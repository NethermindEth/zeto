import { ethers } from "hardhat";
import { Signer, BigNumberish, AbiCoder } from "ethers";
import { expect } from "chai";
import {
  loadCircuit,
  poseidonDecrypt,
  encodeProof,
  Poseidon,
  newEncryptionNonce,
  kycHash,
} from "zeto-js";
import { groth16 } from "snarkjs";
import {
  genKeypair,
  formatPrivKeyForBabyJub,
  genEcdhSharedKey,
  stringifyBigInts,
  Keypair,
} from "maci-crypto";
import {
  Merkletree,
  InMemoryDB,
  str2Bytes,
  ZERO_HASH,
} from "@iden3/js-merkletree";
import { UTXO, User, newUser, newUTXO, newNullifier, ZERO_UTXO } from "./lib/utils";
import { loadProvingKeys } from "./utils";
import { deployZeto } from "./lib/deploy";

// ── constants ──

const poseidonHash2 = Poseidon.poseidon2;
const poseidonHash3 = Poseidon.poseidon3;

const STATUS_ACTIVE = 1n;
const STATUS_FROZEN = 2n;
const SMT_HEIGHT = 64; // used for UTXO, identity, and compliance trees

const ENF_DOMAIN_TAG =
  21455947405572920533869930548514094044543253524099188107381343679564123236615n;

const PROOF_TUPLE = "tuple(uint256[2] pA, uint256[2][2] pB, uint256[2] pC)";

// ── SMT helpers ──

async function addComplianceLeaf(smt: Merkletree, pubKey: BigInt[], status: bigint) {
  await smt.add(
    poseidonHash2([pubKey[0], pubKey[1]]),
    poseidonHash3([pubKey[0], pubKey[1], status]),
  );
}

async function smtProof(smt: Merkletree, key: BigInt) {
  const p = await smt.generateCircomVerifierProof(key, ZERO_HASH);
  return { siblings: p.siblings.map((s) => s.bigInt()), root: p.root.bigInt() };
}

const kycProof = (smt: Merkletree, pubKey: BigInt[]) =>
  smtProof(smt, kycHash(pubKey));

const complianceProof = (smt: Merkletree, pubKey: BigInt[]) =>
  smtProof(smt, poseidonHash2([pubKey[0], pubKey[1]]));

const utxoProof = (smt: Merkletree, hash: BigInt) =>
  smtProof(smt, hash);

function computeEnforcementNullifier(
  ecdhPrivKey: BigInt,
  counterpartyPubKey: BigInt[],
  commitment: BigInt,
): BigInt {
  const shared = genEcdhSharedKey(ecdhPrivKey, counterpartyPubKey);
  const k0 = poseidonHash2([shared[0], shared[1]]);
  return poseidonHash3([commitment, k0, ENF_DOMAIN_TAG]);
}

/** Track UTXO hashes in multiple local SMTs (mirrors on-chain insertions). */
async function trackUtxos(smts: Merkletree[], ...utxos: UTXO[]) {
  for (const u of utxos) {
    if (u.hash === 0n) continue;
    for (const smt of smts) await smt.add(u.hash, u.hash);
  }
}

// ── ABI encoders (must match Solidity abi.decode in each _decodeProof_*) ──

function encodeTransferProof(
  root: BigNumberish, enfNulls: BigInt[], nonce: BigNumberish,
  ecdhPub: BigNumberish[], encRecv: BigNumberish[],
  encArb: BigNumberish[], encEnf: BigNumberish[], proof: object,
) {
  return new AbiCoder().encode(
    ["uint256", "uint256[]", "uint256", "uint256[2]",
     "uint256[]", "uint256[]", "uint256[]", PROOF_TUPLE],
    [root, enfNulls, nonce, ecdhPub, encRecv, encArb, encEnf, proof],
  );
}

function encodeDepositProof(
  nonce: BigNumberish, ecdhPub: BigNumberish[],
  encRecv: BigNumberish[], encArb: BigNumberish[],
  encEnf: BigNumberish[], proof: object,
) {
  return new AbiCoder().encode(
    ["uint256", "uint256[2]", "uint256[]", "uint256[]", "uint256[]", PROOF_TUPLE],
    [nonce, ecdhPub, encRecv, encArb, encEnf, proof],
  );
}

function encodeWithdrawProof(
  root: BigNumberish, enfNulls: BigInt[], nonce: BigNumberish,
  ecdhPub: BigNumberish[], encEnf: BigNumberish[], proof: object,
) {
  return new AbiCoder().encode(
    ["uint256", "uint256[]", "uint256", "uint256[2]", "uint256[]", PROOF_TUPLE],
    [root, enfNulls, nonce, ecdhPub, encEnf, proof],
  );
}

