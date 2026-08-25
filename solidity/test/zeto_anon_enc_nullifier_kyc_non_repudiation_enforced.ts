// Prerequisites — generate circuit artifacts before running:
//
//   cd zkp/circuits && npm i
//   export CIRCUITS_ROOT=<path> PROVING_KEYS_ROOT=<path> PTAU_DOWNLOAD_PATH=<path>
//   npm run gen -- -c anon_enc_nullifier_kyc_non_repudiation_enforced
//   npm run gen -- -c deposit_kyc_non_repudiation_enforced
//   npm run gen -- -c withdraw_nullifier_kyc_enforced
//   npm run gen -- -c forced_transfer_nullifier_kyc_enforced
//
// Then run:  CIRCUITS_ROOT=<path> PROVING_KEYS_ROOT=<path> npx hardhat test test/zeto_anon_enc_nullifier_kyc_non_repudiation_enforced.ts

import { ethers, upgrades } from "hardhat";
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
import {
  UTXO,
  User,
  newUser,
  newUTXO,
  newNullifier,
  ZERO_UTXO,
} from "./lib/utils";
import { loadProvingKeys } from "./utils";
import { deployZeto } from "./lib/deploy";
import { deployFungible } from "../scripts/deploy_upgradeable";
import { getLinkedContractFactory } from "../scripts/lib/common";
import { deployDependencies } from "../scripts/tokens/Zeto_AnonEncNullifierKycNonRepudiationEnforced";

// ── constants ──

const poseidonHash2 = Poseidon.poseidon2;
const poseidonHash3 = Poseidon.poseidon3;

const STATUS_ACTIVE = 1n;
const STATUS_FROZEN = 2n;
const SMT_HEIGHT_UTXO = 32;
const SMT_HEIGHT_IDENTITY = 20;
const SMT_HEIGHT_COMPLIANCE = 20;

const ENF_DOMAIN_TAG =
  21455947405572920533869930548514094044543253524099188107381343679564123236615n;

const PROOF_TUPLE = "tuple(uint256[2] pA, uint256[2][2] pB, uint256[2] pC)";

// ── SMT helpers ──

async function addComplianceLeaf(
  smt: Merkletree,
  pubKey: BigInt[],
  status: bigint,
) {
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

const utxoProof = (smt: Merkletree, hash: BigInt) => smtProof(smt, hash);

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
  root: BigNumberish,
  enfNulls: BigInt[],
  nonce: BigNumberish,
  ecdhPub: BigNumberish[],
  encRecv: BigNumberish[],
  encArb: BigNumberish[],
  encEnf: BigNumberish[],
  proof: object,
) {
  return new AbiCoder().encode(
    [
      "uint256",
      "uint256[]",
      "uint256",
      "uint256[2]",
      "uint256[]",
      "uint256[]",
      "uint256[]",
      PROOF_TUPLE,
    ],
    [root, enfNulls, nonce, ecdhPub, encRecv, encArb, encEnf, proof],
  );
}

function encodeDepositProof(
  nonce: BigNumberish,
  ecdhPub: BigNumberish[],
  encRecv: BigNumberish[],
  encArb: BigNumberish[],
  encEnf: BigNumberish[],
  proof: object,
) {
  return new AbiCoder().encode(
    [
      "uint256",
      "uint256[2]",
      "uint256[]",
      "uint256[]",
      "uint256[]",
      PROOF_TUPLE,
    ],
    [nonce, ecdhPub, encRecv, encArb, encEnf, proof],
  );
}

function encodeWithdrawProof(
  root: BigNumberish,
  enfNulls: BigInt[],
  nonce: BigNumberish,
  ecdhPub: BigNumberish[],
  encArb: BigNumberish[],
  encEnf: BigNumberish[],
  proof: object,
) {
  return new AbiCoder().encode(
    [
      "uint256",
      "uint256[]",
      "uint256",
      "uint256[2]",
      "uint256[]",
      "uint256[]",
      PROOF_TUPLE,
    ],
    [root, enfNulls, nonce, ecdhPub, encArb, encEnf, proof],
  );
}

function encodeForcedTransferProof(
  enfNulls: BigInt[],
  root: BigNumberish,
  enabled: number[],
  nonce: BigNumberish,
  ecdhPub: BigNumberish[],
  encRecv: BigNumberish[],
  encArb: BigNumberish[],
  encEnf: BigNumberish[],
  proof: object,
) {
  return new AbiCoder().encode(
    [
      "uint256[]",
      "uint256",
      "uint256[]",
      "uint256",
      "uint256[2]",
      "uint256[]",
      "uint256[]",
      "uint256[]",
      PROOF_TUPLE,
    ],
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
  const { proof, publicSignals } = (await groth16.prove(
    provingKeyFile,
    wtnsBin,
  )) as {
    proof: BigNumberish[];
    publicSignals: BigNumberish[];
  };
  return { encodedProof: encodeProof(proof), publicSignals };
}

async function proveTransfer(
  sender: User,
  inputs: UTXO[],
  outputs: UTXO[],
  outputOwners: User[],
  utxoSmt: Merkletree,
  kycSmt: Merkletree,
  compSmt: Merkletree,
  arbiter: User,
  enforcer: User,
  ephKp: Keypair,
): Promise<ProveResult> {
  const inputCommitments = inputs.map((u) => u.hash);
  const nullifiers = inputs.map((u) =>
    u.hash === 0n
      ? ({ hash: 0n, value: 0, salt: 0n } as UTXO)
      : newNullifier(u, sender),
  );
  const enfNullifiers = inputCommitments.map((c) =>
    c === 0n
      ? (0n as BigInt)
      : computeEnforcementNullifier(
          sender.babyJubPrivateKey,
          enforcer.babyJubPublicKey,
          c,
        ),
  );
  const encryptionNonce = newEncryptionNonce() as BigNumberish;

  const actors = [sender, ...outputOwners];
  const kycProofs = await Promise.all(
    actors.map((a) => kycProof(kycSmt, a.babyJubPublicKey)),
  );
  const compProofs = await Promise.all(
    actors.map((a) => complianceProof(compSmt, a.babyJubPublicKey)),
  );
  const utxoProofs = await Promise.all(
    inputCommitments.map((c) => utxoProof(utxoSmt, c)),
  );

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
      ...stringifyBigInts({
        encryptionNonce,
        ecdhPrivateKey: formatPrivKeyForBabyJub(ephKp.privKey),
      }),
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
  outputs: UTXO[],
  outputOwners: User[],
  kycSmt: Merkletree,
  compSmt: Merkletree,
  arbiter: User,
  enforcer: User,
  ephKp: Keypair,
): Promise<ProveResult> {
  const encryptionNonce = newEncryptionNonce() as BigNumberish;
  const kycProofs = await Promise.all(
    outputOwners.map((o) => kycProof(kycSmt, o.babyJubPublicKey)),
  );
  const compProofs = await Promise.all(
    outputOwners.map((o) => complianceProof(compSmt, o.babyJubPublicKey)),
  );

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
      ...stringifyBigInts({
        encryptionNonce,
        ecdhPrivateKey: formatPrivKeyForBabyJub(ephKp.privKey),
      }),
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
  sender: User,
  inputs: UTXO[],
  changeOutput: UTXO,
  amount: number,
  utxoSmt: Merkletree,
  kycSmt: Merkletree,
  compSmt: Merkletree,
  arbiter: User,
  enforcer: User,
  ephKp: Keypair,
  // The address the contract will pay the ERC-20 to. It is a bound public
  // signal, so a proof is only usable by the account that submits as this
  // recipient. Defaults to the sender, who is the usual withdrawer.
  recipient?: string,
): Promise<ProveResult> {
  const inputCommitments = inputs.map((u) => u.hash);
  const ownerNullifiers = inputs.map((u) => newNullifier(u, sender).hash);
  const enfNullifiers = inputCommitments.map((c) =>
    computeEnforcementNullifier(
      sender.babyJubPrivateKey,
      enforcer.babyJubPublicKey,
      c,
    ),
  );
  const encryptionNonce = newEncryptionNonce() as BigNumberish;

  // KYC/compliance: [sender, changeOutputOwner] — change always returns to sender
  const actors = [sender, sender];
  const kycProofs = await Promise.all(
    actors.map((a) => kycProof(kycSmt, a.babyJubPublicKey)),
  );
  const compProofs = await Promise.all(
    actors.map((a) => complianceProof(compSmt, a.babyJubPublicKey)),
  );
  const utxoProofs = await Promise.all(
    inputCommitments.map((c) => utxoProof(utxoSmt, c)),
  );

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
      arbiterPublicKey: arbiter.babyJubPublicKey,
      enforcerPublicKey: enforcer.babyJubPublicKey,
      recipient: BigInt(recipient ?? sender.ethAddress),
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
      ...stringifyBigInts({
        encryptionNonce,
        ecdhPrivateKey: formatPrivKeyForBabyJub(ephKp.privKey),
      }),
    },
  );

  return {
    ownerNullifiers,
    enfNullifiers,
    outputCommitments: [changeOutput.hash],
    changeCommitment: changeOutput.hash,
    utxosRoot: utxoProofs[0].root,
    encryptionNonce,
    ecdhPublicKey: publicSignals.slice(0, 2),
    encArb: publicSignals.slice(2, 18), // 16 elements (14-element plaintext)
    encEnf: publicSignals.slice(18, 34), // 16 elements (14-element plaintext)
    encodedProof,
  };
}

