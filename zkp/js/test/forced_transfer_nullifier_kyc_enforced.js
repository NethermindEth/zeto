const { expect } = require("chai");
const { join } = require("path");
const { wasm: wasm_tester } = require("circom_tester");
const {
  genKeypair,
  genEcdhSharedKey,
  formatPrivKeyForBabyJub,
  stringifyBigInts,
} = require("maci-crypto");
const {
  Merkletree,
  InMemoryDB,
  str2Bytes,
  ZERO_HASH,
} = require("@iden3/js-merkletree");
const {
  Poseidon,
  newSalt,
  newEncryptionNonce,
  poseidonDecrypt,
} = require("../index.js");

const SMT_HEIGHT_UTXO = 64;
const SMT_HEIGHT_IDENTITY = 10;
const SMT_HEIGHT_COMPLIANCE = 64;
const poseidonHash = Poseidon.poseidon4;
const poseidonHash2 = Poseidon.poseidon2;
const poseidonHash3 = Poseidon.poseidon3;

const STATUS_ACTIVE = 1n;
const STATUS_FROZEN = 2n;

const ENF_DOMAIN_TAG =
  21455947405572920533869930548514094044543253524099188107381343679564123236615n;

function computeEnforcementNullifier(
  ecdhPrivKey,
  counterpartyPubKey,
  commitment,
) {
  const shared = genEcdhSharedKey(ecdhPrivKey, counterpartyPubKey);
  const k0 = poseidonHash2([shared[0], shared[1]]);
  return poseidonHash3([commitment, k0, ENF_DOMAIN_TAG]);
}