function encodeForcedTransferProof(
  enfNulls: BigInt[], root: BigNumberish, enabled: number[],
  nonce: BigNumberish, ecdhPub: BigNumberish[],
  encRecv: BigNumberish[], encArb: BigNumberish[],
  encEnf: BigNumberish[], proof: object,
) {
  return new AbiCoder().encode(
    ["uint256[]", "uint256", "uint256[]", "uint256", "uint256[2]",
     "uint256[]", "uint256[]", "uint256[]", PROOF_TUPLE],
    [enfNulls, root, enabled, nonce, ecdhPub, encRecv, encArb, encEnf, proof],
  );
}

// ── proof generators ──

interface ProveResult {
  nullifiers?: BigInt[];
  ownerNullifiers?: BigInt[];
  enfNullifiers: BigInt[];
  outputCommitments: BigInt[];
  utxosRoot?: BigInt;
  enabledInputs?: number[];
  encryptionNonce: BigNumberish;
  ecdhPublicKey: BigNumberish[];
  encRecv?: BigNumberish[];
  encArb?: BigNumberish[];
  encEnf: BigNumberish[];
  changeCommitment?: BigInt;
  encodedProof: object;
}

async function generateProof(circuitName: string, witness: object) {
  const circuit = await loadCircuit(circuitName);
  const { provingKeyFile } = loadProvingKeys(circuitName);
  const wtnsBin = await circuit.calculateWTNSBin(witness, true);
  const { proof, publicSignals } = await groth16.prove(provingKeyFile, wtnsBin) as {
    proof: BigNumberish[]; publicSignals: BigNumberish[];
  };
  return { encodedProof: encodeProof(proof), publicSignals };
}

async function proveTransfer(
  sender: User, inputs: UTXO[], outputs: UTXO[], outputOwners: User[],
  utxoSmt: Merkletree, kycSmt: Merkletree, compSmt: Merkletree,
  arbiter: User, enforcer: User, ephKp: Keypair,
): Promise<ProveResult> {
  const inputCommitments = inputs.map((u) => u.hash);
  const nullifiers = inputs.map((u) => newNullifier(u, sender));
  const enfNullifiers = inputCommitments.map((c) =>
    computeEnforcementNullifier(sender.babyJubPrivateKey, enforcer.babyJubPublicKey, c),
  );
  const encryptionNonce = newEncryptionNonce() as BigNumberish;

  const actors = [sender, ...outputOwners];
  const kycProofs = await Promise.all(actors.map((a) => kycProof(kycSmt, a.babyJubPublicKey)));
  const compProofs = await Promise.all(actors.map((a) => complianceProof(compSmt, a.babyJubPublicKey)));
  const utxoProofs = await Promise.all(inputCommitments.map((c) => utxoProof(utxoSmt, c)));

  const { encodedProof, publicSignals } = await generateProof(
    "anon_enc_nullifier_kyc_non_repudiation_enforced",
    {
      ownerNullifiers: nullifiers.map((n) => n.hash),
      enforcementNullifiers: enfNullifiers,
      inputCommitments,
      inputValues: inputs.map((u) => BigInt(u.value || 0)),
      inputSalts: inputs.map((u) => u.salt || 0n),
      inputOwnerPrivateKey: sender.formattedPrivateKey,
      utxosRoot: utxoProofs[0].root,
      utxosMerkleProof: utxoProofs.map((p) => p.siblings),
      enabledInputs: nullifiers.map((n) => (n.hash !== 0n ? 1 : 0)),
      identitiesRoot: kycProofs[0].root,
      identitiesMerkleProof: kycProofs.map((p) => p.siblings),
      complianceRoot: compProofs[0].root,
      complianceMerkleProof: compProofs.map((p) => p.siblings),
      outputCommitments: outputs.map((u) => u.hash),
      outputValues: outputs.map((u) => BigInt(u.value || 0)),
      outputSalts: outputs.map((u) => u.salt || 0n),
      outputOwnerPublicKeys: outputOwners.map((o) => o.babyJubPublicKey),
      arbiterPublicKey: arbiter.babyJubPublicKey,
      enforcerPublicKey: enforcer.babyJubPublicKey,
      ...stringifyBigInts({ encryptionNonce, ecdhPrivateKey: formatPrivKeyForBabyJub(ephKp.privKey) }),
    },
  );

  return {
    nullifiers: nullifiers.map((n) => n.hash),
    enfNullifiers,
    outputCommitments: outputs.map((u) => u.hash),
    utxosRoot: utxoProofs[0].root,
    encryptionNonce,
    ecdhPublicKey: publicSignals.slice(0, 2),
    encRecv: publicSignals.slice(2, 10),
    encArb: publicSignals.slice(10, 26),
    encEnf: publicSignals.slice(26, 42),
    encodedProof,
  };
}