async function proveForcedTransfer(
  seizedOwner: User,
  inputs: UTXO[],
  outputs: UTXO[],
  outputOwners: User[],
  utxoSmt: Merkletree,
  kycSmt: Merkletree,
  compSmt: Merkletree,
  arbiter: User,
  enforcer: User,
  ephKp: Keypair,
): Promise<ProveResult> {
  const inputCommitments = inputs.map((u) => u.hash);
  const enfNullifiers = inputCommitments.map((c) =>
    computeEnforcementNullifier(
      enforcer.babyJubPrivateKey,
      seizedOwner.babyJubPublicKey,
      c,
    ),
  );
  const enabledInputs = inputCommitments.map((c) => (c !== 0n ? 1 : 0));
  const encryptionNonce = newEncryptionNonce() as BigNumberish;

  // KYC/compliance: [seizedOwner, ...outputOwners]
  const actors = [seizedOwner, ...outputOwners];
  const kycProofs = await Promise.all(
    actors.map((a) => kycProof(kycSmt, a.babyJubPublicKey)),
  );
  const compProofs = await Promise.all(
    actors.map((a) => complianceProof(compSmt, a.babyJubPublicKey)),
  );
  const utxoProofs = await Promise.all(
    inputCommitments.map((c) => utxoProof(utxoSmt, c)),
  );

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
      ...stringifyBigInts({
        encryptionNonce,
        ecdhPrivateKey: formatPrivKeyForBabyJub(ephKp.privKey),
      }),
    },
  );

  return {
    enfNullifiers,
    outputCommitments: outputs.map((u) => u.hash),
    enabledInputs,
    utxosRoot: utxoProofs[0].root,
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

function decryptAuthority(
  ciphertext: BigNumberish[],
  privKey: BigInt,
  ephPubKey: BigInt[],
  nonce: bigint,
) {
  const shared = genEcdhSharedKey(privKey, ephPubKey);
  return poseidonDecrypt(toBigInts(ciphertext), shared, nonce, 14);
}

function findEvent(zeto: any, result: any, name: string) {
  const events = result.logs
    .map((l: any) => zeto.interface.parseLog(l))
    .filter(Boolean);
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
  let smtCompBobFrozen: Merkletree;
  let Stranger: User;

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
      await (
        await zeto.connect(deployer).register(user.babyJubPublicKey, "0x")
      ).wait();
    }

    // Local KYC SMT mirror
    smtKyc = new Merkletree(
      new InMemoryDB(str2Bytes("kyc")),
      true,
      SMT_HEIGHT_IDENTITY,
    );
    for (const user of [Alice, Bob, Charlie]) {
      const h = kycHash(user.babyJubPublicKey);
      await smtKyc.add(h, h);
    }

    // Compliance: all ACTIVE
    smtCompAllActive = new Merkletree(
      new InMemoryDB(str2Bytes("comp-active")),
      true,
      SMT_HEIGHT_COMPLIANCE,
    );
    for (const user of [Alice, Bob, Charlie]) {
      await addComplianceLeaf(
        smtCompAllActive,
        user.babyJubPublicKey,
        STATUS_ACTIVE,
      );
    }

    // Compliance: Alice FROZEN, Bob+Charlie ACTIVE
    smtCompAliceFrozen = new Merkletree(
      new InMemoryDB(str2Bytes("comp-frozen")),
      true,
      SMT_HEIGHT_COMPLIANCE,
    );
    await addComplianceLeaf(
      smtCompAliceFrozen,
      Alice.babyJubPublicKey,
      STATUS_FROZEN,
    );
    await addComplianceLeaf(
      smtCompAliceFrozen,
      Bob.babyJubPublicKey,
      STATUS_ACTIVE,
    );
    await addComplianceLeaf(
      smtCompAliceFrozen,
      Charlie.babyJubPublicKey,
      STATUS_ACTIVE,
    );

    // Compliance: Bob FROZEN, Alice+Charlie ACTIVE
    smtCompBobFrozen = new Merkletree(
      new InMemoryDB(str2Bytes("comp-bob-frozen")),
      true,
      SMT_HEIGHT_COMPLIANCE,
    );
    await addComplianceLeaf(
      smtCompBobFrozen,
      Alice.babyJubPublicKey,
      STATUS_ACTIVE,
    );
    await addComplianceLeaf(
      smtCompBobFrozen,
      Bob.babyJubPublicKey,
      STATUS_FROZEN,
    );
    await addComplianceLeaf(
      smtCompBobFrozen,
      Charlie.babyJubPublicKey,
      STATUS_ACTIVE,
    );

    // Stranger: not KYC-registered, no compliance leaf
    Stranger = await newUser((await ethers.getSigners())[8]);

    // UTXO SMTs (per-user local mirrors)
    smtAlice = new Merkletree(
      new InMemoryDB(str2Bytes("alice")),
      true,
      SMT_HEIGHT_UTXO,
    );
    smtBob = new Merkletree(
      new InMemoryDB(str2Bytes("bob")),
      true,
      SMT_HEIGHT_UTXO,
    );
  });

  // ── deployment and admin ──

  describe("deployment and admin", function () {
    it("transfer reverts with EnforcerNotSet before setEnforcer", async function () {
      const dummyProof = new AbiCoder().encode(
        [
          "uint256",
          "uint256[]",
          "uint256",
          "uint256[2]",
          "uint256[]",
          "uint256[]",
          "uint256[]",
          PROOF_TUPLE,
        ],
        [
          0,
          [0, 0],
          0,
          [0, 0],
          [0],
          [0],
          [0],
          {
            pA: [0, 0],
            pB: [
              [0, 0],
              [0, 0],
            ],
            pC: [0, 0],
          },
        ],
      );
      await expect(
        zeto.connect(Alice.signer).transfer([1], [1], dummyProof, "0x"),
      ).to.be.revertedWithCustomError(zeto, "EnforcerNotSet");
    });

    it("setEnforcer sets key and emits event; second call reverts", async function () {
      const tx = await zeto
        .connect(deployer)
        .setEnforcer(Enforcer.babyJubPublicKey);
      await expect(tx)
        .to.emit(zeto, "EnforcerSet")
        .withArgs(Enforcer.babyJubPublicKey);
      const key = await zeto.getEnforcer();
      expect(key[0]).to.equal(Enforcer.babyJubPublicKey[0]);
      expect(key[1]).to.equal(Enforcer.babyJubPublicKey[1]);

      await expect(
        zeto.connect(deployer).setEnforcer(Enforcer.babyJubPublicKey),
      ).to.be.revertedWithCustomError(zeto, "EnforcerAlreadySet");
    });

    it("setArbiter rotates key and increments keyId", async function () {
      await expect(zeto.connect(deployer).setArbiter(Arbiter.babyJubPublicKey))
        .to.emit(zeto, "ArbiterUpdated")
        .withArgs(Arbiter.babyJubPublicKey, 1);
      expect(await zeto.getArbiterKeyId()).to.equal(1);

      // Rotate — keyId increments
      const tmpArbiter = await newUser((await ethers.getSigners())[7]);
      await expect(
        zeto.connect(deployer).setArbiter(tmpArbiter.babyJubPublicKey),
      )
        .to.emit(zeto, "ArbiterUpdated")
        .withArgs(tmpArbiter.babyJubPublicKey, 2);
      expect(await zeto.getArbiterKeyId()).to.equal(2);

      // Restore the arbiter the rest of the suite expects
      await zeto.connect(deployer).setArbiter(Arbiter.babyJubPublicKey);
    });

    it("setComplianceRoot updates root and emits event", async function () {
      const root = (
        await complianceProof(smtCompAllActive, Alice.babyJubPublicKey)
      ).root;
      await expect(
        zeto.connect(deployer).setComplianceRoot(root, "0x"),
      ).to.emit(zeto, "ComplianceRootUpdated");
    });
  });

  // ── authority key validation ──

  describe("authority key validation", function () {
    // BabyJubJub is defined over the BN254 scalar field; the generated verifiers
    // reject any public signal at or above it.
    const FIELD =
      21888242871839275222246405745257275088548364400416034343698204186575808495617n;

    // Each pair is unusable as an authority key: identity / x == 0 (the circuits
    // constrain xIsZero === 0), off-curve, or a coordinate at the field bound.
    const BAD_KEYS: Array<[string, [bigint, bigint]]> = [
      ["identity (0, 1)", [0n, 1n]],
      ["x == 0", [0n, FIELD - 1n]],
      ["zero pair", [0n, 0n]],
      ["off-curve (1, 1)", [1n, 1n]],
      ["x at the field bound", [FIELD, 1n]],
      ["y at the field bound", [1n, FIELD]],
    ];

    it("setEnforcer rejects an unusable key and stays configurable", async function () {
      // A fresh token, so the shared fixture's set-once enforcer is untouched.
      const { deployer: d, zeto: fresh } = await deployZeto(
        "Zeto_AnonEncNullifierKycNonRepudiationEnforced",
      );

      // Before the fix this call succeeded, latching enforcerSet = true with an
      // unusable key and bricking every proof path irreversibly.
      await expect(fresh.connect(d).setEnforcer([0n, 1n]))
        .to.be.revertedWithCustomError(fresh, "InvalidBabyJubKey")
        .withArgs(0n, 1n);

      // The set-once slot was not consumed, so the real key still lands.
      await expect(fresh.connect(d).setEnforcer(Enforcer.babyJubPublicKey))
        .to.emit(fresh, "EnforcerSet")
        .withArgs(Enforcer.babyJubPublicKey);
      const stored = await fresh.getEnforcer();
      expect(stored[0]).to.equal(Enforcer.babyJubPublicKey[0]);
      expect(stored[1]).to.equal(Enforcer.babyJubPublicKey[1]);
    });

    it("setEnforcer rejects every unusable key shape", async function () {
      const { deployer: d, zeto: fresh } = await deployZeto(
        "Zeto_AnonEncNullifierKycNonRepudiationEnforced",
      );
      for (const [label, key] of BAD_KEYS) {
        await expect(
          fresh.connect(d).setEnforcer(key),
          label,
        ).to.be.revertedWithCustomError(fresh, "InvalidBabyJubKey");
      }
    });

    it("setArbiter rejects every unusable key shape and keeps the current key", async function () {
      const before = await zeto.getArbiter();
      const keyIdBefore = await zeto.getArbiterKeyId();
      for (const [label, key] of BAD_KEYS) {
        await expect(
          zeto.connect(deployer).setArbiter(key),
          label,
        ).to.be.revertedWithCustomError(zeto, "InvalidBabyJubKey");
      }
      // No partial write and no keyId churn from the rejected calls.
      const after = await zeto.getArbiter();
      expect(after[0]).to.equal(before[0]);
      expect(after[1]).to.equal(before[1]);
      expect(await zeto.getArbiterKeyId()).to.equal(keyIdBefore);
    });

    it("both setters still accept a real on-curve key", async function () {
      await expect(
        zeto.connect(deployer).setArbiter(Arbiter.babyJubPublicKey),
      ).to.emit(zeto, "ArbiterUpdated");
      const { deployer: d, zeto: fresh } = await deployZeto(
        "Zeto_AnonEncNullifierKycNonRepudiationEnforced",
      );
      await expect(fresh.connect(d).setEnforcer(Enforcer.babyJubPublicKey))
        .to.emit(fresh, "EnforcerSet")
        .withArgs(Enforcer.babyJubPublicKey);
    });
  });

  // ── codec and facet address validation ──

  describe("codec and facet address validation", function () {
    // Both setters store a call target that is later reached through a low-level
    // call. `_forwardToFacet` DELEGATECALLs the facet and `_callCodec`
    // STATICCALLs the codec, and both of those succeed with empty return data
    // against an account that holds no code, so a codeless target is not
    // reported as an error anywhere downstream.
    const dummyProof = new AbiCoder().encode(
      [
        "uint256",
        "uint256[]",
        "uint256",
        "uint256[2]",
        "uint256[]",
        "uint256[]",
        "uint256[]",
        PROOF_TUPLE,
      ],
      [
        0,
        [0, 0],
        0,
        [0, 0],
        [0],
        [0],
        [0],
        {
          pA: [0, 0],
          pB: [
            [0, 0],
            [0, 0],
          ],
          pC: [0, 0],
        },
      ],
    );

    /** An externally owned account — a non-zero address that holds no code. */
    async function eoaAddress(): Promise<string> {
      return await (await ethers.getSigners())[9].getAddress();
    }

    /**
     * A router with neither the codec nor the transfer facet configured. The
     * suite's deployment helper wires both with real contracts, so on every
     * token it returns the set-once codec slot is already consumed.
     */
    async function deployUnconfiguredRouter() {
      const {
        deployer: d,
        args,
        libraries,
        codec,
        transferFacet,
      } = await deployDependencies();
      const factory = await getLinkedContractFactory(
        "Zeto_AnonEncNullifierKycNonRepudiationEnforced",
        libraries,
      );
      // The implementation calls `_disableInitializers()` in its constructor,
      // so `initialize` only ever runs behind a proxy.
      const proxy = await upgrades.deployProxy(factory.connect(d), args, {
        kind: "uups",
        initializer: "initialize",
        unsafeAllow: ["delegatecall", "external-library-linking"],
      } as any);
      await proxy.waitForDeployment();
      const router: any = await ethers.getContractAt(
        "Zeto_AnonEncNullifierKycNonRepudiationEnforced",
        await proxy.getAddress(),
      );
      return { d, router, codec, transferFacet };
    }

    it("setTransferFacet rejects an EOA, so a successful receipt still means a real transfer", async function () {
      const { deployer: d, zeto: fresh } = await deployZeto(
        "Zeto_AnonEncNullifierKycNonRepudiationEnforced",
      );
      await (
        await fresh.connect(d).setEnforcer(Enforcer.babyJubPublicKey)
      ).wait();
      const eoa = await eoaAddress();

      // Before the fix this call succeeded, and DELEGATECALL to a codeless
      // account then returned success with zero return data.
      await expect(fresh.connect(d).setTransferFacet(eoa))
        .to.be.revertedWithCustomError(fresh, "NotAContract")
        .withArgs(eoa);

      // The real facet is therefore still installed, so transfer reaches it and
      // rejects the bogus proof. Before the fix the facet was the EOA and this
      // transaction produced a status-1 receipt with no event and no state
      // change -- which the Paladin domain plugin reads as a completed
      // transfer.
      await expect(
        fresh.connect(Alice.signer).transfer([1], [1], dummyProof, "0x"),
      ).to.be.reverted;
    });

    it("setCodec rejects an EOA, so the set-once slot cannot be bricked", async function () {
      const { d, router, codec } = await deployUnconfiguredRouter();
      const eoa = await eoaAddress();

      // Before the fix this call latched a codeless codec permanently:
      // `_callCodec`'s STATICCALL would return ok == 1 with zero return data,
      // `require(ok, "Codec call failed")` would pass, and the assembly
      // readers would run off the end of an empty buffer -- with no way to
      // replace the codec short of a UUPS upgrade.
      await expect(router.connect(d).setCodec(eoa))
        .to.be.revertedWithCustomError(router, "NotAContract")
        .withArgs(eoa);

      // The set-once slot was not consumed, so the real codec still lands.
      await (await router.connect(d).setCodec(codec)).wait();
      await expect(
        router.connect(d).setCodec(codec),
      ).to.be.revertedWithCustomError(router, "CodecAlreadySet");
    });

    it("both setters still reject the zero address", async function () {
      const { d, router } = await deployUnconfiguredRouter();
      await expect(
        router.connect(d).setCodec(ethers.ZeroAddress),
      ).to.be.revertedWithCustomError(router, "NotAContract");
      await expect(
        router.connect(d).setTransferFacet(ethers.ZeroAddress),
      ).to.be.revertedWith("Zero address");
    });

    it("both setters accept a deployed contract", async function () {
      const { d, router, codec, transferFacet } =
        await deployUnconfiguredRouter();
      await (await router.connect(d).setCodec(codec)).wait();
      await (await router.connect(d).setTransferFacet(transferFacet)).wait();
    });
  });

  // ── deposit ──

  describe("deposit", function () {
    it("deposits ERC-20 into two UTXOs; arbiter decrypts deposit ciphertext", async function () {
      this.timeout(600000);
      const utxo30 = newUTXO(30, Alice);
      const utxo70 = newUTXO(70, Alice);

      await (await erc20.connect(deployer).mint(Alice.ethAddress, 100)).wait();
      await (
        await erc20.connect(Alice.signer).approve(zeto.target, 100)
      ).wait();

      const ephKp = genKeypair();
      const dp = await proveDeposit(
        [utxo30, utxo70],
        [Alice, Alice],
        smtKyc,
        smtCompAllActive,
        Arbiter,
        Enforcer,
        ephKp,
      );

      const result = await (
        await zeto
          .connect(Alice.signer)
          .deposit(
            100,
            dp.outputCommitments,
            encodeDepositProof(
              dp.encryptionNonce,
              dp.ecdhPublicKey,
              dp.encRecv!,
              dp.encArb!,
              dp.encEnf,
              dp.encodedProof,
            ),
            "0x",
          )
      ).wait();
      expect(result!.status).to.equal(1);

      await trackUtxos([smtAlice, smtBob], utxo30, utxo70);

      // Arbiter decrypts 14-element plaintext (input fields zeroed per deposit schema)
      const arbPlain = decryptAuthority(
        dp.encArb!,
        Arbiter.babyJubPrivateKey,
        ephKp.pubKey,
        BigInt(dp.encryptionNonce),
      );
      expect(arbPlain[2]).to.equal(0n); // in1Value zeroed
      expect(arbPlain[3]).to.equal(0n); // in1Salt zeroed
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
      await (
        await zeto.connect(deployer).mint([utxo30.hash, utxo70.hash], "0x")
      ).wait();
      await trackUtxos([smtAlice, smtBob], utxo30, utxo70);

      utxoBob50 = newUTXO(50, Bob);
      utxoAliceChange50 = newUTXO(50, Alice);
      const ephKp = genKeypair();

      const tp = await proveTransfer(
        Alice,
        [utxo30, utxo70],
        [utxoBob50, utxoAliceChange50],
        [Bob, Alice],
        smtAlice,
        smtKyc,
        smtCompAllActive,
        Arbiter,
        Enforcer,
        ephKp,
      );
      transferOwnerNullifiers = tp.nullifiers!;
      transferEnfNullifiers = tp.enfNullifiers;

      const result = await (
        await zeto.connect(Alice.signer).transfer(
          tp.nullifiers!.filter((n) => n !== 0n),
          tp.outputCommitments.filter((c) => c !== 0n),
          encodeTransferProof(
            tp.utxosRoot!,
            tp.enfNullifiers,
            tp.encryptionNonce,
            tp.ecdhPublicKey,
            tp.encRecv!,
            tp.encArb!,
            tp.encEnf,
            tp.encodedProof,
          ),
          "0x",
        )
      ).wait();

      // Verify event shape
      const ev = findEvent(zeto, result!, "UTXOTransferNonRepudiationEnforced");
      expect(ev).to.not.be.undefined;
      expect(ev!.args.arbiterKeyId).to.equal(await zeto.getArbiterKeyId());

      // Arbiter decrypts full 14-element plaintext
      const arbPlain = decryptAuthority(
        ev!.args.encryptedValuesForArbiter,
        Arbiter.babyJubPrivateKey,
        ephKp.pubKey,
        ev!.args.encryptionNonce,
      );
      expect(arbPlain[0]).to.equal(Alice.babyJubPublicKey[0]); // senderPubX
      expect(arbPlain[2]).to.equal(30n); // in1Value
      expect(arbPlain[4]).to.equal(70n); // in2Value
      expect(arbPlain[10]).to.equal(50n); // out1Value (Bob)
      expect(arbPlain[12]).to.equal(50n); // out2Value (Alice change)

      // Enforcer decrypts identical plaintext via different ECDH key
      const enfPlain = decryptAuthority(
        ev!.args.encryptedValuesForEnforcer,
        Enforcer.babyJubPrivateKey,
        ephKp.pubKey,
        ev!.args.encryptionNonce,
      );
      expect(enfPlain).to.deep.equal(arbPlain);

      // Receiver (Bob) decrypts their per-output ciphertext
      const bobShared = genEcdhSharedKey(Bob.babyJubPrivateKey, ephKp.pubKey);
      const bobPlain = poseidonDecrypt(
        toBigInts(ev!.args.encryptedValuesForReceiver).slice(0, 4),
        bobShared,
        ev!.args.encryptionNonce,
        2,
      );
      expect(bobPlain[0]).to.equal(50n);
      expect(bobPlain[1]).to.equal(utxoBob50.salt);

      await trackUtxos([smtAlice, smtBob], utxoBob50, utxoAliceChange50);

      // Both nullifier types marked spent
      for (const n of transferOwnerNullifiers) {
        if (n !== 0n) expect(await zeto.ownerNullifierSpent(n)).to.be.true;
      }
      for (const n of transferEnfNullifiers) {
        if (n !== 0n)
          expect(await zeto.enforcementNullifierSpent(n)).to.be.true;
      }
      expect(
        await zeto.isSpent(
          transferOwnerNullifiers[0],
          transferEnfNullifiers[0],
        ),
      ).to.be.true;
    });
  });

  // ── withdraw ──

  describe("withdraw", function () {
    it("partial withdrawal; arbiter+enforcer decrypt 14-element ciphertext; both nullifier types marked", async function () {
      this.timeout(600000);
      const utxo40 = newUTXO(40, Alice);
      const utxo60 = newUTXO(60, Alice);
      await (
        await zeto.connect(deployer).mint([utxo40.hash, utxo60.hash], "0x")
      ).wait();
      await trackUtxos([smtAlice, smtBob], utxo40, utxo60);

      const changeUtxo = newUTXO(20, Alice); // withdraw 80, keep 20
      const ephKp = genKeypair();
      const wp = await proveWithdraw(
        Alice,
        [utxo40, utxo60],
        changeUtxo,
        80,
        smtAlice,
        smtKyc,
        smtCompAllActive,
        Arbiter,
        Enforcer,
        ephKp,
      );

      const result = await (
        await zeto
          .connect(Alice.signer)
          .withdraw(
            80,
            wp.ownerNullifiers!,
            wp.changeCommitment,
            encodeWithdrawProof(
              wp.utxosRoot!,
              wp.enfNullifiers,
              wp.encryptionNonce,
              wp.ecdhPublicKey,
              wp.encArb!,
              wp.encEnf,
              wp.encodedProof,
            ),
            "0x",
          )
      ).wait();
      expect(result!.status).to.equal(1);

      // Arbiter decrypts 14-element authority plaintext from withdraw
      const arbPlain = decryptAuthority(
        wp.encArb!,
        Arbiter.babyJubPrivateKey,
        ephKp.pubKey,
        BigInt(wp.encryptionNonce),
      );
      expect(arbPlain[0]).to.equal(Alice.babyJubPublicKey[0]); // senderPubX
      expect(arbPlain[10]).to.equal(20n); // changeValue
      expect(arbPlain[11]).to.equal(changeUtxo.salt); // changeSalt
      expect(arbPlain[12]).to.equal(0n); // virtual output value
      expect(arbPlain[13]).to.equal(0n); // virtual output salt

      // Enforcer decrypts identical plaintext via different ECDH key
      const enfPlain = decryptAuthority(
        wp.encEnf,
        Enforcer.babyJubPrivateKey,
        ephKp.pubKey,
        BigInt(wp.encryptionNonce),
      );
      expect(enfPlain).to.deep.equal(arbPlain);

      // Both nullifier types marked
      for (const n of wp.ownerNullifiers!) {
        if (n !== 0n) expect(await zeto.ownerNullifierSpent(n)).to.be.true;
      }
      for (const n of wp.enfNullifiers) {
        if (n !== 0n)
          expect(await zeto.enforcementNullifierSpent(n)).to.be.true;
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
      await (
        await zeto
          .connect(deployer)
          .mint([seizedUtxo1.hash, seizedUtxo2.hash], "0x")
      ).wait();
      await trackUtxos([smtAlice, smtBob], seizedUtxo1, seizedUtxo2);
      seizedOwnerNullifiers = [seizedUtxo1, seizedUtxo2].map(
        (u) => newNullifier(u, Alice).hash,
      );
    });

    it("freeze: update compliance root to FROZEN for Alice", async function () {
      const frozenRoot = (
        await complianceProof(smtCompAliceFrozen, Alice.babyJubPublicKey)
      ).root;
      await (
        await zeto.connect(deployer).setComplianceRoot(frozenRoot, "0x")
      ).wait();
      expect(await zeto.getComplianceRoot()).to.equal(frozenRoot);
    });

    it("seize: forcedTransfer redirects Alice's UTXOs to Bob; only enforcement nullifiers marked", async function () {
      this.timeout(600000);
      const seizureOutput = newUTXO(100, Bob);
      const ephKp = genKeypair();

      const fp = await proveForcedTransfer(
        Alice,
        [seizedUtxo1, seizedUtxo2],
        [seizureOutput, ZERO_UTXO],
        [Bob, Bob],
        smtAlice,
        smtKyc,
        smtCompAliceFrozen,
        Arbiter,
        Enforcer,
        ephKp,
      );
      seizedEnfNullifiers = fp.enfNullifiers;

      const result = await (
        await zeto
          .connect(deployer)
          .forcedTransfer(
            fp.outputCommitments,
            encodeForcedTransferProof(
              fp.enfNullifiers,
              fp.utxosRoot!,
              fp.enabledInputs!,
              fp.encryptionNonce,
              fp.ecdhPublicKey,
              fp.encRecv!,
              fp.encArb!,
              fp.encEnf,
              fp.encodedProof,
            ),
            "0x",
          )
      ).wait();

      // Event uses enforcement nullifiers as inputs (not commitments — those are private witnesses)
      const ev = findEvent(zeto, result!, "UTXOForcedTransferEnforced");
      expect(ev).to.not.be.undefined;
      expect(
        ev!.args.enforcementNullifiers.map((n: any) => BigInt(n)),
      ).to.deep.equal(seizedEnfNullifiers);

      // Arbiter decrypts: senderPub = seized owner's key (Alice, not the enforcer)
      const arbPlain = decryptAuthority(
        ev!.args.encryptedValuesForArbiter,
        Arbiter.babyJubPrivateKey,
        ephKp.pubKey,
        ev!.args.encryptionNonce,
      );
      expect(arbPlain[0]).to.equal(Alice.babyJubPublicKey[0]);
      expect(arbPlain[1]).to.equal(Alice.babyJubPublicKey[1]);

      // Only enforcement nullifiers marked (not owner — enforcer can't compute them)
      for (const n of seizedEnfNullifiers) {
        if (n !== 0n)
          expect(await zeto.enforcementNullifierSpent(n)).to.be.true;
      }
      for (const n of seizedOwnerNullifiers) {
        expect(await zeto.ownerNullifierSpent(n)).to.be.false;
      }
      // OR semantics: isSpent returns true even though only enforcement side is marked
      expect(
        await zeto.isSpent(seizedOwnerNullifiers[0], seizedEnfNullifiers[0]),
      ).to.be.true;

      await trackUtxos([smtAlice, smtBob], seizureOutput);
    });

    it("Alice cannot spend seized UTXOs — enforcement nullifiers already spent", async function () {
      this.timeout(600000);

      // Restore ACTIVE compliance root so Alice can attempt a transfer
      const activeRoot = (
        await complianceProof(smtCompAllActive, Alice.babyJubPublicKey)
      ).root;
      await (
        await zeto.connect(deployer).setComplianceRoot(activeRoot, "0x")
      ).wait();

      // Alice generates a valid transfer proof (she has the private key)
      const ephKp = genKeypair();
      const tp = await proveTransfer(
        Alice,
        [seizedUtxo1, seizedUtxo2],
        [newUTXO(25, Bob), newUTXO(75, Bob)],
        [Bob, Bob],
        smtAlice,
        smtKyc,
        smtCompAllActive,
        Arbiter,
        Enforcer,
        ephKp,
      );

      // Contract rejects: enforcement nullifiers already marked by forcedTransfer
      await expect(
        zeto.connect(Alice.signer).transfer(
          tp.nullifiers!.filter((n) => n !== 0n),
          tp.outputCommitments.filter((c) => c !== 0n),
          encodeTransferProof(
            tp.utxosRoot!,
            tp.enfNullifiers,
            tp.encryptionNonce,
            tp.ecdhPublicKey,
            tp.encRecv!,
            tp.encArb!,
            tp.encEnf,
            tp.encodedProof,
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

  // ═══════════════════════════════════════════════════════════════
  // Negative & edge-case tests
  // ═══════════════════════════════════════════════════════════════

  /** Helper: expect a proof generator to throw a circuit constraint error. */
  async function expectCircuitReject(proofFn: () => Promise<unknown>) {
    try {
      await proofFn();
      expect.fail("should have thrown");
    } catch (e: any) {
      expect(e.message).to.contain("Error in template");
    }
  }

  /** Mint UTXOs via admin and track them in all local SMTs. */
  async function mintAndTrack(utxos: UTXO[]) {
    await mintInto(zeto, deployer, [smtAlice, smtBob], utxos);
  }

  /** {mintAndTrack} against an arbitrary token and set of local mirrors. */
  async function mintInto(
    token: any,
    owner: Signer,
    smts: Merkletree[],
    utxos: UTXO[],
  ) {
    const hashes: bigint[] = utxos.map((u) => BigInt(u.hash as any));
    while (hashes.length < 2) hashes.push(0n);
    await (await token.connect(owner).mint(hashes.slice(0, 2), "0x")).wait();
    await trackUtxos(smts, ...utxos);
  }

  /**
   * A fully configured AENKNR-E token backed by `erc20Address`, with an empty
   * commitments tree and a matching local mirror.
   *
   * {ZetoFungible.setERC20} is one-shot -- a second call reverts
   * {ERC20AlreadySet} -- so a block that needs a non-standard backing asset
   * cannot re-point the suite's shared token and deploys its own instead. The
   * identity registrations are replayed in the same order so the on-chain
   * identities root still matches `smtKyc`.
   */
  async function deployTokenBackedBy(erc20Address: string, mirror: string) {
    const { deployer: owner, zeto: token } = await deployFungible(
      "Zeto_AnonEncNullifierKycNonRepudiationEnforced",
      erc20Address,
    );
    for (const user of [Alice, Bob, Charlie]) {
      await (
        await token.connect(owner).register(user.babyJubPublicKey, "0x")
      ).wait();
    }
    await (
      await token.connect(owner).setEnforcer(Enforcer.babyJubPublicKey)
    ).wait();
    await (
      await token.connect(owner).setArbiter(Arbiter.babyJubPublicKey)
    ).wait();
    const activeRoot = (
      await complianceProof(smtCompAllActive, Alice.babyJubPublicKey)
    ).root;
    await (
      await token.connect(owner).setComplianceRoot(activeRoot, "0x")
    ).wait();
    const smt = new Merkletree(
      new InMemoryDB(str2Bytes(mirror)),
      true,
      SMT_HEIGHT_UTXO,
    );
    return { owner, token, smt };
  }

  // ── KYC gating ──

  describe("KYC gating", function () {
    it("transfer fails at circuit level if sender is not KYC-registered", async function () {
      this.timeout(600000);
      const u1 = newUTXO(50, Stranger);
      const u2 = newUTXO(50, Stranger);
      await mintAndTrack([u1, u2]);

      await expectCircuitReject(() =>
        proveTransfer(
          Stranger,
          [u1, u2],
          [newUTXO(50, Alice), newUTXO(50, Alice)],
          [Alice, Alice],
          smtAlice,
          smtKyc,
          smtCompAllActive,
          Arbiter,
          Enforcer,
          genKeypair(),
        ),
      );
    });

    it("transfer fails at circuit level if recipient is not KYC-registered", async function () {
      this.timeout(600000);
      const u1 = newUTXO(50, Alice);
      const u2 = newUTXO(50, Alice);
      await mintAndTrack([u1, u2]);

      await expectCircuitReject(() =>
        proveTransfer(
          Alice,
          [u1, u2],
          [newUTXO(50, Stranger), newUTXO(50, Alice)],
          [Stranger, Alice],
          smtAlice,
          smtKyc,
          smtCompAllActive,
          Arbiter,
          Enforcer,
          genKeypair(),
        ),
      );
    });

    it("deposit fails at circuit level if recipient is not KYC-registered", async function () {
      this.timeout(600000);
      await expectCircuitReject(() =>
        proveDeposit(
          [newUTXO(50, Stranger), newUTXO(50, Stranger)],
          [Stranger, Stranger],
          smtKyc,
          smtCompAllActive,
          Arbiter,
          Enforcer,
          genKeypair(),
        ),
      );
    });
  });

  // ── compliance gating ──

  describe("compliance gating", function () {
    it("transfer fails at circuit level if sender is FROZEN", async function () {
      this.timeout(600000);
      const u1 = newUTXO(50, Alice);
      const u2 = newUTXO(50, Alice);
      await mintAndTrack([u1, u2]);

      await expectCircuitReject(() =>
        proveTransfer(
          Alice,
          [u1, u2],
          [newUTXO(50, Bob), newUTXO(50, Alice)],
          [Bob, Alice],
          smtAlice,
          smtKyc,
          smtCompAliceFrozen,
          Arbiter,
          Enforcer,
          genKeypair(),
        ),
      );
    });

    it("transfer fails at circuit level if recipient is FROZEN", async function () {
      this.timeout(600000);
      const u1 = newUTXO(50, Alice);
      const u2 = newUTXO(50, Alice);
      await mintAndTrack([u1, u2]);

      await expectCircuitReject(() =>
        proveTransfer(
          Alice,
          [u1, u2],
          [newUTXO(50, Bob), newUTXO(50, Alice)],
          [Bob, Alice],
          smtAlice,
          smtKyc,
          smtCompBobFrozen,
          Arbiter,
          Enforcer,
          genKeypair(),
        ),
      );
    });

    it("withdraw fails at circuit level if sender is FROZEN", async function () {
      this.timeout(600000);
      const u1 = newUTXO(40, Alice);
      const u2 = newUTXO(60, Alice);
      await mintAndTrack([u1, u2]);

      await expectCircuitReject(() =>
        proveWithdraw(
          Alice,
          [u1, u2],
          newUTXO(20, Alice),
          80,
          smtAlice,
          smtKyc,
          smtCompAliceFrozen,
          Arbiter,
          Enforcer,
          genKeypair(),
        ),
      );
    });

    it("deposit fails at circuit level if recipient is FROZEN", async function () {
      this.timeout(600000);
      await expectCircuitReject(() =>
        proveDeposit(
          [newUTXO(50, Bob), newUTXO(50, Bob)],
          [Bob, Bob],
          smtKyc,
          smtCompBobFrozen,
          Arbiter,
          Enforcer,
          genKeypair(),
        ),
      );
    });
  });

  // ── value conservation ──

  describe("value conservation", function () {
    it("deposit fails on-chain when amount != sum(outputValues)", async function () {
      this.timeout(600000);
      const u1 = newUTXO(40, Alice);
      const u2 = newUTXO(50, Alice);

      // Generate proof normally — circuit output `out` = 90
      const ephKp = genKeypair();
      const dp = await proveDeposit(
        [u1, u2],
        [Alice, Alice],
        smtKyc,
        smtCompAllActive,
        Arbiter,
        Enforcer,
        ephKp,
      );

      // Mint enough ERC-20 for the mismatched amount
      await (await erc20.connect(deployer).mint(Alice.ethAddress, 100)).wait();
      await (
        await erc20.connect(Alice.signer).approve(zeto.target, 100)
      ).wait();

      // Submit with amount=100 but proof binds to out=90 → verifier rejects
      await expect(
        zeto
          .connect(Alice.signer)
          .deposit(
            100,
            dp.outputCommitments,
            encodeDepositProof(
              dp.encryptionNonce,
              dp.ecdhPublicKey,
              dp.encRecv!,
              dp.encArb!,
              dp.encEnf,
              dp.encodedProof,
            ),
            "0x",
          ),
      ).to.be.revertedWithCustomError(zeto, "InvalidProof");
    });
  });

  // ── forced transfer edge cases ──

  describe("forced transfer edge cases", function () {
    it("forced transfer fails at circuit level with inputs from two different owners", async function () {
      this.timeout(600000);
      const aliceUtxo = newUTXO(50, Alice);
      const bobUtxo = newUTXO(50, Bob);
      await mintAndTrack([aliceUtxo, bobUtxo]);

      await expectCircuitReject(() =>
        proveForcedTransfer(
          Alice,
          [aliceUtxo, bobUtxo],
          [newUTXO(100, Charlie), ZERO_UTXO],
          [Charlie, Charlie],
          smtAlice,
          smtKyc,
          smtCompAliceFrozen,
          Arbiter,
          Enforcer,
          genKeypair(),
        ),
      );
    });

    it("forced transfer succeeds with change back to the same FROZEN owner", async function () {
      this.timeout(600000);
      const u1 = newUTXO(25, Alice);
      const u2 = newUTXO(75, Alice);
      await mintAndTrack([u1, u2]);

      // Ensure on-chain compliance root is Alice-frozen
      const frozenRoot = (
        await complianceProof(smtCompAliceFrozen, Alice.babyJubPublicKey)
      ).root;
      await (
        await zeto.connect(deployer).setComplianceRoot(frozenRoot, "0x")
      ).wait();

      const seizureOut = newUTXO(80, Bob);
      const changeOut = newUTXO(20, Alice);
      const ephKp = genKeypair();

      const fp = await proveForcedTransfer(
        Alice,
        [u1, u2],
        [seizureOut, changeOut],
        [Bob, Alice],
        smtAlice,
        smtKyc,
        smtCompAliceFrozen,
        Arbiter,
        Enforcer,
        ephKp,
      );

      const result = await (
        await zeto
          .connect(deployer)
          .forcedTransfer(
            fp.outputCommitments,
            encodeForcedTransferProof(
              fp.enfNullifiers,
              fp.utxosRoot!,
              fp.enabledInputs!,
              fp.encryptionNonce,
              fp.ecdhPublicKey,
              fp.encRecv!,
              fp.encArb!,
              fp.encEnf,
              fp.encodedProof,
            ),
            "0x",
          )
      ).wait();

      const ev = findEvent(zeto, result!, "UTXOForcedTransferEnforced");
      expect(ev).to.not.be.undefined;

      // Enforcement nullifiers marked spent
      for (const n of fp.enfNullifiers) {
        if (n !== 0n)
          expect(await zeto.enforcementNullifierSpent(n)).to.be.true;
      }

      await trackUtxos([smtAlice, smtBob], seizureOut, changeOut);

      // Restore all-active root for subsequent tests
      const activeRoot = (
        await complianceProof(smtCompAllActive, Alice.babyJubPublicKey)
      ).root;
      await (
        await zeto.connect(deployer).setComplianceRoot(activeRoot, "0x")
      ).wait();
    });

    it("forced transfer succeeds with full-balance seizure (zero-change slot with [0,0] key)", async function () {
      this.timeout(600000);
      const u1 = newUTXO(40, Alice);
      const u2 = newUTXO(60, Alice);
      await mintAndTrack([u1, u2]);

      // Ensure on-chain compliance root is Alice-frozen
      const frozenRoot = (
        await complianceProof(smtCompAliceFrozen, Alice.babyJubPublicKey)
      ).root;
      await (
        await zeto.connect(deployer).setComplianceRoot(frozenRoot, "0x")
      ).wait();

      const seizureOutput = newUTXO(100, Bob);
      const ephKp = genKeypair();

      // Build proof manually to inject [0,0] as the zero-slot owner key
      const inputCommitments = [u1, u2].map((u) => u.hash);
      const enfNullifiers = inputCommitments.map((c) =>
        computeEnforcementNullifier(
          Enforcer.babyJubPrivateKey,
          Alice.babyJubPublicKey,
          c,
        ),
      );
      const enabledInputs = inputCommitments.map((c) => (c !== 0n ? 1 : 0));
      const encryptionNonce = newEncryptionNonce() as BigNumberish;

      // KYC/compliance proofs: [seizedOwner, output0Owner, output1Owner]
      // output1 is zero-commitment → gated off, but the merkle proof arrays must still be well-formed
      const actors = [Alice, Bob, Bob];
      const kycProofs = await Promise.all(
        actors.map((a) => kycProof(smtKyc, a.babyJubPublicKey)),
      );
      const compProofs = await Promise.all(
        actors.map((a) =>
          complianceProof(smtCompAliceFrozen, a.babyJubPublicKey),
        ),
      );
      const utxoProofs = await Promise.all(
        inputCommitments.map((c) => utxoProof(smtAlice, c)),
      );

      const { encodedProof, publicSignals } = await generateProof(
        "forced_transfer_nullifier_kyc_enforced",
        {
          enforcementNullifiers: enfNullifiers,
          outputCommitments: [seizureOutput.hash, 0n],
          utxosRoot: utxoProofs[0].root,
          identitiesRoot: kycProofs[0].root,
          complianceRoot: compProofs[0].root,
          enabledInputs,
          enforcerPublicKey: Enforcer.babyJubPublicKey,
          arbiterPublicKey: Arbiter.babyJubPublicKey,
          inputCommitments,
          inputValues: [u1, u2].map((u) => BigInt(u.value || 0)),
          inputSalts: [u1, u2].map((u) => u.salt || 0n),
          seizedOwnerPublicKey: Alice.babyJubPublicKey,
          enforcerPrivateKey: Enforcer.formattedPrivateKey,
          utxosMerkleProof: utxoProofs.map((p) => p.siblings),
          identitiesMerkleProof: kycProofs.map((p) => p.siblings),
          complianceMerkleProof: compProofs.map((p) => p.siblings),
          outputValues: [BigInt(seizureOutput.value || 0), 0n],
          outputSalts: [seizureOutput.salt || 0n, 0n],
          outputOwnerPublicKeys: [Bob.babyJubPublicKey, [0n, 0n]],
          ...stringifyBigInts({
            encryptionNonce,
            ecdhPrivateKey: formatPrivKeyForBabyJub(ephKp.privKey),
          }),
        },
      );

      const ecdhPublicKey = publicSignals.slice(0, 2);
      const encRecv = publicSignals.slice(2, 10);
      const encArb = publicSignals.slice(10, 26);
      const encEnf = publicSignals.slice(26, 42);

      const result = await (
        await zeto
          .connect(deployer)
          .forcedTransfer(
            [seizureOutput.hash, 0n],
            encodeForcedTransferProof(
              enfNullifiers,
              utxoProofs[0].root,
              enabledInputs,
              encryptionNonce,
              ecdhPublicKey,
              encRecv,
              encArb,
              encEnf,
              encodedProof,
            ),
            "0x",
          )
      ).wait();

      const ev = findEvent(zeto, result!, "UTXOForcedTransferEnforced");
      expect(ev).to.not.be.undefined;

      for (const n of enfNullifiers) {
        if (n !== 0n)
          expect(await zeto.enforcementNullifierSpent(n)).to.be.true;
      }

      await trackUtxos([smtAlice, smtBob], seizureOutput);

      // Restore active root
      const activeRoot2 = (
        await complianceProof(smtCompAllActive, Alice.babyJubPublicKey)
      ).root;
      await (
        await zeto.connect(deployer).setComplianceRoot(activeRoot2, "0x")
      ).wait();
    });

    it("forced transfer fails at circuit level when output goes to a FROZEN non-seized party", async function () {
      this.timeout(600000);
      const u1 = newUTXO(50, Alice);
      const u2 = newUTXO(50, Alice);
      await mintAndTrack([u1, u2]);

      // Both Alice and Bob frozen
      const smtCompBothFrozen = new Merkletree(
        new InMemoryDB(str2Bytes("comp-both-frozen")),
        true,
        SMT_HEIGHT_COMPLIANCE,
      );
      await addComplianceLeaf(
        smtCompBothFrozen,
        Alice.babyJubPublicKey,
        STATUS_FROZEN,
      );
      await addComplianceLeaf(
        smtCompBothFrozen,
        Bob.babyJubPublicKey,
        STATUS_FROZEN,
      );
      await addComplianceLeaf(
        smtCompBothFrozen,
        Charlie.babyJubPublicKey,
        STATUS_ACTIVE,
      );

      // Bob is FROZEN but is NOT the seized owner → circuit expects ACTIVE for Bob → fails
      await expectCircuitReject(() =>
        proveForcedTransfer(
          Alice,
          [u1, u2],
          [newUTXO(100, Bob), ZERO_UTXO],
          [Bob, Bob],
          smtAlice,
          smtKyc,
          smtCompBothFrozen,
          Arbiter,
          Enforcer,
          genKeypair(),
        ),
      );
    });
  });

  // ── stale root rejection ──

  describe("stale root rejection", function () {
    it("transfer fails on-chain with stale compliance root", async function () {
      this.timeout(600000);
      const u1 = newUTXO(30, Alice);
      const u2 = newUTXO(70, Alice);
      await mintAndTrack([u1, u2]);

      // Generate proof against current (all-active) compliance root
      const ephKp = genKeypair();
      const tp = await proveTransfer(
        Alice,
        [u1, u2],
        [newUTXO(50, Bob), newUTXO(50, Alice)],
        [Bob, Alice],
        smtAlice,
        smtKyc,
        smtCompAllActive,
        Arbiter,
        Enforcer,
        ephKp,
      );

      // Swap compliance root on-chain before submitting
      const frozenRoot = (
        await complianceProof(smtCompAliceFrozen, Alice.babyJubPublicKey)
      ).root;
      await (
        await zeto.connect(deployer).setComplianceRoot(frozenRoot, "0x")
      ).wait();

      // Proof was generated against old root → pi mismatch → verifier rejects
      await expect(
        zeto.connect(Alice.signer).transfer(
          tp.nullifiers!.filter((n) => n !== 0n),
          tp.outputCommitments.filter((c) => c !== 0n),
          encodeTransferProof(
            tp.utxosRoot!,
            tp.enfNullifiers,
            tp.encryptionNonce,
            tp.ecdhPublicKey,
            tp.encRecv!,
            tp.encArb!,
            tp.encEnf,
            tp.encodedProof,
          ),
          "0x",
        ),
      ).to.be.revertedWithCustomError(zeto, "InvalidProof");

      // Restore active root
      const activeRoot = (
        await complianceProof(smtCompAllActive, Alice.babyJubPublicKey)
      ).root;
      await (
        await zeto.connect(deployer).setComplianceRoot(activeRoot, "0x")
      ).wait();
    });
  });

  // ── disabled-slot gating ──

  describe("disabled-slot gating", function () {
    it("transfer with one zero input and one zero output succeeds (padding slots skipped)", async function () {
      this.timeout(600000);
      const u1 = newUTXO(100, Alice);
      await mintAndTrack([u1]);

      const ephKp = genKeypair();
      const tp = await proveTransfer(
        Alice,
        [u1, ZERO_UTXO],
        [newUTXO(50, Bob), newUTXO(50, Alice)],
        [Bob, Alice],
        smtAlice,
        smtKyc,
        smtCompAllActive,
        Arbiter,
        Enforcer,
        ephKp,
      );

      const result = await (
        await zeto.connect(Alice.signer).transfer(
          tp.nullifiers!.filter((n) => n !== 0n),
          tp.outputCommitments.filter((c) => c !== 0n),
          encodeTransferProof(
            tp.utxosRoot!,
            tp.enfNullifiers,
            tp.encryptionNonce,
            tp.ecdhPublicKey,
            tp.encRecv!,
            tp.encArb!,
            tp.encEnf,
            tp.encodedProof,
          ),
          "0x",
        )
      ).wait();
      expect(result!.status).to.equal(1);

      // Zero-input slot's nullifiers should NOT be marked spent
      expect(await zeto.ownerNullifierSpent(tp.nullifiers![1])).to.be.false;
      expect(await zeto.enforcementNullifierSpent(tp.enfNullifiers[1])).to.be
        .false;

      await trackUtxos(
        [smtAlice, smtBob],
        ...tp.outputCommitments
          .filter((c) => c !== 0n)
          .map((c) => ({ hash: c, value: 50 }) as UTXO),
      );
    });
  });

  // ── enforcement-nullifier duplicate rejection ──

  describe("enforcement-nullifier duplicate rejection", function () {
    // The facet checks the enforcement nullifiers before the verifier runs, so
    // the contract's own verdict on a repeated tag is observable independently
    // of the circuit. The owner-nullifier and output-commitment domains have
    // always rejected an in-batch duplicate (lib/storage/nullifier.sol); these
    // cases pin that the third domain does too, and that a zero tag -- which
    // marks a disabled slot -- stays exempt.
    //
    // The proof blobs here are synthetic: every field the contract reads before
    // the enforcement-nullifier check is valid, and the Groth16 proof is not.
    // A submission that gets past the check therefore reverts InvalidProof,
    // which is exactly the signal that the tag check did not fire.
    const DUMMY_PROOF = {
      pA: [1n, 2n],
      pB: [
        [3n, 4n],
        [5n, 6n],
      ],
      pC: [7n, 8n],
    };
    const words = (n: number, base: bigint) =>
      Array.from({ length: n }, (_, i) => base + BigInt(i));

    // Canonical ciphertext arities for the three tag-carrying circuits.
    const ENC_RECEIVER = 8;
    const ENC_AUTHORITY = 16;

    const TAG = 0x5eed1234n;
    const OTHER_TAG = 0x5eed5678n;

    /** Fresh, unspent nullifiers and unused output commitments per case. */
    let seq = 0;
    const fresh = () => {
      seq += 1;
      return {
        nullifiers: [
          0x100000n + BigInt(seq) * 2n,
          0x100001n + BigInt(seq) * 2n,
        ],
        outputs: [0x200000n + BigInt(seq) * 2n, 0x200001n + BigInt(seq) * 2n],
      };
    };

    before(async function () {
      // The suite configures the authorities in the "deployment and admin"
      // block. Re-apply them here so this block also runs standalone.
      if ((await zeto.getEnforcer())[0] === 0n) {
        await (
          await zeto.connect(deployer).setEnforcer(Enforcer.babyJubPublicKey)
        ).wait();
      }
      if ((await zeto.getArbiterKeyId()) === 0n) {
        await (
          await zeto.connect(deployer).setArbiter(Arbiter.babyJubPublicKey)
        ).wait();
      }
    });

    const transferBlob = async (enfN: bigint[]) =>
      encodeTransferProof(
        await zeto.getRoot(),
        enfN as unknown as BigInt[],
        1,
        [1, 2],
        words(ENC_RECEIVER, 3000n),
        words(ENC_AUTHORITY, 4000n),
        words(ENC_AUTHORITY, 5000n),
        DUMMY_PROOF,
      );

    const withdrawBlob = async (enfN: bigint[]) =>
      encodeWithdrawProof(
        await zeto.getRoot(),
        enfN as unknown as BigInt[],
        1,
        [1, 2],
        words(ENC_AUTHORITY, 4000n),
        words(ENC_AUTHORITY, 5000n),
        DUMMY_PROOF,
      );

    const forcedBlob = async (enfN: bigint[]) =>
      encodeForcedTransferProof(
        enfN as unknown as BigInt[],
        await zeto.getRoot(),
        [1, 1],
        1,
        [1, 2],
        words(ENC_RECEIVER, 3000n),
        words(ENC_AUTHORITY, 4000n),
        words(ENC_AUTHORITY, 5000n),
        DUMMY_PROOF,
      );

    it("transfer rejects a tag repeated within the batch", async function () {
      const { nullifiers, outputs } = fresh();
      await expect(
        zeto
          .connect(Alice.signer)
          .transfer(nullifiers, outputs, await transferBlob([TAG, TAG]), "0x"),
      )
        .to.be.revertedWithCustomError(zeto, "EnforcementNullifierDuplicate")
        .withArgs(TAG);
    });

    it("withdraw rejects a tag repeated within the batch", async function () {
      const { nullifiers, outputs } = fresh();
      await expect(
        zeto
          .connect(Alice.signer)
          .withdraw(
            10,
            nullifiers,
            outputs[0],
            await withdrawBlob([TAG, TAG]),
            "0x",
          ),
      )
        .to.be.revertedWithCustomError(zeto, "EnforcementNullifierDuplicate")
        .withArgs(TAG);
    });

    it("forcedTransfer rejects a tag repeated within the batch", async function () {
      const { outputs } = fresh();
      await expect(
        zeto
          .connect(deployer)
          .forcedTransfer(outputs, await forcedBlob([TAG, TAG]), "0x"),
      )
        .to.be.revertedWithCustomError(zeto, "EnforcementNullifierDuplicate")
        .withArgs(TAG);
    });

    it("two disabled slots are not treated as a duplicate", async function () {
      // After the disabled-slot gating fix a zero tag means "slot off", and a
      // batch may legitimately carry more than one. This must reach the
      // verifier, not the duplicate check.
      const { nullifiers, outputs } = fresh();
      await expect(
        zeto
          .connect(Alice.signer)
          .transfer(nullifiers, outputs, await transferBlob([0n, 0n]), "0x"),
      ).to.be.revertedWithCustomError(zeto, "InvalidProof");
    });

    it("one live tag beside a disabled slot is accepted", async function () {
      const { nullifiers, outputs } = fresh();
      await expect(
        zeto
          .connect(Alice.signer)
          .transfer(nullifiers, outputs, await transferBlob([TAG, 0n]), "0x"),
      ).to.be.revertedWithCustomError(zeto, "InvalidProof");
    });

    it("two distinct tags are accepted", async function () {
      const { nullifiers, outputs } = fresh();
      await expect(
        zeto
          .connect(Alice.signer)
          .transfer(
            nullifiers,
            outputs,
            await transferBlob([TAG, OTHER_TAG]),
            "0x",
          ),
      ).to.be.revertedWithCustomError(zeto, "InvalidProof");
    });
  });

  // ── forced transfer access control ──

  describe("forced transfer access control", function () {
    it("forcedTransfer reverts when enforcer key is wrong in proof", async function () {
      this.timeout(600000);
      const u1 = newUTXO(50, Alice);
      const u2 = newUTXO(50, Alice);
      await mintAndTrack([u1, u2]);

      // Ensure on-chain compliance root is Alice-frozen
      const frozenRoot = (
        await complianceProof(smtCompAliceFrozen, Alice.babyJubPublicKey)
      ).root;
      await (
        await zeto.connect(deployer).setComplianceRoot(frozenRoot, "0x")
      ).wait();

      // FakeEnforcer: different private key → BabyPbk(fakePriv) != enforcerPublicKey → constraint fails
      const FakeEnforcer = await newUser((await ethers.getSigners())[9]);

      await expectCircuitReject(async () => {
        const inputCommitments = [u1, u2].map((u) => u.hash);
        const enfNullifiers = inputCommitments.map((c) =>
          computeEnforcementNullifier(
            FakeEnforcer.babyJubPrivateKey,
            Alice.babyJubPublicKey,
            c,
          ),
        );
        const enabledInputs = inputCommitments.map((c) => (c !== 0n ? 1 : 0));
        const encryptionNonce = newEncryptionNonce() as BigNumberish;
        const ephKp = genKeypair();
        const out1 = newUTXO(100, Charlie);

        const actors = [Alice, Charlie, Charlie];
        const kycProofs = await Promise.all(
          actors.map((a) => kycProof(smtKyc, a.babyJubPublicKey)),
        );
        const compProofs = await Promise.all(
          actors.map((a) =>
            complianceProof(smtCompAliceFrozen, a.babyJubPublicKey),
          ),
        );
        const utxoProofs = await Promise.all(
          inputCommitments.map((c) => utxoProof(smtAlice, c)),
        );

        await generateProof("forced_transfer_nullifier_kyc_enforced", {
          enforcementNullifiers: enfNullifiers,
          outputCommitments: [out1.hash, ZERO_UTXO.hash],
          utxosRoot: utxoProofs[0].root,
          identitiesRoot: kycProofs[0].root,
          complianceRoot: compProofs[0].root,
          enabledInputs,
          enforcerPublicKey: Enforcer.babyJubPublicKey, // real on-chain enforcer key
          arbiterPublicKey: Arbiter.babyJubPublicKey,
          inputCommitments,
          inputValues: [u1, u2].map((u) => BigInt(u.value || 0)),
          inputSalts: [u1, u2].map((u) => u.salt || 0n),
          seizedOwnerPublicKey: Alice.babyJubPublicKey,
          enforcerPrivateKey: FakeEnforcer.formattedPrivateKey, // WRONG key
          utxosMerkleProof: utxoProofs.map((p) => p.siblings),
          identitiesMerkleProof: kycProofs.map((p) => p.siblings),
          complianceMerkleProof: compProofs.map((p) => p.siblings),
          outputValues: [BigInt(out1.value || 0), 0n],
          outputSalts: [out1.salt || 0n, 0n],
          outputOwnerPublicKeys: [
            Charlie.babyJubPublicKey,
            Charlie.babyJubPublicKey,
          ],
          ...stringifyBigInts({
            encryptionNonce,
            ecdhPrivateKey: formatPrivKeyForBabyJub(ephKp.privKey),
          }),
        });
      });

      // Restore active root
      const activeRoot = (
        await complianceProof(smtCompAllActive, Alice.babyJubPublicKey)
      ).root;
      await (
        await zeto.connect(deployer).setComplianceRoot(activeRoot, "0x")
      ).wait();
    });
  });

  // ── codec proof-field arity (RC-01 / report IDs 7, 8, 9; ID 1 negative case) ──

  describe("codec proof-field arity", function () {
    // Every AENKNR-E circuit has a fixed public-signal layout. The codec fills a
    // fixed-size `pi` sequentially from caller-controlled dynamic lengths, so a
    // length-preserving shift between two adjacent dynamic fields yields a public
    // input vector bit-identical to a genuine proof's while the facet records
    // different values. These tests pin the exact per-circuit arities.

    const DUMMY_PROOF = {
      pA: [1n, 2n],
      pB: [
        [3n, 4n],
        [5n, 6n],
      ],
      pC: [7n, 8n],
    };

    /** n words of filler, distinct from each other so a shift is observable. */
    const words = (n: number, base = 1000n) =>
      Array.from({ length: n }, (_, i) => base + BigInt(i));

    /** abi.encode(head...) ++ 192 raw bytes of ProofContext, as the facet builds it. */
    function packArgs(types: string[], values: any[]): string {
      const head = new AbiCoder().encode(types, values);
      const ctx = words(6, 7000n)
        .map((v) => v.toString(16).padStart(64, "0"))
        .join("");
      return head + ctx;
    }

    let codec: any;

    before(async function () {
      codec = await (await ethers.getContractFactory("AENKNRECodec")).deploy();
      await codec.waitForDeployment();

      // The suite configures the authorities in the "deployment and admin" block.
      // Re-apply them here so this block also runs standalone under --grep.
      if ((await zeto.getEnforcer())[0] === 0n) {
        await (
          await zeto.connect(deployer).setEnforcer(Enforcer.babyJubPublicKey)
        ).wait();
      }
      if ((await zeto.getArbiterKeyId()) === 0n) {
        await (
          await zeto.connect(deployer).setArbiter(Arbiter.babyJubPublicKey)
        ).wait();
      }
    });

    // Canonical arities, cross-checked against each circuit's `main { public [...] }`
    // and against nPublic in the generated verification keys (58/52/50/56).
    const ENC_RECEIVER = 8; // 2 outputs x 4 fields
    const ENC_AUTHORITY = 16; // 14-field authority plaintext, Poseidon-padded
    const ARITY_2 = 2; // nullifiers, enforcement nullifiers, outputs, enabled

    function transferProof(o: any = {}) {
      return encodeTransferProof(
        1,
        o.enfN ?? words(ARITY_2, 2000n),
        1,
        [1, 2],
        o.encR ?? words(ENC_RECEIVER, 3000n),
        o.encA ?? words(ENC_AUTHORITY, 4000n),
        o.encE ?? words(ENC_AUTHORITY, 5000n),
        DUMMY_PROOF,
      );
    }
    const transferArgs = (o: any = {}) =>
      packArgs(
        ["uint256[]", "uint256[]"],
        [
          o.nullifiers ?? words(ARITY_2, 100n),
          o.outputs ?? words(ARITY_2, 200n),
        ],
      );

    function depositProof(o: any = {}) {
      return encodeDepositProof(
        1,
        [1, 2],
        o.encR ?? words(ENC_RECEIVER, 3000n),
        o.encA ?? words(ENC_AUTHORITY, 4000n),
        o.encE ?? words(ENC_AUTHORITY, 5000n),
        DUMMY_PROOF,
      );
    }
    const depositArgs = (o: any = {}) =>
      packArgs(
        ["uint256", "uint256[]"],
        [100, o.outputs ?? words(ARITY_2, 200n)],
      );

    function withdrawProof(o: any = {}) {
      return encodeWithdrawProof(
        1,
        o.enfN ?? words(ARITY_2, 2000n),
        1,
        [1, 2],
        o.encA ?? words(ENC_AUTHORITY, 4000n),
        o.encE ?? words(ENC_AUTHORITY, 5000n),
        DUMMY_PROOF,
      );
    }
    const withdrawArgs = (o: any = {}) =>
      packArgs(
        ["uint256", "uint256[]", "uint256", "uint256"],
        [
          100,
          o.nullifiers ?? words(ARITY_2, 100n),
          200,
          o.recipient ?? 0x1234n, // proof-bound withdrawal recipient
        ],
      );

    function forcedProof(o: any = {}) {
      return encodeForcedTransferProof(
        o.enfN ?? words(ARITY_2, 2000n),
        1,
        (o.enabled ?? [1, 1]) as number[],
        1,
        [1, 2],
        o.encR ?? words(ENC_RECEIVER, 3000n),
        o.encA ?? words(ENC_AUTHORITY, 4000n),
        o.encE ?? words(ENC_AUTHORITY, 5000n),
        DUMMY_PROOF,
      );
    }
    const forcedArgs = (o: any = {}) =>
      packArgs(["uint256[]"], [o.outputs ?? words(ARITY_2, 200n)]);

    it("accepts the exact canonical arity for all four builders", async function () {
      // Positive control: these lengths are the ones the circuits declare, so a
      // regression that tightened the wrong field would fail here.
      const pi = [
        (await codec.buildTransfer(transferProof(), transferArgs()))[0],
        (await codec.buildDeposit(depositProof(), depositArgs()))[0],
        (await codec.buildWithdraw(withdrawProof(), withdrawArgs()))[0],
        (await codec.buildForcedTransfer(forcedProof(), forcedArgs()))[0],
      ];
      expect(pi.map((p: any) => p.length)).to.deep.equal([58, 52, 51, 56]);
    });

    // Each row: builder name, proof/args factories, and the field it perturbs.
    const cases: Array<[string, (o: any) => Promise<any>, string, number]> = [
      [
        "buildTransfer",
        (o) => codec.buildTransfer(transferProof(o), transferArgs(o)),
        "encR",
        ENC_RECEIVER,
      ],
      [
        "buildTransfer",
        (o) => codec.buildTransfer(transferProof(o), transferArgs(o)),
        "encA",
        ENC_AUTHORITY,
      ],
      [
        "buildTransfer",
        (o) => codec.buildTransfer(transferProof(o), transferArgs(o)),
        "encE",
        ENC_AUTHORITY,
      ],
      [
        "buildTransfer",
        (o) => codec.buildTransfer(transferProof(o), transferArgs(o)),
        "enfN",
        ARITY_2,
      ],
      [
        "buildTransfer",
        (o) => codec.buildTransfer(transferProof(o), transferArgs(o)),
        "nullifiers",
        ARITY_2,
      ],
      [
        "buildTransfer",
        (o) => codec.buildTransfer(transferProof(o), transferArgs(o)),
        "outputs",
        ARITY_2,
      ],
      [
        "buildDeposit",
        (o) => codec.buildDeposit(depositProof(o), depositArgs(o)),
        "encR",
        ENC_RECEIVER,
      ],
      [
        "buildDeposit",
        (o) => codec.buildDeposit(depositProof(o), depositArgs(o)),
        "encA",
        ENC_AUTHORITY,
      ],
      [
        "buildDeposit",
        (o) => codec.buildDeposit(depositProof(o), depositArgs(o)),
        "encE",
        ENC_AUTHORITY,
      ],
      [
        "buildDeposit",
        (o) => codec.buildDeposit(depositProof(o), depositArgs(o)),
        "outputs",
        ARITY_2,
      ],
      [
        "buildWithdraw",
        (o) => codec.buildWithdraw(withdrawProof(o), withdrawArgs(o)),
        "encA",
        ENC_AUTHORITY,
      ],
      [
        "buildWithdraw",
        (o) => codec.buildWithdraw(withdrawProof(o), withdrawArgs(o)),
        "encE",
        ENC_AUTHORITY,
      ],
      [
        "buildWithdraw",
        (o) => codec.buildWithdraw(withdrawProof(o), withdrawArgs(o)),
        "enfN",
        ARITY_2,
      ],
      [
        "buildWithdraw",
        (o) => codec.buildWithdraw(withdrawProof(o), withdrawArgs(o)),
        "nullifiers",
        ARITY_2,
      ],
      [
        "buildForcedTransfer",
        (o) => codec.buildForcedTransfer(forcedProof(o), forcedArgs(o)),
        "encR",
        ENC_RECEIVER,
      ],
      [
        "buildForcedTransfer",
        (o) => codec.buildForcedTransfer(forcedProof(o), forcedArgs(o)),
        "encA",
        ENC_AUTHORITY,
      ],
      [
        "buildForcedTransfer",
        (o) => codec.buildForcedTransfer(forcedProof(o), forcedArgs(o)),
        "encE",
        ENC_AUTHORITY,
      ],
      [
        "buildForcedTransfer",
        (o) => codec.buildForcedTransfer(forcedProof(o), forcedArgs(o)),
        "enfN",
        ARITY_2,
      ],
      [
        "buildForcedTransfer",
        (o) => codec.buildForcedTransfer(forcedProof(o), forcedArgs(o)),
        "outputs",
        ARITY_2,
      ],
      [
        "buildForcedTransfer",
        (o) => codec.buildForcedTransfer(forcedProof(o), forcedArgs(o)),
        "enabled",
        ARITY_2,
      ],
    ];

    for (const [name, call, field, len] of cases) {
      it(`${name} rejects a short ${field} (${len - 1} of ${len})`, async function () {
        await expect(call({ [field]: words(len - 1, 9000n) }))
          .to.be.revertedWithCustomError(codec, "InvalidProofFieldArity")
          .withArgs(len, len - 1);
      });
      it(`${name} rejects a long ${field} (${len + 1} of ${len})`, async function () {
        await expect(call({ [field]: words(len + 1, 9000n) }))
          .to.be.revertedWithCustomError(codec, "InvalidProofFieldArity")
          .withArgs(len, len + 1);
      });
    }

    it("buildTransfer rejects the length-preserving encE/enfN shift", async function () {
      // The exploit shape: two extra words appended to encE displace the owner
      // nullifier slots, and an empty enfN lets the calldata nullifiers land in
      // the enforcement slots. Total pi length is unchanged at 58.
      await expect(
        codec.buildTransfer(
          transferProof({ encE: words(ENC_AUTHORITY + 2, 5000n), enfN: [] }),
          transferArgs(),
        ),
      ).to.be.revertedWithCustomError(codec, "InvalidProofFieldArity");
    });

    it("buildDeposit rejects a third output commitment", async function () {
      // Report ID 1: the facet binds every output, so a third output previously
      // ran `pi` past its 52 slots and panicked. It is now an explicit arity revert.
      await expect(
        codec.buildDeposit(
          depositProof(),
          depositArgs({ outputs: words(3, 200n) }),
        ),
      )
        .to.be.revertedWithCustomError(codec, "InvalidProofFieldArity")
        .withArgs(2, 3);
    });

    it("rejects args shorter than the 192-byte proof context", async function () {
      const short = "0x" + "11".repeat(191);
      await expect(codec.buildTransfer(transferProof(), short))
        .to.be.revertedWithCustomError(codec, "InvalidArgsLength")
        .withArgs(191);
    });

    it("arity-shifted transfer proof cannot desynchronize the two nullifier families", async function () {
      this.timeout(600000);
      const activeRoot = (
        await complianceProof(smtCompAllActive, Alice.babyJubPublicKey)
      ).root;
      await (
        await zeto.connect(deployer).setComplianceRoot(activeRoot, "0x")
      ).wait();

      const u1 = newUTXO(60, Alice);
      const u2 = newUTXO(40, Alice);
      await mintAndTrack([u1, u2]);

      // 1. Spend both notes honestly. Both nullifier families are now marked.
      const ephKp1 = genKeypair();
      const honest = await proveTransfer(
        Alice,
        [u1, u2],
        [newUTXO(60, Bob), newUTXO(40, Alice)],
        [Bob, Alice],
        smtAlice,
        smtKyc,
        smtCompAllActive,
        Arbiter,
        Enforcer,
        ephKp1,
      );
      await (
        await zeto.connect(Alice.signer).transfer(
          honest.nullifiers!.filter((n) => n !== 0n),
          honest.outputCommitments.filter((c) => c !== 0n),
          encodeTransferProof(
            honest.utxosRoot!,
            honest.enfNullifiers,
            honest.encryptionNonce,
            honest.ecdhPublicKey,
            honest.encRecv!,
            honest.encArb!,
            honest.encEnf,
            honest.encodedProof,
          ),
          "0x",
        )
      ).wait();
      await trackUtxos(
        [smtAlice, smtBob],
        ...honest.outputCommitments
          .filter((c) => c !== 0n)
          .map((c) => ({ hash: c, value: 50 }) as UTXO),
      );

      const ownerN = honest.nullifiers!;
      const enfN = honest.enfNullifiers;
      expect(await zeto.ownerNullifierSpent(ownerN[0])).to.be.true;
      expect(await zeto.enforcementNullifierSpent(enfN[0])).to.be.true;

      // 2. Build a second genuine proof spending the very same notes again.
      const stolen1 = newUTXO(60, Bob);
      const stolen2 = newUTXO(40, Bob);
      const ephKp2 = genKeypair();
      const replay = await proveTransfer(
        Alice,
        [u1, u2],
        [stolen1, stolen2],
        [Bob, Bob],
        smtAlice,
        smtKyc,
        smtCompAllActive,
        Arbiter,
        Enforcer,
        ephKp2,
      );

      // Submitted honestly it is rejected: the owner nullifiers are spent.
      await expect(
        zeto.connect(Alice.signer).transfer(
          replay.nullifiers!.filter((n) => n !== 0n),
          replay.outputCommitments.filter((c) => c !== 0n),
          encodeTransferProof(
            replay.utxosRoot!,
            replay.enfNullifiers,
            replay.encryptionNonce,
            replay.ecdhPublicKey,
            replay.encRecv!,
            replay.encArb!,
            replay.encEnf,
            replay.encodedProof,
          ),
          "0x",
        ),
      ).to.be.reverted;

      // 3. Re-pack the same proof bytes so the codec shifts the two nullifier
      //    families by exactly two slots. pi is bit-identical to the honest
      //    vector, so the Groth16 proof still verifies, but the contract would
      //    mark the *enforcement* tags in the owner mapping and mark nothing at
      //    all in the enforcement mapping — re-spending fully spent notes.
      const shiftedEncE = [...(replay.encEnf as any[]), ownerN[0], ownerN[1]];
      expect(shiftedEncE.length).to.equal(ENC_AUTHORITY + 2);

      await expect(
        zeto.connect(Alice.signer).transfer(
          enfN as any, // enforcement tags posing as owner nullifiers
          replay.outputCommitments.filter((c) => c !== 0n),
          encodeTransferProof(
            replay.utxosRoot!,
            [], // enfN emptied to preserve total length
            replay.encryptionNonce,
            replay.ecdhPublicKey,
            replay.encRecv!,
            replay.encArb!,
            shiftedEncE,
            replay.encodedProof,
          ),
          "0x",
        ),
      ).to.be.revertedWith("Codec call failed");

      // The notes stayed spent and no new commitment was created.
      expect(await zeto.ownerNullifierSpent(enfN[0])).to.be.false;
      for (const c of replay.outputCommitments) {
        if (c !== 0n) expect(await zeto.spent(c)).to.equal(0n); // UTXOStatus.UNKNOWN
      }
    });
  });

  // ── withdraw checks-effects-interactions (RC-03 / report IDs 5A, 12, 15) ──

  describe("withdraw reentrancy", function () {
    let malicious: any;
    // This block needs the pool backed by a callback-capable ERC-20, and
    // `setERC20` is one-shot, so it runs against its own token instance with
    // its own commitments mirror.
    let zeto: any;
    let deployer: Signer;
    let smt: Merkletree;

    async function mintAndTrack(utxos: UTXO[]) {
      await mintInto(zeto, deployer, [smt], utxos);
    }

    before(async function () {
      this.timeout(600000);
      malicious = await (
        await ethers.getContractFactory("ReentrantWithdrawERC20")
      ).deploy();
      await malicious.waitForDeployment();
      ({
        owner: deployer,
        token: zeto,
        smt,
      } = await deployTokenBackedBy(malicious.target, "reentrancy"));
      // Fund the pool's reserves.
      await (await malicious.mint(zeto.target, 1000)).wait();
    });

    it("a reentrant ERC-20 callback cannot redeem the same note twice", async function () {
      this.timeout(600000);
      const u1 = newUTXO(60, Alice);
      const u2 = newUTXO(40, Alice);
      await mintAndTrack([u1, u2]);

      // Full withdrawal: the change slot is zero, so the nested call inserts no
      // leaf and cannot be stopped by a duplicate-commitment revert. That keeps
      // the ordering defect, rather than output validation, the thing under test.
      const ephKp = genKeypair();
      const wp = await proveWithdraw(
        Alice,
        [u1, u2],
        ZERO_UTXO,
        100,
        smt,
        smtKyc,
        smtCompAllActive,
        Arbiter,
        Enforcer,
        ephKp,
      );

      const proofBytes = encodeWithdrawProof(
        wp.utxosRoot!,
        wp.enfNullifiers,
        wp.encryptionNonce,
        wp.ecdhPublicKey,
        wp.encArb!,
        wp.encEnf,
        wp.encodedProof,
      );
      const args = [
        100,
        wp.ownerNullifiers!,
        wp.changeCommitment,
        proofBytes,
        "0x",
      ];

      // The nested call comes from the token, so its msg.sender is the token.
      // Bind a second proof to that recipient; otherwise the nested call would
      // fail the recipient binding and never reach the spend check under test.
      const nested = await proveWithdraw(
        Alice,
        [u1, u2],
        ZERO_UTXO,
        100,
        smt,
        smtKyc,
        smtCompAllActive,
        Arbiter,
        Enforcer,
        genKeypair(),
        malicious.target,
      );
      await (
        await malicious.arm(
          zeto.target,
          zeto.interface.encodeFunctionData("withdraw", [
            100,
            nested.ownerNullifiers!,
            nested.changeCommitment,
            encodeWithdrawProof(
              nested.utxosRoot!,
              nested.enfNullifiers,
              nested.encryptionNonce,
              nested.ecdhPublicKey,
              nested.encArb!,
              nested.encEnf,
              nested.encodedProof,
            ),
            "0x",
          ] as any),
        )
      ).wait();

      const poolBefore = await malicious.balanceOf(zeto.target);
      await (
        await zeto.connect(Alice.signer).withdraw(...(args as any))
      ).wait();
      const poolAfter = await malicious.balanceOf(zeto.target);

      // The callback fired, but the note must only ever pay out once.
      expect(await malicious.reentered()).to.be.true;
      expect(await malicious.reentrySucceeded()).to.be.false;
      expect(poolBefore - poolAfter).to.equal(100n);

      // Both nullifier families are marked exactly once by the outer call.
      for (const n of wp.ownerNullifiers!) {
        if (n !== 0n) expect(await zeto.ownerNullifierSpent(n)).to.be.true;
      }
      for (const n of wp.enfNullifiers) {
        if (n !== 0n)
          expect(await zeto.enforcementNullifierSpent(n)).to.be.true;
      }
    });

    it("a failing ERC-20 transfer reverts the whole withdrawal", async function () {
      this.timeout(600000);
      // A pool backed by a token it holds no reserves of, so the payout fails.
      const empty = await (
        await ethers.getContractFactory("ReentrantWithdrawERC20")
      ).deploy();
      await empty.waitForDeployment();
      const {
        owner: emptyOwner,
        token: emptyZeto,
        smt: emptySmt,
      } = await deployTokenBackedBy(empty.target, "reentrancy-empty");

      const u1 = newUTXO(50, Alice);
      const u2 = newUTXO(50, Alice);
      await mintInto(emptyZeto, emptyOwner, [emptySmt], [u1, u2]);

      const ephKp = genKeypair();
      const wp = await proveWithdraw(
        Alice,
        [u1, u2],
        ZERO_UTXO,
        100,
        emptySmt,
        smtKyc,
        smtCompAllActive,
        Arbiter,
        Enforcer,
        ephKp,
      );

      await expect(
        emptyZeto
          .connect(Alice.signer)
          .withdraw(
            100,
            wp.ownerNullifiers!,
            wp.changeCommitment,
            encodeWithdrawProof(
              wp.utxosRoot!,
              wp.enfNullifiers,
              wp.encryptionNonce,
              wp.ecdhPublicKey,
              wp.encArb!,
              wp.encEnf,
              wp.encodedProof,
            ),
            "0x",
          ),
      ).to.be.reverted;

      // The revert rolls the spend back: both notes remain spendable.
      for (const n of wp.ownerNullifiers!) {
        if (n !== 0n)
          expect(await emptyZeto.ownerNullifierSpent(n)).to.be.false;
      }
      for (const n of wp.enfNullifiers) {
        if (n !== 0n)
          expect(await emptyZeto.enforcementNullifierSpent(n)).to.be.false;
      }
    });

    it("a partial withdrawal with a change note still succeeds", async function () {
      this.timeout(600000);
      const u1 = newUTXO(70, Alice);
      const u2 = newUTXO(30, Alice);
      await mintAndTrack([u1, u2]);

      const changeUtxo = newUTXO(25, Alice);
      const ephKp = genKeypair();
      const wp = await proveWithdraw(
        Alice,
        [u1, u2],
        changeUtxo,
        75,
        smt,
        smtKyc,
        smtCompAllActive,
        Arbiter,
        Enforcer,
        ephKp,
      );

      const before = await malicious.balanceOf(Alice.ethAddress);
      await (
        await zeto
          .connect(Alice.signer)
          .withdraw(
            75,
            wp.ownerNullifiers!,
            wp.changeCommitment,
            encodeWithdrawProof(
              wp.utxosRoot!,
              wp.enfNullifiers,
              wp.encryptionNonce,
              wp.ecdhPublicKey,
              wp.encArb!,
              wp.encEnf,
              wp.encodedProof,
            ),
            "0x",
          )
      ).wait();
      expect((await malicious.balanceOf(Alice.ethAddress)) - before).to.equal(
        75n,
      );
      await trackUtxos([smt], changeUtxo);
    });
  });

  // ── enforcement-nullifier staging lifecycle (RC-04 / invariant 11) ──

  describe("pending enforcement-nullifier staging", function () {
    // `pendingEnfNullifiers` is field 0 of the ERC-7201 Layout, so it lives at
    // the namespace slot itself; for a dynamic array that slot holds the length.
    // Reading it directly keeps the invariant observable without widening the
    // production ABI with a view helper.
    const AENKNRE_SLOT = ethers.keccak256(
      AbiCoder.defaultAbiCoder().encode(
        ["uint256"],
        [
          BigInt(ethers.keccak256(ethers.toUtf8Bytes("zeto.storage.aenknre"))) -
            1n,
        ],
      ),
    );

    async function pendingLength(): Promise<bigint> {
      return BigInt(
        await ethers.provider.getStorage(zeto.target, AENKNRE_SLOT),
      );
    }

    before(async function () {
      if ((await zeto.getEnforcer())[0] === 0n) {
        await (
          await zeto.connect(deployer).setEnforcer(Enforcer.babyJubPublicKey)
        ).wait();
      }
      if ((await zeto.getArbiterKeyId()) === 0n) {
        await (
          await zeto.connect(deployer).setArbiter(Arbiter.babyJubPublicKey)
        ).wait();
      }
      const activeRoot = (
        await complianceProof(smtCompAllActive, Alice.babyJubPublicKey)
      ).root;
      await (
        await zeto.connect(deployer).setComplianceRoot(activeRoot, "0x")
      ).wait();

      // Earlier suites drew the pool's reserves down; top them up so the
      // withdraw below exercises staging rather than ERC-20 custody.
      await (await erc20.connect(deployer).mint(zeto.target, 10000)).wait();
    });

    it("staging is cleared after a successful transfer", async function () {
      this.timeout(600000);
      const u1 = newUTXO(30, Alice);
      const u2 = newUTXO(70, Alice);
      await mintAndTrack([u1, u2]);

      const out1 = newUTXO(60, Bob);
      const out2 = newUTXO(40, Alice);
      const ephKp = genKeypair();
      const tp = await proveTransfer(
        Alice,
        [u1, u2],
        [out1, out2],
        [Bob, Alice],
        smtAlice,
        smtKyc,
        smtCompAllActive,
        Arbiter,
        Enforcer,
        ephKp,
      );

      await (
        await zeto.connect(Alice.signer).transfer(
          tp.nullifiers!.filter((n) => n !== 0n),
          tp.outputCommitments.filter((c) => c !== 0n),
          encodeTransferProof(
            tp.utxosRoot!,
            tp.enfNullifiers,
            tp.encryptionNonce,
            tp.ecdhPublicKey,
            tp.encRecv!,
            tp.encArb!,
            tp.encEnf,
            tp.encodedProof,
          ),
          "0x",
        )
      ).wait();
      await trackUtxos([smtAlice, smtBob], out1, out2);

      for (const n of tp.enfNullifiers) {
        if (n !== 0n)
          expect(await zeto.enforcementNullifierSpent(n)).to.be.true;
      }
      expect(await pendingLength()).to.equal(0n);
    });

    it("staging is cleared after a successful withdraw", async function () {
      this.timeout(600000);
      const u1 = newUTXO(45, Alice);
      const u2 = newUTXO(55, Alice);
      await mintAndTrack([u1, u2]);

      const changeUtxo = newUTXO(20, Alice);
      const ephKp = genKeypair();
      const wp = await proveWithdraw(
        Alice,
        [u1, u2],
        changeUtxo,
        80,
        smtAlice,
        smtKyc,
        smtCompAllActive,
        Arbiter,
        Enforcer,
        ephKp,
      );

      await (
        await zeto
          .connect(Alice.signer)
          .withdraw(
            80,
            wp.ownerNullifiers!,
            wp.changeCommitment,
            encodeWithdrawProof(
              wp.utxosRoot!,
              wp.enfNullifiers,
              wp.encryptionNonce,
              wp.ecdhPublicKey,
              wp.encArb!,
              wp.encEnf,
              wp.encodedProof,
            ),
            "0x",
          )
      ).wait();
      await trackUtxos([smtAlice, smtBob], changeUtxo);

      for (const n of wp.enfNullifiers) {
        if (n !== 0n)
          expect(await zeto.enforcementNullifierSpent(n)).to.be.true;
      }
      expect(await pendingLength()).to.equal(0n);
    });

    it("a later operation marks only its own enforcement nullifiers", async function () {
      this.timeout(600000);
      const u1 = newUTXO(15, Alice);
      const u2 = newUTXO(85, Alice);
      await mintAndTrack([u1, u2]);

      // A forced transfer consumes no staged transfer/withdraw values, so after
      // the preceding operations nothing stale may be marked on its behalf.
      const fresh = newUTXO(11, Alice);
      const other = newUTXO(89, Alice);
      const staleTag = computeEnforcementNullifier(
        Alice.babyJubPrivateKey,
        Enforcer.babyJubPublicKey,
        fresh.hash as bigint,
      );
      expect(await zeto.enforcementNullifierSpent(staleTag)).to.be.false;

      const outBob = newUTXO(100, Bob);
      const ephKp = genKeypair();
      const tp = await proveTransfer(
        Alice,
        [u1, u2],
        [outBob, ZERO_UTXO],
        [Bob, Bob],
        smtAlice,
        smtKyc,
        smtCompAllActive,
        Arbiter,
        Enforcer,
        ephKp,
      );

      await (
        await zeto.connect(Alice.signer).transfer(
          tp.nullifiers!.filter((n) => n !== 0n),
          tp.outputCommitments.filter((c) => c !== 0n),
          encodeTransferProof(
            tp.utxosRoot!,
            tp.enfNullifiers,
            tp.encryptionNonce,
            tp.ecdhPublicKey,
            tp.encRecv!,
            tp.encArb!,
            tp.encEnf,
            tp.encodedProof,
          ),
          "0x",
        )
      ).wait();
      await trackUtxos([smtAlice, smtBob], outBob);

      // Only this transaction's tags were marked; the unrelated note is untouched.
      for (const n of tp.enfNullifiers) {
        if (n !== 0n)
          expect(await zeto.enforcementNullifierSpent(n)).to.be.true;
      }
      expect(await zeto.enforcementNullifierSpent(staleTag)).to.be.false;
      expect(other.hash).to.not.equal(0n);
      expect(await pendingLength()).to.equal(0n);
    });
  });

  // ── deposit collateral conservation (RC-05 / report IDs 3, 13, 17) ──

  describe("deposit collateral", function () {
    let feeToken: any;
    // `setERC20` is one-shot, so the fee-on-transfer backing asset needs its
    // own token instance rather than a swap on the shared one.
    let zeto: any;
    let deployer: Signer;
    let smt: Merkletree;

    /** Build a genuine 2-output deposit proof summing to `amount`. */
    async function depositProofFor(amount: number) {
      const half = amount / 2;
      const o1 = newUTXO(half, Alice);
      const o2 = newUTXO(amount - half, Alice);
      const ephKp = genKeypair();
      const dp = await proveDeposit(
        [o1, o2],
        [Alice, Alice],
        smtKyc,
        smtCompAllActive,
        Arbiter,
        Enforcer,
        ephKp,
      );
      return { dp, utxos: [o1, o2] };
    }

    before(async function () {
      this.timeout(600000);
      feeToken = await (
        await ethers.getContractFactory("FeeOnTransferERC20")
      ).deploy();
      await feeToken.waitForDeployment();
      await (await feeToken.mint(Alice.ethAddress, 100000)).wait();
      ({
        owner: deployer,
        token: zeto,
        smt,
      } = await deployTokenBackedBy(feeToken.target, "deposit-collateral"));
    });

    it("rejects a deposit that credits less than the proof-bound amount", async function () {
      this.timeout(600000);
      await (await feeToken.setFeeBps(100)).wait(); // 1% withheld
      const { dp } = await depositProofFor(100);
      await (
        await feeToken.connect(Alice.signer).approve(zeto.target, 100)
      ).wait();

      await expect(
        zeto
          .connect(Alice.signer)
          .deposit(
            100,
            dp.outputCommitments,
            encodeDepositProof(
              dp.encryptionNonce,
              dp.ecdhPublicKey,
              dp.encRecv!,
              dp.encArb!,
              dp.encEnf,
              dp.encodedProof,
            ),
            "0x",
          ),
      )
        .to.be.revertedWithCustomError(zeto, "InsufficientDepositCredited")
        .withArgs(100n, 99n);

      // No commitment was created from the short collateral.
      for (const c of dp.outputCommitments) {
        if (c !== 0n) expect(await zeto.spent(c)).to.equal(0n); // UTXOStatus.UNKNOWN
      }
    });

    it("accepts a deposit from a zero-fee token and credits the full amount", async function () {
      this.timeout(600000);
      await (await feeToken.setFeeBps(0)).wait();
      const { dp, utxos } = await depositProofFor(100);
      await (
        await feeToken.connect(Alice.signer).approve(zeto.target, 100)
      ).wait();

      const poolBefore = await feeToken.balanceOf(zeto.target);
      await (
        await zeto
          .connect(Alice.signer)
          .deposit(
            100,
            dp.outputCommitments,
            encodeDepositProof(
              dp.encryptionNonce,
              dp.ecdhPublicKey,
              dp.encRecv!,
              dp.encArb!,
              dp.encEnf,
              dp.encodedProof,
            ),
            "0x",
          )
      ).wait();
      expect((await feeToken.balanceOf(zeto.target)) - poolBefore).to.equal(
        100n,
      );
      await trackUtxos([smt], ...utxos);
    });

    it("accepts a deposit of an exact odd amount", async function () {
      this.timeout(600000);
      await (await feeToken.setFeeBps(0)).wait();
      const { dp, utxos } = await depositProofFor(64);
      await (
        await feeToken.connect(Alice.signer).approve(zeto.target, 64)
      ).wait();

      const poolBefore = await feeToken.balanceOf(zeto.target);
      await (
        await zeto
          .connect(Alice.signer)
          .deposit(
            64,
            dp.outputCommitments,
            encodeDepositProof(
              dp.encryptionNonce,
              dp.ecdhPublicKey,
              dp.encRecv!,
              dp.encArb!,
              dp.encEnf,
              dp.encodedProof,
            ),
            "0x",
          )
      ).wait();
      expect((await feeToken.balanceOf(zeto.target)) - poolBefore).to.equal(
        64n,
      );
      await trackUtxos([smt], ...utxos);
    });

    it("rejects a deposit whose transferFrom reports failure without reverting", async function () {
      this.timeout(600000);
      await (await feeToken.setFeeBps(0)).wait();
      await (await feeToken.setFailTransferFrom(true)).wait();
      const { dp } = await depositProofFor(100);
      await (
        await feeToken.connect(Alice.signer).approve(zeto.target, 100)
      ).wait();

      await expect(
        zeto
          .connect(Alice.signer)
          .deposit(
            100,
            dp.outputCommitments,
            encodeDepositProof(
              dp.encryptionNonce,
              dp.ecdhPublicKey,
              dp.encRecv!,
              dp.encArb!,
              dp.encEnf,
              dp.encodedProof,
            ),
            "0x",
          ),
      ).to.be.revertedWithCustomError(
        await ethers.getContractAt("Zeto_AENKNRETransferFacet", zeto.target),
        "SafeERC20FailedOperation",
      );

      await (await feeToken.setFailTransferFrom(false)).wait();
    });
  });

  // ── withdrawal recipient binding (RC-06 / report ID 6) ──

  describe("withdraw recipient binding", function () {
    before(async function () {
      if ((await zeto.getEnforcer())[0] === 0n) {
        await (
          await zeto.connect(deployer).setEnforcer(Enforcer.babyJubPublicKey)
        ).wait();
      }
      if ((await zeto.getArbiterKeyId()) === 0n) {
        await (
          await zeto.connect(deployer).setArbiter(Arbiter.babyJubPublicKey)
        ).wait();
      }
      const activeRoot = (
        await complianceProof(smtCompAllActive, Alice.babyJubPublicKey)
      ).root;
      await (
        await zeto.connect(deployer).setComplianceRoot(activeRoot, "0x")
      ).wait();
      await (await erc20.connect(deployer).mint(zeto.target, 10000)).wait();
    });

    it("another submitter cannot front-run a pending withdrawal", async function () {
      this.timeout(600000);
      const u1 = newUTXO(35, Alice);
      const u2 = newUTXO(65, Alice);
      await mintAndTrack([u1, u2]);

      // Alice builds a withdrawal for herself, as she would before broadcasting.
      const ephKp = genKeypair();
      const wp = await proveWithdraw(
        Alice,
        [u1, u2],
        ZERO_UTXO,
        100,
        smtAlice,
        smtKyc,
        smtCompAllActive,
        Arbiter,
        Enforcer,
        ephKp,
      );
      const payload = [
        100,
        wp.ownerNullifiers!,
        wp.changeCommitment,
        encodeWithdrawProof(
          wp.utxosRoot!,
          wp.enfNullifiers,
          wp.encryptionNonce,
          wp.ecdhPublicKey,
          wp.encArb!,
          wp.encEnf,
          wp.encodedProof,
        ),
        "0x",
      ];

      // Bob copies the pending payload verbatim and submits it first. The
      // contract injects his address as the recipient signal, which no longer
      // matches the one Alice bound, so the proof does not verify.
      const bobBefore = await erc20.balanceOf(Bob.ethAddress);
      await expect(
        zeto.connect(Bob.signer).withdraw(...(payload as any)),
      ).to.be.revertedWithCustomError(zeto, "InvalidProof");
      expect(await erc20.balanceOf(Bob.ethAddress)).to.equal(bobBefore);

      // The notes are untouched, so Alice's own withdrawal still goes through.
      for (const n of wp.ownerNullifiers!) {
        if (n !== 0n) expect(await zeto.ownerNullifierSpent(n)).to.be.false;
      }
      const aliceBefore = await erc20.balanceOf(Alice.ethAddress);
      await (
        await zeto.connect(Alice.signer).withdraw(...(payload as any))
      ).wait();
      expect((await erc20.balanceOf(Alice.ethAddress)) - aliceBefore).to.equal(
        100n,
      );
    });

    it("a withdrawal bound to a third party is only usable by that party", async function () {
      this.timeout(600000);
      const u1 = newUTXO(20, Alice);
      const u2 = newUTXO(30, Alice);
      await mintAndTrack([u1, u2]);

      // Alice binds the payout to Bob; only Bob may execute it.
      const wp = await proveWithdraw(
        Alice,
        [u1, u2],
        ZERO_UTXO,
        50,
        smtAlice,
        smtKyc,
        smtCompAllActive,
        Arbiter,
        Enforcer,
        genKeypair(),
        Bob.ethAddress,
      );
      const payload = [
        50,
        wp.ownerNullifiers!,
        wp.changeCommitment,
        encodeWithdrawProof(
          wp.utxosRoot!,
          wp.enfNullifiers,
          wp.encryptionNonce,
          wp.ecdhPublicKey,
          wp.encArb!,
          wp.encEnf,
          wp.encodedProof,
        ),
        "0x",
      ];

      await expect(
        zeto.connect(Alice.signer).withdraw(...(payload as any)),
      ).to.be.revertedWithCustomError(zeto, "InvalidProof");

      const bobBefore = await erc20.balanceOf(Bob.ethAddress);
      await (
        await zeto.connect(Bob.signer).withdraw(...(payload as any))
      ).wait();
      expect((await erc20.balanceOf(Bob.ethAddress)) - bobBefore).to.equal(50n);
    });
  });

  // ── inherited lock paths (invariant 3 / report ID 4) ──

  describe("inherited lock paths", function () {
    // The enforced token does not support locking. There is no locked-transfer
    // circuit, so the deployment configures the lock verifier to the zero
    // address; under the lock-identifier model `createLock` never reaches that
    // verifier, and the inherited hook would instead build a seven-signal
    // public-input vector for a verifier that expects fifty-eight. An
    // accidental refusal is not a security property, so both {ZetoLockable}
    // hooks are overridden to revert {LockingNotSupported} and no lock can
    // ever come into existence. These tests pin every entry point of the
    // lifecycle, so a future change to the inherited chain cannot quietly open
    // a route that bypasses the AENKNR-E proof, the KYC and compliance checks,
    // and the dual-nullifier state transition.
    const CREATE_LOCK_ARGS =
      "tuple(bytes32 txId,uint256[] inputs,uint256[] outputs," +
      "uint256[] lockedOutputs,bytes proof)";
    const SPEND_LOCK_ARGS =
      "tuple(bytes32 txId,uint256[] lockedOutputs,uint256[] outputs," +
      "bytes proof,bytes data)";
    const TX_ID = ethers.zeroPadValue("0x01", 32);
    const NO_LOCK = ethers.zeroPadValue("0x02", 32);

    const dummyProof = new AbiCoder().encode(
      [
        "uint256",
        "uint256[]",
        "uint256",
        "uint256[2]",
        "uint256[]",
        "uint256[]",
        "uint256[]",
        PROOF_TUPLE,
      ],
      [
        0,
        [0, 0],
        0,
        [0, 0],
        [0],
        [0],
        [0],
        {
          pA: [0, 0],
          pB: [
            [0, 0],
            [0, 0],
          ],
          pC: [0, 0],
        },
      ],
    );

    const createArgs = new AbiCoder().encode(
      [CREATE_LOCK_ARGS],
      [[TX_ID, [1], [2], [3], dummyProof]],
    );
    const spendArgs = new AbiCoder().encode(
      [SPEND_LOCK_ARGS],
      [[TX_ID, [3], [2], dummyProof, "0x"]],
    );
    const txIdArgs = new AbiCoder().encode(["tuple(bytes32 txId)"], [[TX_ID]]);

    it("createLock reverts because the enforced token has no lock circuit", async function () {
      await expect(
        zeto
          .connect(Alice.signer)
          .createLock(createArgs, ethers.ZeroHash, ethers.ZeroHash, "0x"),
      ).to.be.revertedWithCustomError(zeto, "LockingNotSupported");
    });

    it("spendLock reverts because no lock can exist to spend", async function () {
      await expect(
        zeto.connect(Alice.signer).spendLock(NO_LOCK, spendArgs, "0x"),
      )
        .to.be.revertedWithCustomError(zeto, "LockNotActive")
        .withArgs(NO_LOCK);
    });

    it("cancelLock reverts because no lock can exist to cancel", async function () {
      await expect(
        zeto.connect(Alice.signer).cancelLock(NO_LOCK, spendArgs, "0x"),
      )
        .to.be.revertedWithCustomError(zeto, "LockNotActive")
        .withArgs(NO_LOCK);
    });

    it("updateLock reverts because no lock can exist to update", async function () {
      await expect(
        zeto
          .connect(Alice.signer)
          .updateLock(
            NO_LOCK,
            txIdArgs,
            ethers.ZeroHash,
            ethers.ZeroHash,
            "0x",
          ),
      )
        .to.be.revertedWithCustomError(zeto, "LockNotActive")
        .withArgs(NO_LOCK);
    });

    it("delegateLock reverts because nothing can ever be locked", async function () {
      await expect(
        zeto
          .connect(Alice.signer)
          .delegateLock(NO_LOCK, txIdArgs, Bob.ethAddress, "0x"),
      )
        .to.be.revertedWithCustomError(zeto, "LockNotActive")
        .withArgs(NO_LOCK);
    });

    it("the locked-transfer hook is unreachable from outside", async function () {
      // `zetoLockTransferLocked` is `onlySelf`, so an external caller is
      // rejected before the hook body runs; the body itself reverts
      // {LockingNotSupported}. Reaching it needs the library's self-call,
      // which only `spendLock` on an active lock ever makes.
      await expect(
        zeto
          .connect(Alice.signer)
          .zetoLockTransferLocked(NO_LOCK, [1], [2], [3], dummyProof, "0x"),
      )
        .to.be.revertedWithCustomError(zeto, "NotSelf")
        .withArgs(Alice.ethAddress);
    });

    it("no lock path leaves any UTXO locked", async function () {
      expect((await zeto.locked(1))[0]).to.be.false;
      expect((await zeto.locked(2))[0]).to.be.false;
      expect((await zeto.locked(3))[0]).to.be.false;
      expect(await zeto.isLockActive(NO_LOCK)).to.be.false;
    });
  });
});