describe("forced_transfer_nullifier_kyc_enforced circuit tests", () => {
  let circuit;
  let smtUtxo, smtKYC;
  let smtCompMain, smtCompAliceActive, smtCompWithCharlie, smtCompWithDave;

  // Alice = seized FROZEN owner, Bob = ACTIVE recipient,
  // Charlie = ACTIVE third party, Dave = FROZEN third party (not Alice)
  const Alice = {};
  const Bob = {};
  const Charlie = {};
  const Dave = {};
  const Enforcer = {};
  const Arbiter = {};
  let enforcerFormattedPrivKey;

  before(async function () {
    this.timeout(60000);

    circuit = await wasm_tester(
      join(
        __dirname,
        "../../circuits/forced_transfer_nullifier_kyc_enforced.circom",
      ),
    );

    for (const actor of [Alice, Bob, Charlie, Dave, Enforcer, Arbiter]) {
      const kp = genKeypair();
      actor.privKey = kp.privKey;
      actor.pubKey = kp.pubKey;
    }
    enforcerFormattedPrivKey = formatPrivKeyForBabyJub(Enforcer.privKey);

    smtUtxo = new Merkletree(
      new InMemoryDB(str2Bytes("utxo")),
      true,
      SMT_HEIGHT_UTXO,
    );

    smtKYC = new Merkletree(
      new InMemoryDB(str2Bytes("kyc")),
      true,
      SMT_HEIGHT_IDENTITY,
    );
    for (const actor of [Alice, Bob, Charlie, Dave]) {
      const id = poseidonHash2(actor.pubKey);
      await smtKYC.add(id, id);
    }

    async function buildComplianceSmt(tag, entries) {
      const smt = new Merkletree(
        new InMemoryDB(str2Bytes(tag)),
        true,
        SMT_HEIGHT_COMPLIANCE,
      );
      for (const [actor, status] of entries) {
        await smt.add(
          poseidonHash2(actor.pubKey),
          poseidonHash3([...actor.pubKey, status]),
        );
      }
      return smt;
    }

    smtCompMain = await buildComplianceSmt("comp-main", [
      [Alice, STATUS_FROZEN],
      [Bob, STATUS_ACTIVE],
    ]);
    smtCompAliceActive = await buildComplianceSmt("comp-alice-active", [
      [Alice, STATUS_ACTIVE],
      [Bob, STATUS_ACTIVE],
    ]);
    smtCompWithCharlie = await buildComplianceSmt("comp-charlie", [
      [Alice, STATUS_FROZEN],
      [Charlie, STATUS_ACTIVE],
    ]);
    smtCompWithDave = await buildComplianceSmt("comp-dave", [
      [Alice, STATUS_FROZEN],
      [Dave, STATUS_FROZEN],
    ]);
  });

  // Build circuit inputs for a 2-in / 2-out forced transfer.
  // Default: both inputs owned by Alice (seized FROZEN owner), both outputs to Bob (ACTIVE).
  async function buildInputs(
    complianceSmt,
    {
      inputOwners = [Alice, Alice],
      outputRecipients = [Bob, Bob],
      inputValues = [32, 40],
      outputValues = [20, 52],
    } = {},
  ) {
    const inputSalts = [newSalt(), newSalt()];
    const inputCommitments = inputValues.map((v, i) =>
      poseidonHash([BigInt(v), inputSalts[i], ...inputOwners[i].pubKey]),
    );

    for (const c of inputCommitments) await smtUtxo.add(c, c);
    const utxoProofs = [];
    for (const c of inputCommitments) {
      utxoProofs.push(
        await smtUtxo.generateCircomVerifierProof(c, ZERO_HASH),
      );
    }

    // enforcement nullifiers: ECDH(enforcerPriv, seizedOwnerPub=Alice)
    const enforcementNullifiers = inputCommitments.map((c) =>
      computeEnforcementNullifier(Enforcer.privKey, Alice.pubKey, c),
    );

    const outputSalts = [newSalt(), newSalt()];
    const outputCommitments = outputValues.map((v, i) =>
      poseidonHash([BigInt(v), outputSalts[i], ...outputRecipients[i].pubKey]),
    );

    const encryptionNonce = newEncryptionNonce();
    const ephemeralKeypair = genKeypair();

    // KYC proofs: [seizedOwner, output1Owner, output2Owner]
    const kycActors = [Alice, ...outputRecipients];
    const kycProofs = [];
    for (const a of kycActors) {
      kycProofs.push(
        await smtKYC.generateCircomVerifierProof(
          poseidonHash2(a.pubKey),
          ZERO_HASH,
        ),
      );
    }

    // compliance proofs: [seizedOwner, output1Owner, output2Owner]
    const compActors = [Alice, ...outputRecipients];
    const compProofs = [];
    for (const a of compActors) {
      compProofs.push(
        await complianceSmt.generateCircomVerifierProof(
          poseidonHash2(a.pubKey),
          ZERO_HASH,
        ),
      );
    }

    const circuitInputs = {
      enforcementNullifiers,
      outputCommitments,
      utxosRoot: utxoProofs[0].root.bigInt(),
      identitiesRoot: kycProofs[0].root.bigInt(),
      complianceRoot: compProofs[0].root.bigInt(),
      enabledInputs: [1, 1],
      enforcerPublicKey: Enforcer.pubKey,
      arbiterPublicKey: Arbiter.pubKey,
      inputCommitments,
      inputValues,
      inputSalts,
      seizedOwnerPublicKey: Alice.pubKey,
      enforcerPrivateKey: enforcerFormattedPrivKey,
      utxosMerkleProof: utxoProofs.map((p) =>
        p.siblings.map((s) => s.bigInt()),
      ),
      identitiesMerkleProof: kycProofs.map((p) =>
        p.siblings.map((s) => s.bigInt()),
      ),
      complianceMerkleProof: compProofs.map((p) =>
        p.siblings.map((s) => s.bigInt()),
      ),
      outputValues,
      outputSalts,
      outputOwnerPublicKeys: outputRecipients.map((r) => r.pubKey),
      ...stringifyBigInts({
        encryptionNonce,
        ecdhPrivateKey: formatPrivKeyForBabyJub(ephemeralKeypair.privKey),
      }),
    };

    return {
      circuitInputs,
      inputSalts,
      outputSalts,
      enforcementNullifiers,
      inputCommitments,
      outputCommitments,
      encryptionNonce,
      ephemeralKeypair,
    };
  }

  it("should succeed for happy-path seizure with two enabled inputs, verify signal ordering and decryption", async function () {
    this.timeout(60000);

    const {
      circuitInputs,
      inputSalts,
      outputSalts,
      enforcementNullifiers,
      inputCommitments,
      outputCommitments,
      encryptionNonce,
      ephemeralKeypair,
    } = await buildInputs(smtCompMain);

    const witness = await circuit.calculateWitness(circuitInputs, true);

    // ── public signal ordering snapshot for Solidity integration ──
    //   output signals (automatically public, appear first):
    //     [1-2]    ecdhPublicKey[2]
    //     [3-10]   encryptedValuesForReceiver[2][4]
    //     [11-26]  encryptedValuesForArbiter[16]
    //     [27-42]  encryptedValuesForEnforcer[16]
    //   public input signals (in { public [] } declaration order):
    //     [43-44]  enforcementNullifiers[2]
    //     [45-46]  outputCommitments[2]
    //     [47]     utxosRoot
    //     [48]     identitiesRoot
    //     [49]     complianceRoot
    //     [50-51]  enabledInputs[2]
    //     [52-53]  enforcerPublicKey[2]
    //     [54]     encryptionNonce
    //     [55-56]  arbiterPublicKey[2]

    expect(witness[43]).to.equal(BigInt(enforcementNullifiers[0]));
    expect(witness[44]).to.equal(BigInt(enforcementNullifiers[1]));
    expect(witness[45]).to.equal(BigInt(outputCommitments[0]));
    expect(witness[46]).to.equal(BigInt(outputCommitments[1]));
    expect(witness[47]).to.equal(circuitInputs.utxosRoot);
    expect(witness[48]).to.equal(circuitInputs.identitiesRoot);
    expect(witness[49]).to.equal(circuitInputs.complianceRoot);
    expect(witness[50]).to.equal(1n);
    expect(witness[51]).to.equal(1n);
    expect(witness[52]).to.equal(Enforcer.pubKey[0]);
    expect(witness[53]).to.equal(Enforcer.pubKey[1]);
    expect(witness[54]).to.equal(BigInt(encryptionNonce));
    expect(witness[55]).to.equal(Arbiter.pubKey[0]);
    expect(witness[56]).to.equal(Arbiter.pubKey[1]);

    // inputCommitments must NOT appear in public signals (privacy requirement)
    const publicSignals = witness.slice(1, 57);
    expect(publicSignals).to.not.include(BigInt(inputCommitments[0]));
    expect(publicSignals).to.not.include(BigInt(inputCommitments[1]));

    // ── receiver decryption ──
    // Bob decrypts output 1
    const bobKey = genEcdhSharedKey(Bob.privKey, ephemeralKeypair.pubKey);
    const pt1 = poseidonDecrypt(
      witness.slice(3, 7),
      bobKey,
      encryptionNonce,
      2,
    );
    expect(pt1).to.deep.equal([
      BigInt(circuitInputs.outputValues[0]),
      outputSalts[0],
    ]);

    // Bob decrypts output 2 (both outputs go to Bob in happy path)
    const pt2 = poseidonDecrypt(
      witness.slice(7, 11),
      bobKey,
      encryptionNonce,
      2,
    );
    expect(pt2).to.deep.equal([
      BigInt(circuitInputs.outputValues[1]),
      outputSalts[1],
    ]);

    // ── arbiter decryption (14-element authority plaintext, senderPub = seized owner) ──
    const arbiterKey = genEcdhSharedKey(
      Arbiter.privKey,
      ephemeralKeypair.pubKey,
    );
    const arbiterPT = poseidonDecrypt(
      witness.slice(11, 27),
      arbiterKey,
      encryptionNonce,
      14,
    );
    expect(arbiterPT).to.deep.equal([
      Alice.pubKey[0], // senderPub = seizedOwnerPublicKey
      Alice.pubKey[1],
      BigInt(circuitInputs.inputValues[0]),
      inputSalts[0],
      BigInt(circuitInputs.inputValues[1]),
      inputSalts[1],
      Bob.pubKey[0], // output 1 owner
      Bob.pubKey[1],
      Bob.pubKey[0], // output 2 owner
      Bob.pubKey[1],
      BigInt(circuitInputs.outputValues[0]),
      outputSalts[0],
      BigInt(circuitInputs.outputValues[1]),
      outputSalts[1],
    ]);

    // ── enforcer decryption (same plaintext, different ECDH key) ──
    const enforcerKey = genEcdhSharedKey(
      Enforcer.privKey,
      ephemeralKeypair.pubKey,
    );
    const enforcerPT = poseidonDecrypt(
      witness.slice(27, 43),
      enforcerKey,
      encryptionNonce,
      14,
    );
    expect(enforcerPT).to.deep.equal(arbiterPT);

    // non-authority cannot decrypt either ciphertext
    expect(() =>
      poseidonDecrypt(witness.slice(11, 27), bobKey, encryptionNonce, 14),
    ).to.throw();
    expect(() =>
      poseidonDecrypt(witness.slice(27, 43), bobKey, encryptionNonce, 14),
    ).to.throw();
  });

  it("should fail when inputs belong to different owners (single-frozen-owner violated)", async function () {
    this.timeout(60000);

    // input2 is owned by Bob, but seizedOwnerPublicKey = Alice
    // → CheckHashes recomputes commitment with Alice's key → hash mismatch
    const { circuitInputs } = await buildInputs(smtCompMain, {
      inputOwners: [Alice, Bob],
    });

    let err;
    try {
      await circuit.calculateWitness(circuitInputs, true);
    } catch (e) {
      err = e;
    }
    expect(err).to.match(/CheckHashes/);
  });

  it("should fail when seized owner has ACTIVE status (FROZEN required)", async function () {
    this.timeout(60000);

    // smtCompAliceActive has Alice as ACTIVE; ComplianceStatus(..., 2) expects FROZEN
    const { circuitInputs } = await buildInputs(smtCompAliceActive);

    let err;
    try {
      await circuit.calculateWitness(circuitInputs, true);
    } catch (e) {
      err = e;
    }
    expect(err).to.match(/SMTVerifier/);
  });

  it("should fail when enforcerPrivateKey does not match enforcerPublicKey", async function () {
    this.timeout(60000);

    const { circuitInputs } = await buildInputs(smtCompMain);

    // supply a different enforcer private key; BabyPbk(wrongKey) != enforcerPublicKey
    // AND the ECDH shared secret changes so enforcement nullifiers won't match either
    const wrongEnforcer = genKeypair();
    circuitInputs.enforcerPrivateKey = formatPrivKeyForBabyJub(
      wrongEnforcer.privKey,
    );

    let err;
    try {
      await circuit.calculateWitness(circuitInputs, true);
    } catch (e) {
      err = e;
    }
    expect(err).to.exist;
  });

  it("should fail when enforcement nullifier is tampered", async function () {
    this.timeout(60000);

    const { circuitInputs } = await buildInputs(smtCompMain);

    // flip a bit in the first enforcement nullifier
    circuitInputs.enforcementNullifiers = [
      circuitInputs.enforcementNullifiers[0] + 1n,
      circuitInputs.enforcementNullifiers[1],
    ];

    let err;
    try {
      await circuit.calculateWitness(circuitInputs, true);
    } catch (e) {
      err = e;
    }
    expect(err).to.match(/CheckEnforcementNullifiers/);
  });

  it("should succeed with change output back to same FROZEN owner (isChangeBack mux)", async function () {
    this.timeout(60000);

    // output1 → Bob (ACTIVE, isChangeBack=0), output2 → Alice (FROZEN, isChangeBack=1)
    const {
      circuitInputs,
      outputSalts,
      encryptionNonce,
      ephemeralKeypair,
    } = await buildInputs(smtCompMain, {
      outputRecipients: [Bob, Alice],
    });

    const witness = await circuit.calculateWitness(circuitInputs, true);

    // arbiter decrypts and verifies senderPub = Alice, output2 owner = Alice
    const arbiterKey = genEcdhSharedKey(
      Arbiter.privKey,
      ephemeralKeypair.pubKey,
    );
    const arbiterPT = poseidonDecrypt(
      witness.slice(11, 27),
      arbiterKey,
      encryptionNonce,
      14,
    );
    // senderPub = seized owner
    expect(arbiterPT[0]).to.equal(Alice.pubKey[0]);
    expect(arbiterPT[1]).to.equal(Alice.pubKey[1]);
    // output 1 owner = Bob
    expect(arbiterPT[6]).to.equal(Bob.pubKey[0]);
    expect(arbiterPT[7]).to.equal(Bob.pubKey[1]);
    // output 2 owner = Alice (change back to frozen owner)
    expect(arbiterPT[8]).to.equal(Alice.pubKey[0]);
    expect(arbiterPT[9]).to.equal(Alice.pubKey[1]);
  });

  it("should succeed with output to ACTIVE third party (isChangeBack == 0)", async function () {
    this.timeout(60000);

    // both outputs → Charlie (ACTIVE); smtCompWithCharlie has Alice FROZEN + Charlie ACTIVE
    const { circuitInputs, outputCommitments } = await buildInputs(
      smtCompWithCharlie,
      { outputRecipients: [Charlie, Charlie] },
    );

    const witness = await circuit.calculateWitness(circuitInputs, true);

    expect(witness[45]).to.equal(BigInt(outputCommitments[0]));
    expect(witness[46]).to.equal(BigInt(outputCommitments[1]));
  });

  it("should fail when output goes to FROZEN party that is NOT the seized owner", async function () {
    this.timeout(60000);

    // output → Dave (FROZEN but not Alice); isChangeBack=0 → expects ACTIVE → mismatch
    const { circuitInputs } = await buildInputs(smtCompWithDave, {
      outputRecipients: [Dave, Dave],
    });

    let err;
    try {
      await circuit.calculateWitness(circuitInputs, true);
    } catch (e) {
      err = e;
    }
    expect(err).to.match(/SMTVerifier/);
  });

  it("should fail when value conservation is violated", async function () {
    this.timeout(60000);

    const { circuitInputs } = await buildInputs(smtCompMain);

    // tamper output values: sum 72 → 80; recompute commitments to isolate CheckSum failure
    const tamperedValues = [50, 30];
    circuitInputs.outputCommitments = tamperedValues.map((v, i) =>
      poseidonHash([
        BigInt(v),
        circuitInputs.outputSalts[i],
        ...circuitInputs.outputOwnerPublicKeys[i],
      ]),
    );
    circuitInputs.outputValues = tamperedValues;

    let err;
    try {
      await circuit.calculateWitness(circuitInputs, true);
    } catch (e) {
      err = e;
    }
    expect(err).to.match(/CheckSum/);
  });

  it("should succeed with a disabled output slot (commitment == 0)", async function () {
    this.timeout(60000);

    const { circuitInputs } = await buildInputs(smtCompMain, {
      outputValues: [72, 0],
    });

    // disabled output slot: zero commitment overrides the helper's computed hash;
    // BabyCheck still requires a valid curve point in outputOwnerPublicKeys
    circuitInputs.outputCommitments[1] = 0n;
    circuitInputs.outputSalts[1] = 0n;
    circuitInputs.identitiesMerkleProof[2] = Array(SMT_HEIGHT_IDENTITY).fill(0n);
    circuitInputs.complianceMerkleProof[2] = Array(SMT_HEIGHT_COMPLIANCE).fill(0n);

    const witness = await circuit.calculateWitness(circuitInputs, true);
    expect(witness[46]).to.equal(0n); // outputCommitments[1] == 0
  });
});