async function proveDeposit(
  outputs: UTXO[], outputOwners: User[],
  kycSmt: Merkletree, compSmt: Merkletree,
  arbiter: User, enforcer: User, ephKp: Keypair,
): Promise<ProveResult> {
  const encryptionNonce = newEncryptionNonce() as BigNumberish;
  const kycProofs = await Promise.all(outputOwners.map((o) => kycProof(kycSmt, o.babyJubPublicKey)));
  const compProofs = await Promise.all(outputOwners.map((o) => complianceProof(compSmt, o.babyJubPublicKey)));

  const { encodedProof, publicSignals } = await generateProof(
    "deposit_kyc_non_repudiation_enforced",
    {
      outputCommitments: outputs.map((u) => u.hash),
      outputValues: outputs.map((u) => BigInt(u.value || 0)),
      outputSalts: outputs.map((u) => u.salt || 0n),
      outputOwnerPublicKeys: outputOwners.map((o) => o.babyJubPublicKey),
      identitiesRoot: kycProofs[0].root,
      identitiesMerkleProof: kycProofs.map((p) => p.siblings),
      complianceRoot: compProofs[0].root,
      complianceMerkleProof: compProofs.map((p) => p.siblings),
      arbiterPublicKey: arbiter.babyJubPublicKey,
      enforcerPublicKey: enforcer.babyJubPublicKey,
      ...stringifyBigInts({ encryptionNonce, ecdhPrivateKey: formatPrivKeyForBabyJub(ephKp.privKey) }),
    },
  );

  // publicSignals[0] = amount (circuit output "out")
  return {
    enfNullifiers: [],
    outputCommitments: outputs.map((u) => u.hash),
    encryptionNonce,
    ecdhPublicKey: publicSignals.slice(1, 3),
    encRecv: publicSignals.slice(3, 11),
    encArb: publicSignals.slice(11, 27),
    encEnf: publicSignals.slice(27, 43),
    encodedProof,
  };
}

async function proveWithdraw(
  sender: User, inputs: UTXO[], changeOutput: UTXO, amount: number,
  utxoSmt: Merkletree, kycSmt: Merkletree, compSmt: Merkletree,
  enforcer: User, ephKp: Keypair,
): Promise<ProveResult> {
  const inputCommitments = inputs.map((u) => u.hash);
  const ownerNullifiers = inputs.map((u) => newNullifier(u, sender).hash);
  const enfNullifiers = inputCommitments.map((c) =>
    computeEnforcementNullifier(sender.babyJubPrivateKey, enforcer.babyJubPublicKey, c),
  );
  const encryptionNonce = newEncryptionNonce() as BigNumberish;

  // KYC/compliance: [sender, changeOutputOwner] — change always returns to sender
  const actors = [sender, sender];
  const kycProofs = await Promise.all(actors.map((a) => kycProof(kycSmt, a.babyJubPublicKey)));
  const compProofs = await Promise.all(actors.map((a) => complianceProof(compSmt, a.babyJubPublicKey)));
  const utxoProofs = await Promise.all(inputCommitments.map((c) => utxoProof(utxoSmt, c)));

  const { encodedProof, publicSignals } = await generateProof(
    "withdraw_nullifier_kyc_enforced",
    {
      amount,
      ownerNullifiers,
      enforcementNullifiers: enfNullifiers,
      outputCommitments: [changeOutput.hash],
      utxosRoot: utxoProofs[0].root,
      identitiesRoot: kycProofs[0].root,
      complianceRoot: compProofs[0].root,
      enabledInputs: ownerNullifiers.map((n) => (n !== 0n ? 1 : 0)),
      enforcerPublicKey: enforcer.babyJubPublicKey,
      inputCommitments,
      inputValues: inputs.map((u) => BigInt(u.value || 0)),
      inputSalts: inputs.map((u) => u.salt || 0n),
      inputOwnerPrivateKey: sender.formattedPrivateKey,
      utxosMerkleProof: utxoProofs.map((p) => p.siblings),
      identitiesMerkleProof: kycProofs.map((p) => p.siblings),
      complianceMerkleProof: compProofs.map((p) => p.siblings),
      outputValues: [BigInt(changeOutput.value || 0)],
      outputSalts: [changeOutput.salt || 0n],
      outputOwnerPublicKeys: [sender.babyJubPublicKey],
      ...stringifyBigInts({ encryptionNonce, ecdhPrivateKey: formatPrivKeyForBabyJub(ephKp.privKey) }),
    },
  );

  return {
    ownerNullifiers,
    enfNullifiers,
    changeCommitment: changeOutput.hash,
    utxosRoot: utxoProofs[0].root,
    encryptionNonce,
    ecdhPublicKey: publicSignals.slice(0, 2),
    encEnf: publicSignals.slice(2, 6), // only 4 elements (2-element plaintext)
    encodedProof,
  };
}

