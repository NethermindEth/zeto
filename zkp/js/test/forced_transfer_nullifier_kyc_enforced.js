// Copyright © 2025 Kaleido, Inc.
//
// SPDX-License-Identifier: Apache-2.0
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

const { expect } = require("chai");
const { witnessIndex } = require("./lib/aenknre-signal-layout.js");
const { newRejectionTracker } = require("./util/witness-errors.js");
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
  enforcementNullifier,
  ENFORCEMENT_NULLIFIER_DOMAIN_TAG,
} = require("../index.js");

const SMT_HEIGHT_UTXO = 32;
const SMT_HEIGHT_IDENTITY = 20;
const SMT_HEIGHT_COMPLIANCE = 20;
const poseidonHash = Poseidon.poseidon4;
const poseidonHash2 = Poseidon.poseidon2;
const poseidonHash3 = Poseidon.poseidon3;

const STATUS_ACTIVE = 1n;
const STATUS_FROZEN = 2n;

// The 1-based witness index of a public signal of this circuit.
const pi = (signal) =>
  witnessIndex("forced_transfer_nullifier_kyc_enforced", signal);

describe("forced_transfer_nullifier_kyc_enforced circuit tests", () => {
  let circuit;
  // circom_tester accumulates every failed assert into one error string for the
  // life of the process, so only the freshly appended stack describes the failure
  // under test. See test/util/witness-errors.js.
  const rejects = newRejectionTracker();
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
      seizedOwner = Alice,
      inputOwners = null,
      outputRecipients = [Bob, Bob],
      inputValues = [32, 40],
      outputValues = [20, 52],
    } = {},
  ) {
    inputOwners = inputOwners || [seizedOwner, seizedOwner];
    const inputSalts = [newSalt(), newSalt()];
    const inputCommitments = inputValues.map((v, i) =>
      poseidonHash([BigInt(v), inputSalts[i], ...inputOwners[i].pubKey]),
    );

    for (const c of inputCommitments) await smtUtxo.add(c, c);
    const utxoProofs = [];
    for (const c of inputCommitments) {
      utxoProofs.push(await smtUtxo.generateCircomVerifierProof(c, ZERO_HASH));
    }

    // enforcement nullifiers: ECDH(enforcerPriv, seizedOwnerPub=Alice)
    const enforcementNullifiers = inputCommitments.map((c) =>
      enforcementNullifier(Enforcer.privKey, seizedOwner.pubKey, c),
    );

    const outputSalts = [newSalt(), newSalt()];
    const outputCommitments = outputValues.map((v, i) =>
      poseidonHash([BigInt(v), outputSalts[i], ...outputRecipients[i].pubKey]),
    );

    const encryptionNonce = newEncryptionNonce();
    const ephemeralKeypair = genKeypair();

    // KYC proofs: [seizedOwner, output1Owner, output2Owner]
    const kycActors = [seizedOwner, ...outputRecipients];
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
    const compActors = [seizedOwner, ...outputRecipients];
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
      seizedOwnerPublicKey: seizedOwner.pubKey,
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
    // calculateWitness evaluates the asserts; checkConstraints evaluates the
    // R1CS system, which is where an under-constrained signal shows up.
    await circuit.checkConstraints(witness);

    // Public-signal indices come from test/lib/aenknre-signal-layout.js, which
    // public-signal-layout.js checks against the compiled .sym. Circom orders
    // public signals by declaration order in the template, not by the order of
    // the `{ public [...] }` list, so they cannot be re-derived by hand here.

    expect(witness[pi("enforcementNullifiers[0]")]).to.equal(
      BigInt(enforcementNullifiers[0]),
    );
    expect(witness[pi("enforcementNullifiers[1]")]).to.equal(
      BigInt(enforcementNullifiers[1]),
    );
    expect(witness[pi("outputCommitments[0]")]).to.equal(
      BigInt(outputCommitments[0]),
    );
    expect(witness[pi("outputCommitments[1]")]).to.equal(
      BigInt(outputCommitments[1]),
    );
    expect(witness[pi("utxosRoot")]).to.equal(circuitInputs.utxosRoot);
    expect(witness[pi("identitiesRoot")]).to.equal(
      circuitInputs.identitiesRoot,
    );
    expect(witness[pi("complianceRoot")]).to.equal(
      circuitInputs.complianceRoot,
    );
    expect(witness[pi("enabledInputs[0]")]).to.equal(1n);
    expect(witness[pi("enabledInputs[1]")]).to.equal(1n);
    expect(witness[pi("enforcerPublicKey[0]")]).to.equal(Enforcer.pubKey[0]);
    expect(witness[pi("enforcerPublicKey[1]")]).to.equal(Enforcer.pubKey[1]);
    expect(witness[pi("encryptionNonce")]).to.equal(BigInt(encryptionNonce));
    expect(witness[pi("arbiterPublicKey[0]")]).to.equal(Arbiter.pubKey[0]);
    expect(witness[pi("arbiterPublicKey[1]")]).to.equal(Arbiter.pubKey[1]);

    // inputCommitments must not appear in public signals, which is what keeps
    // the seized notes private
    const publicSignals = witness.slice(1, 57);
    expect(publicSignals).to.not.include(BigInt(inputCommitments[0]));
    expect(publicSignals).to.not.include(BigInt(inputCommitments[1]));

    // Bob decrypts output 1.
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

    // The arbiter decrypts the 14-element authority plaintext, in which
    // senderPub is the seized owner.
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

    // The enforcer recovers the same plaintext through a different ECDH key.
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

    await rejects(circuit, circuitInputs);
  });

  it("should fail when seized owner has ACTIVE status (FROZEN required)", async function () {
    this.timeout(60000);

    // smtCompAliceActive has Alice as ACTIVE; ComplianceStatus(..., 2) expects FROZEN
    const { circuitInputs } = await buildInputs(smtCompAliceActive);

    await rejects(circuit, circuitInputs);
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

    await rejects(circuit, circuitInputs);
  });

  it("should fail when enforcement nullifier is tampered", async function () {
    this.timeout(60000);

    const { circuitInputs } = await buildInputs(smtCompMain);

    // flip a bit in the first enforcement nullifier
    circuitInputs.enforcementNullifiers = [
      circuitInputs.enforcementNullifiers[0] + 1n,
      circuitInputs.enforcementNullifiers[1],
    ];

    await rejects(circuit, circuitInputs);
  });

  it("should succeed with change output back to same FROZEN owner (isChangeBack mux)", async function () {
    this.timeout(60000);

    // output1 → Bob (ACTIVE, isChangeBack=0), output2 → Alice (FROZEN, isChangeBack=1)
    const { circuitInputs, outputSalts, encryptionNonce, ephemeralKeypair } =
      await buildInputs(smtCompMain, {
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

    expect(witness[pi("outputCommitments[0]")]).to.equal(
      BigInt(outputCommitments[0]),
    );
    expect(witness[pi("outputCommitments[1]")]).to.equal(
      BigInt(outputCommitments[1]),
    );
  });

  it("should fail when output goes to FROZEN party that is NOT the seized owner", async function () {
    this.timeout(60000);

    // output → Dave (FROZEN but not Alice); isChangeBack=0 → expects ACTIVE → mismatch
    const { circuitInputs } = await buildInputs(smtCompWithDave, {
      outputRecipients: [Dave, Dave],
    });

    await rejects(circuit, circuitInputs);
  });

  it("should fail when the enforcement nullifiers are suppressed to zero", async function () {
    this.timeout(60000);

    // The seizure consumes both of the frozen owner's real notes but
    // publishes no enforcement tag, so nothing on chain records that they were
    // spent and the same notes stay available to the owner.
    const { circuitInputs } = await buildInputs(smtCompMain);
    circuitInputs.enforcementNullifiers = [0, 0];

    await rejects(circuit, circuitInputs);
  });

  it("should fail when a disabled seized slot carries value", async function () {
    this.timeout(60000);

    // A phantom seized note. Slot 1 is off at every zero-keyed gate but
    // its value still counts in CheckSum, so the enforcer seizes 10^12 out of a
    // single 32-unit note.
    const { circuitInputs } = await buildInputs(smtCompMain);
    const phantom = 1000000000000;
    circuitInputs.inputCommitments[1] = 0n;
    circuitInputs.enforcementNullifiers[1] = 0n;
    circuitInputs.enabledInputs = [1, 0];
    circuitInputs.utxosMerkleProof[1] = Array(SMT_HEIGHT_UTXO).fill(0n);
    circuitInputs.inputValues = [32, phantom];
    circuitInputs.outputValues = [20, 32 + phantom - 20];
    circuitInputs.outputCommitments = circuitInputs.outputValues.map((v, i) =>
      poseidonHash([
        BigInt(v),
        circuitInputs.outputSalts[i],
        ...circuitInputs.outputOwnerPublicKeys[i],
      ]),
    );

    await rejects(circuit, circuitInputs);
  });

  it("should fail when the seized owner key has x == 0", async function () {
    this.timeout(60000);

    // The seized owner key is the ECDH counterparty for every enforcement
    // tag and the identity the compliance tree must show as FROZEN. With x == 0
    // ComplianceStatus skips the FROZEN check entirely, so any set of notes can
    // be seized regardless of their owner's status.
    //
    // The tags here are derived the way the circuit derives them rather than via
    // genEcdhSharedKey: EscalarMulAny replaces an x == 0 point with the Base8
    // generator, so the "shared secret" collapses to enforcerPrivateKey * Base8,
    // which is the enforcer's own public key. That the tags can be computed from
    // public data alone is N-1.
    const seizedOwner = { pubKey: [0n, 1n] };
    const { circuitInputs } = await buildInputs(smtCompMain, { seizedOwner });
    const publiclyDerivableK0 = poseidonHash2(Enforcer.pubKey);
    circuitInputs.enforcementNullifiers = circuitInputs.inputCommitments.map(
      (c) =>
        poseidonHash3([
          c,
          publiclyDerivableK0,
          ENFORCEMENT_NULLIFIER_DOMAIN_TAG,
        ]),
    );

    await rejects(circuit, circuitInputs);
  });

  it("should fail when the ephemeral key is zero", async function () {
    this.timeout(60000);

    // With a zero scalar every ECDH output is the curve identity,
    // so the "shared secret" is a constant any observer can compute. Every
    // ciphertext in the transaction — receiver, arbiter and enforcer — becomes
    // world-readable, and the published ephemeral public key is the identity.
    const { circuitInputs } = await buildInputs(smtCompMain);
    circuitInputs.ecdhPrivateKey = 0;

    await rejects(circuit, circuitInputs);
  });

  it("should fail when the same note is seized in both input slots", async function () {
    this.timeout(60000);

    // Transfer and withdraw get duplicate-input rejection for free from
    // their owner nullifiers, which the contract refuses to spend twice. This
    // path publishes only enforcement tags, and two copies of one note produce
    // one tag that the contract sees as a single unspent entry. CheckSum then
    // counts the note's value twice, so a 32-unit note yields a 64-unit seizure.
    const { circuitInputs } = await buildInputs(smtCompMain);
    circuitInputs.inputCommitments[1] = circuitInputs.inputCommitments[0];
    circuitInputs.inputValues = [32, 32];
    circuitInputs.inputSalts[1] = circuitInputs.inputSalts[0];
    circuitInputs.enforcementNullifiers[1] =
      circuitInputs.enforcementNullifiers[0];
    circuitInputs.utxosMerkleProof[1] = circuitInputs.utxosMerkleProof[0];
    circuitInputs.outputValues = [20, 44];
    circuitInputs.outputCommitments = circuitInputs.outputValues.map((v, i) =>
      poseidonHash([
        BigInt(v),
        circuitInputs.outputSalts[i],
        ...circuitInputs.outputOwnerPublicKeys[i],
      ]),
    );

    await rejects(circuit, circuitInputs);
  });

  it("should succeed when one slot is disabled and the other is live", async function () {
    this.timeout(60000);

    // The distinctness check must not reject a legitimate single-note seizure:
    // two disabled slots both carry a zero commitment, which is not a duplicate.
    const { circuitInputs } = await buildInputs(smtCompMain);
    circuitInputs.inputCommitments[1] = 0n;
    circuitInputs.enforcementNullifiers[1] = 0n;
    circuitInputs.enabledInputs = [1, 0];
    circuitInputs.inputValues = [32, 0];
    circuitInputs.utxosMerkleProof[1] = Array(SMT_HEIGHT_UTXO).fill(0n);
    circuitInputs.outputValues = [20, 12];
    circuitInputs.outputCommitments = circuitInputs.outputValues.map((v, i) =>
      poseidonHash([
        BigInt(v),
        circuitInputs.outputSalts[i],
        ...circuitInputs.outputOwnerPublicKeys[i],
      ]),
    );

    const witness = await circuit.calculateWitness(circuitInputs, true);
    await circuit.checkConstraints(witness);
  });

  it("should fail when the seizure output recipient is not KYC-registered", async function () {
    this.timeout(60000);

    // Negative KYC coverage on the seizure path: the enforcer may not redirect
    // seized value to an identity absent from the identities tree.
    const stranger = genKeypair();
    const { circuitInputs } = await buildInputs(smtCompMain);
    circuitInputs.outputOwnerPublicKeys[0] = stranger.pubKey;
    circuitInputs.outputCommitments[0] = poseidonHash([
      BigInt(circuitInputs.outputValues[0]),
      circuitInputs.outputSalts[0],
      ...stranger.pubKey,
    ]);

    await rejects(circuit, circuitInputs);
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

    await rejects(circuit, circuitInputs);
  });

  it("should fail when every output slot is disabled but value is still seized", async function () {
    this.timeout(60000);

    // Both output commitments are zero, so CheckHashes skips both slots
    // and no note is minted — yet the seized 72 units still balance CheckSum.
    // The seizure destroys the frozen owner's value outright.
    const { circuitInputs } = await buildInputs(smtCompMain);
    circuitInputs.outputCommitments = [0n, 0n];

    await rejects(circuit, circuitInputs);
  });

  it("should succeed with a disabled output slot (commitment == 0)", async function () {
    this.timeout(60000);

    const { circuitInputs } = await buildInputs(smtCompMain, {
      outputValues: [72, 0],
    });

    // disabled output slot: the zero commitment overrides the helper's computed
    // hash, and the slot's owner key becomes inert — the curve check is fed the
    // Base8 padding instead, and the KYC/compliance key is zeroed
    circuitInputs.outputCommitments[1] = 0n;
    circuitInputs.outputSalts[1] = 0n;
    circuitInputs.identitiesMerkleProof[2] =
      Array(SMT_HEIGHT_IDENTITY).fill(0n);
    circuitInputs.complianceMerkleProof[2] = Array(SMT_HEIGHT_COMPLIANCE).fill(
      0n,
    );

    const witness = await circuit.calculateWitness(circuitInputs, true);
    expect(witness[pi("outputCommitments[1]")]).to.equal(0n);
  });
});