async function proveForcedTransfer(
  seizedOwner: User, inputs: UTXO[], outputs: UTXO[], outputOwners: User[],
  utxoSmt: Merkletree, kycSmt: Merkletree, compSmt: Merkletree,
  arbiter: User, enforcer: User, ephKp: Keypair,
): Promise<ProveResult> {
  const inputCommitments = inputs.map((u) => u.hash);
  const enfNullifiers = inputCommitments.map((c) =>
    computeEnforcementNullifier(enforcer.babyJubPrivateKey, seizedOwner.babyJubPublicKey, c),
  );
  const enabledInputs = inputCommitments.map((c) => (c !== 0n ? 1 : 0));
  const encryptionNonce = newEncryptionNonce() as BigNumberish;

  // KYC/compliance: [seizedOwner, ...outputOwners]
  const actors = [seizedOwner, ...outputOwners];
  const kycProofs = await Promise.all(actors.map((a) => kycProof(kycSmt, a.babyJubPublicKey)));
  const compProofs = await Promise.all(actors.map((a) => complianceProof(compSmt, a.babyJubPublicKey)));
  const utxoProofs = await Promise.all(inputCommitments.map((c) => utxoProof(utxoSmt, c)));

  const { encodedProof, publicSignals } = await generateProof(
    "forced_transfer_nullifier_kyc_enforced",
    {
      enforcementNullifiers: enfNullifiers,
      outputCommitments: outputs.map((u) => u.hash),
      utxosRoot: utxoProofs[0].root,
      identitiesRoot: kycProofs[0].root,
      complianceRoot: compProofs[0].root,
      enabledInputs,
      enforcerPublicKey: enforcer.babyJubPublicKey,
      arbiterPublicKey: arbiter.babyJubPublicKey,
      inputCommitments,
      inputValues: inputs.map((u) => BigInt(u.value || 0)),
      inputSalts: inputs.map((u) => u.salt || 0n),
      seizedOwnerPublicKey: seizedOwner.babyJubPublicKey,
      enforcerPrivateKey: enforcer.formattedPrivateKey,
      utxosMerkleProof: utxoProofs.map((p) => p.siblings),
      identitiesMerkleProof: kycProofs.map((p) => p.siblings),
      complianceMerkleProof: compProofs.map((p) => p.siblings),
      outputValues: outputs.map((u) => BigInt(u.value || 0)),
      outputSalts: outputs.map((u) => u.salt || 0n),
      outputOwnerPublicKeys: outputOwners.map((o) => o.babyJubPublicKey),
      ...stringifyBigInts({ encryptionNonce, ecdhPrivateKey: formatPrivKeyForBabyJub(ephKp.privKey) }),
    },
  );

  return {
    enfNullifiers,
    outputCommitments: outputs.map((u) => u.hash),
    enabledInputs, utxosRoot: utxoProofs[0].root,
    encryptionNonce,
    ecdhPublicKey: publicSignals.slice(0, 2),
    encRecv: publicSignals.slice(2, 10),
    encArb: publicSignals.slice(10, 26),
    encEnf: publicSignals.slice(26, 42),
    encodedProof,
  };
}

// ── helpers for decrypting from proof output signals ──

function toBigInts(arr: BigNumberish[]): BigInt[] {
  return arr.map((x) => BigInt(x));
}

function decryptAuthority(ciphertext: BigNumberish[], privKey: BigInt, ephPubKey: BigInt[], nonce: bigint) {
  const shared = genEcdhSharedKey(privKey, ephPubKey);
  return poseidonDecrypt(toBigInts(ciphertext), shared, nonce, 14);
}

function findEvent(zeto: any, result: any, name: string) {
  const events = result.logs.map((l: any) => zeto.interface.parseLog(l)).filter(Boolean);
  return events.find((e: any) => e!.name === name);
}

// ── test suite ──

describe("Zeto AENKNR-E: enforced fungible token with KYC, compliance, non-repudiation, and seizure", function () {
  let deployer: Signer;
  let Alice: User;
  let Bob: User;
  let Charlie: User;
  let Arbiter: User;
  let Enforcer: User;
  let erc20: any;
  let zeto: any;

  // Local mirrors of on-chain SMTs
  let smtAlice: Merkletree;
  let smtBob: Merkletree;
  let smtKyc: Merkletree;
  let smtCompAllActive: Merkletree;
  let smtCompAliceFrozen: Merkletree;

  before(async function () {
    this.timeout(600000);
    const [d, a, b, c, e, f] = await ethers.getSigners();
    deployer = d;
    Alice = await newUser(a);
    Bob = await newUser(b);
    Charlie = await newUser(c);
    Arbiter = await newUser(e);
    Enforcer = await newUser(f);

    ({ deployer, zeto, erc20 } = await deployZeto(
      "Zeto_AnonEncNullifierKycNonRepudiationEnforced",
    ));

    // Register identities (KYC)
    for (const user of [Alice, Bob, Charlie]) {
      await (await zeto.connect(deployer).register(user.babyJubPublicKey, "0x")).wait();
    }

    // Local KYC SMT mirror
    smtKyc = new Merkletree(new InMemoryDB(str2Bytes("kyc")), true, SMT_HEIGHT);
    for (const user of [Alice, Bob, Charlie]) {
      const h = kycHash(user.babyJubPublicKey);
      await smtKyc.add(h, h);
    }

    // Compliance: all ACTIVE
    smtCompAllActive = new Merkletree(new InMemoryDB(str2Bytes("comp-active")), true, SMT_HEIGHT);
    for (const user of [Alice, Bob, Charlie]) {
      await addComplianceLeaf(smtCompAllActive, user.babyJubPublicKey, STATUS_ACTIVE);
    }

    // Compliance: Alice FROZEN, Bob+Charlie ACTIVE
    smtCompAliceFrozen = new Merkletree(new InMemoryDB(str2Bytes("comp-frozen")), true, SMT_HEIGHT);
    await addComplianceLeaf(smtCompAliceFrozen, Alice.babyJubPublicKey, STATUS_FROZEN);
    await addComplianceLeaf(smtCompAliceFrozen, Bob.babyJubPublicKey, STATUS_ACTIVE);
    await addComplianceLeaf(smtCompAliceFrozen, Charlie.babyJubPublicKey, STATUS_ACTIVE);

    // UTXO SMTs (per-user local mirrors)
    smtAlice = new Merkletree(new InMemoryDB(str2Bytes("alice")), true, SMT_HEIGHT);
    smtBob = new Merkletree(new InMemoryDB(str2Bytes("bob")), true, SMT_HEIGHT);
  });

  // ── deployment and admin ──

  describe("deployment and admin", function () {
    it("transfer reverts with EnforcerNotSet before setEnforcer", async function () {
      const dummyProof = new AbiCoder().encode(
        ["uint256", "uint256[]", "uint256", "uint256[2]",
         "uint256[]", "uint256[]", "uint256[]", PROOF_TUPLE],
        [0, [0, 0], 0, [0, 0], [0], [0], [0],
         { pA: [0, 0], pB: [[0, 0], [0, 0]], pC: [0, 0] }],
      );
      await expect(
        zeto.connect(Alice.signer).transfer([1], [1], dummyProof, "0x"),
      ).to.be.revertedWithCustomError(zeto, "EnforcerNotSet");
    });

    it("setEnforcer sets key and emits event; second call reverts", async function () {
      const tx = await zeto.connect(deployer).setEnforcer(Enforcer.babyJubPublicKey);
      await expect(tx).to.emit(zeto, "EnforcerSet").withArgs(Enforcer.babyJubPublicKey);
      const key = await zeto.getEnforcer();
      expect(key[0]).to.equal(Enforcer.babyJubPublicKey[0]);
      expect(key[1]).to.equal(Enforcer.babyJubPublicKey[1]);

      await expect(
        zeto.connect(deployer).setEnforcer(Enforcer.babyJubPublicKey),
      ).to.be.revertedWithCustomError(zeto, "EnforcerAlreadySet");
    });

    it("setArbiter rotates key and increments keyId", async function () {
      await expect(zeto.connect(deployer).setArbiter(Arbiter.babyJubPublicKey))
        .to.emit(zeto, "ArbiterUpdated").withArgs(Arbiter.babyJubPublicKey, 1);
      expect(await zeto.getArbiterKeyId()).to.equal(1);

      // Rotate — keyId increments
      const tmpArbiter = await newUser((await ethers.getSigners())[7]);
      await expect(zeto.connect(deployer).setArbiter(tmpArbiter.babyJubPublicKey))
        .to.emit(zeto, "ArbiterUpdated").withArgs(tmpArbiter.babyJubPublicKey, 2);
      expect(await zeto.getArbiterKeyId()).to.equal(2);

      // Reset to our test arbiter
      await zeto.connect(deployer).setArbiter(Arbiter.babyJubPublicKey);
    });

    it("setComplianceRoot updates root and emits event", async function () {
      const root = (await complianceProof(smtCompAllActive, Alice.babyJubPublicKey)).root;
      await expect(zeto.connect(deployer).setComplianceRoot(root, "0x"))
        .to.emit(zeto, "ComplianceRootUpdated");
    });
  });

  // ── deposit ──

  describe("deposit", function () {
    it("deposits ERC-20 into two UTXOs; arbiter decrypts deposit ciphertext", async function () {
      this.timeout(600000);
      const utxo30 = newUTXO(30, Alice);
      const utxo70 = newUTXO(70, Alice);

      await (await erc20.connect(deployer).mint(Alice.ethAddress, 100)).wait();
      await (await erc20.connect(Alice.signer).approve(zeto.target, 100)).wait();

      const ephKp = genKeypair();
      const dp = await proveDeposit(
        [utxo30, utxo70], [Alice, Alice],
        smtKyc, smtCompAllActive, Arbiter, Enforcer, ephKp,
      );

      const result = await (await zeto.connect(Alice.signer).deposit(
        100, dp.outputCommitments,
        encodeDepositProof(dp.encryptionNonce, dp.ecdhPublicKey, dp.encRecv!, dp.encArb!, dp.encEnf, dp.encodedProof),
        "0x",
      )).wait();
      expect(result!.status).to.equal(1);

      await trackUtxos([smtAlice, smtBob], utxo30, utxo70);

      // Arbiter decrypts 14-element plaintext (input fields zeroed per deposit schema)
      const arbPlain = decryptAuthority(dp.encArb!, Arbiter.babyJubPrivateKey, ephKp.pubKey, BigInt(dp.encryptionNonce));
      expect(arbPlain[2]).to.equal(0n);  // in1Value zeroed
      expect(arbPlain[3]).to.equal(0n);  // in1Salt zeroed
      expect(arbPlain[10]).to.equal(30n); // out1Value
      expect(arbPlain[12]).to.equal(70n); // out2Value
    });
  });

  // ── transfer ──

  describe("transfer", function () {
    let utxoBob50: UTXO;
    let utxoAliceChange50: UTXO;
    let transferEnfNullifiers: BigInt[];
    let transferOwnerNullifiers: BigInt[];

    it("transfers Alice→Bob; all three ciphertext streams decryptable; both nullifier types marked", async function () {
      this.timeout(600000);
      const utxo30 = newUTXO(30, Alice);
      const utxo70 = newUTXO(70, Alice);
      await (await zeto.connect(deployer).mint([utxo30.hash, utxo70.hash], "0x")).wait();
      await trackUtxos([smtAlice, smtBob], utxo30, utxo70);

      utxoBob50 = newUTXO(50, Bob);
      utxoAliceChange50 = newUTXO(50, Alice);
      const ephKp = genKeypair();

      const tp = await proveTransfer(
        Alice, [utxo30, utxo70], [utxoBob50, utxoAliceChange50],
        [Bob, Alice], smtAlice, smtKyc, smtCompAllActive,
        Arbiter, Enforcer, ephKp,
      );
      transferOwnerNullifiers = tp.nullifiers!;
      transferEnfNullifiers = tp.enfNullifiers;

      const result = await (await zeto.connect(Alice.signer).transfer(
        tp.nullifiers!.filter((n) => n !== 0n),
        tp.outputCommitments.filter((c) => c !== 0n),
        encodeTransferProof(
          tp.utxosRoot!, tp.enfNullifiers, tp.encryptionNonce,
          tp.ecdhPublicKey, tp.encRecv!, tp.encArb!, tp.encEnf, tp.encodedProof,
        ),
        "0x",
      )).wait();

      // Verify event shape
      const ev = findEvent(zeto, result!, "UTXOTransferNonRepudiationEnforced");
      expect(ev).to.not.be.undefined;
      expect(ev!.args.arbiterKeyId).to.equal(await zeto.getArbiterKeyId());

      // Arbiter decrypts full 14-element plaintext
      const arbPlain = decryptAuthority(ev!.args.encryptedValuesForArbiter, Arbiter.babyJubPrivateKey, ephKp.pubKey, ev!.args.encryptionNonce);
      expect(arbPlain[0]).to.equal(Alice.babyJubPublicKey[0]); // senderPubX
      expect(arbPlain[2]).to.equal(30n);  // in1Value
      expect(arbPlain[4]).to.equal(70n);  // in2Value
      expect(arbPlain[10]).to.equal(50n); // out1Value (Bob)
      expect(arbPlain[12]).to.equal(50n); // out2Value (Alice change)

      // Enforcer decrypts identical plaintext via different ECDH key
      const enfPlain = decryptAuthority(ev!.args.encryptedValuesForEnforcer, Enforcer.babyJubPrivateKey, ephKp.pubKey, ev!.args.encryptionNonce);
      expect(enfPlain).to.deep.equal(arbPlain);

      // Receiver (Bob) decrypts their per-output ciphertext
      const bobShared = genEcdhSharedKey(Bob.babyJubPrivateKey, ephKp.pubKey);
      const bobPlain = poseidonDecrypt(
        toBigInts(ev!.args.encryptedValuesForReceiver).slice(0, 4),
        bobShared, ev!.args.encryptionNonce, 2,
      );
      expect(bobPlain[0]).to.equal(50n);
      expect(bobPlain[1]).to.equal(utxoBob50.salt);

      await trackUtxos([smtAlice, smtBob], utxoBob50, utxoAliceChange50);

      // Both nullifier types marked spent
      for (const n of transferOwnerNullifiers) {
        if (n !== 0n) expect(await zeto.ownerNullifierSpent(n)).to.be.true;
      }
      for (const n of transferEnfNullifiers) {
        if (n !== 0n) expect(await zeto.enforcementNullifierSpent(n)).to.be.true;
      }
      expect(await zeto.isSpent(transferOwnerNullifiers[0], transferEnfNullifiers[0])).to.be.true;
    });
  });

  // ── withdraw ──

  describe("withdraw", function () {
    it("partial withdrawal; enforcer decrypts change ciphertext; both nullifier types marked", async function () {
      this.timeout(600000);
      const utxo40 = newUTXO(40, Alice);
      const utxo60 = newUTXO(60, Alice);
      await (await zeto.connect(deployer).mint([utxo40.hash, utxo60.hash], "0x")).wait();
      await trackUtxos([smtAlice, smtBob], utxo40, utxo60);

      const changeUtxo = newUTXO(20, Alice); // withdraw 80, keep 20
      const ephKp = genKeypair();
      const wp = await proveWithdraw(
        Alice, [utxo40, utxo60], changeUtxo, 80,
        smtAlice, smtKyc, smtCompAllActive, Enforcer, ephKp,
      );

      const result = await (await zeto.connect(Alice.signer).withdraw(
        80, wp.ownerNullifiers!, wp.changeCommitment,
        encodeWithdrawProof(wp.utxosRoot!, wp.enfNullifiers, wp.encryptionNonce, wp.ecdhPublicKey, wp.encEnf, wp.encodedProof),
        "0x",
      )).wait();
      expect(result!.status).to.equal(1);

      // Enforcer decrypts change note (2-element plaintext: [changeValue, changeSalt])
      const enfShared = genEcdhSharedKey(Enforcer.babyJubPrivateKey, ephKp.pubKey);
      const enfPlain = poseidonDecrypt(toBigInts(wp.encEnf), enfShared, BigInt(wp.encryptionNonce), 2);
      expect(enfPlain[0]).to.equal(20n);
      expect(enfPlain[1]).to.equal(changeUtxo.salt);

      // Both nullifier types marked
      for (const n of wp.ownerNullifiers!) {
        if (n !== 0n) expect(await zeto.ownerNullifierSpent(n)).to.be.true;
      }
      for (const n of wp.enfNullifiers) {
        if (n !== 0n) expect(await zeto.enforcementNullifierSpent(n)).to.be.true;
      }

      await trackUtxos([smtAlice, smtBob], changeUtxo);
    });
  });

  // ── forced transfer (seizure lifecycle) ──

  describe("forced transfer (seizure lifecycle)", function () {
    let seizedUtxo1: UTXO;
    let seizedUtxo2: UTXO;
    let seizedEnfNullifiers: BigInt[];
    let seizedOwnerNullifiers: BigInt[];

    it("setup: mint UTXOs for Alice (who will be frozen)", async function () {
      seizedUtxo1 = newUTXO(25, Alice);
      seizedUtxo2 = newUTXO(75, Alice);
      await (await zeto.connect(deployer).mint([seizedUtxo1.hash, seizedUtxo2.hash], "0x")).wait();
      await trackUtxos([smtAlice, smtBob], seizedUtxo1, seizedUtxo2);
      seizedOwnerNullifiers = [seizedUtxo1, seizedUtxo2].map((u) => newNullifier(u, Alice).hash);
    });

    it("freeze: update compliance root to FROZEN for Alice", async function () {
      const frozenRoot = (await complianceProof(smtCompAliceFrozen, Alice.babyJubPublicKey)).root;
      await (await zeto.connect(deployer).setComplianceRoot(frozenRoot, "0x")).wait();
      expect(await zeto.getComplianceRoot()).to.equal(frozenRoot);
    });

    it("seize: forcedTransfer redirects Alice's UTXOs to Bob; only enforcement nullifiers marked", async function () {
      this.timeout(600000);
      const seizureOutput = newUTXO(100, Bob);
      const ephKp = genKeypair();

      const fp = await proveForcedTransfer(
        Alice, [seizedUtxo1, seizedUtxo2],
        [seizureOutput, ZERO_UTXO], [Bob, Bob],
        smtAlice, smtKyc, smtCompAliceFrozen,
        Arbiter, Enforcer, ephKp,
      );
      seizedEnfNullifiers = fp.enfNullifiers;

      const result = await (await zeto.connect(deployer).forcedTransfer(
        fp.outputCommitments,
        encodeForcedTransferProof(
          fp.enfNullifiers, fp.utxosRoot!, fp.enabledInputs!,
          fp.encryptionNonce, fp.ecdhPublicKey,
          fp.encRecv!, fp.encArb!, fp.encEnf, fp.encodedProof,
        ),
        "0x",
      )).wait();

      // Event uses enforcement nullifiers as inputs (not commitments — those are private witnesses)
      const ev = findEvent(zeto, result!, "UTXOForcedTransferEnforced");
      expect(ev).to.not.be.undefined;
      expect(ev!.args.enforcementNullifiers.map((n: any) => BigInt(n))).to.deep.equal(seizedEnfNullifiers);

      // Arbiter decrypts: senderPub = seized owner's key (Alice, not the enforcer)
      const arbPlain = decryptAuthority(ev!.args.encryptedValuesForArbiter, Arbiter.babyJubPrivateKey, ephKp.pubKey, ev!.args.encryptionNonce);
      expect(arbPlain[0]).to.equal(Alice.babyJubPublicKey[0]);
      expect(arbPlain[1]).to.equal(Alice.babyJubPublicKey[1]);

      // Only enforcement nullifiers marked (not owner — enforcer can't compute them)
      for (const n of seizedEnfNullifiers) {
        if (n !== 0n) expect(await zeto.enforcementNullifierSpent(n)).to.be.true;
      }
      for (const n of seizedOwnerNullifiers) {
        expect(await zeto.ownerNullifierSpent(n)).to.be.false;
      }
      // OR semantics: isSpent returns true even though only enforcement side is marked
      expect(await zeto.isSpent(seizedOwnerNullifiers[0], seizedEnfNullifiers[0])).to.be.true;

      await trackUtxos([smtAlice, smtBob], seizureOutput);
    });

    it("Alice cannot spend seized UTXOs — enforcement nullifiers already spent", async function () {
      this.timeout(600000);

      // Restore ACTIVE compliance root so Alice can attempt a transfer
      const activeRoot = (await complianceProof(smtCompAllActive, Alice.babyJubPublicKey)).root;
      await (await zeto.connect(deployer).setComplianceRoot(activeRoot, "0x")).wait();

      // Alice generates a valid transfer proof (she has the private key)
      const ephKp = genKeypair();
      const tp = await proveTransfer(
        Alice, [seizedUtxo1, seizedUtxo2],
        [newUTXO(25, Bob), newUTXO(75, Bob)], [Bob, Bob],
        smtAlice, smtKyc, smtCompAllActive, Arbiter, Enforcer, ephKp,
      );

      // Contract rejects: enforcement nullifiers already marked by forcedTransfer
      await expect(
        zeto.connect(Alice.signer).transfer(
          tp.nullifiers!.filter((n) => n !== 0n),
          tp.outputCommitments.filter((c) => c !== 0n),
          encodeTransferProof(
            tp.utxosRoot!, tp.enfNullifiers, tp.encryptionNonce,
            tp.ecdhPublicKey, tp.encRecv!, tp.encArb!, tp.encEnf, tp.encodedProof,
          ),
          "0x",
        ),
      ).to.be.revertedWithCustomError(zeto, "EnforcementNullifierAlreadySpent");
    });

    it("non-owner cannot call forcedTransfer", async function () {
      await expect(
        zeto.connect(Alice.signer).forcedTransfer([1n], "0x", "0x"),
      ).to.be.revertedWithCustomError(zeto, "OwnableUnauthorizedAccount");
    });
  });

  // ── nullifier spend semantics ──

  describe("nullifier spend semantics", function () {
    it("fresh nullifiers report not spent via all three read APIs", async function () {
      const n = 999999999n;
      expect(await zeto.ownerNullifierSpent(n)).to.be.false;
      expect(await zeto.enforcementNullifierSpent(n)).to.be.false;
      expect(await zeto.isSpent(n, n)).to.be.false;
    });
  });
});