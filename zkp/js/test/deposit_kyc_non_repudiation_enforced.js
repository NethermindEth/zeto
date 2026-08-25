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
} = require("../index.js");

const SMT_HEIGHT_IDENTITY = 20;
const SMT_HEIGHT_COMPLIANCE = 20;
const poseidonHash = Poseidon.poseidon4;
const poseidonHash2 = Poseidon.poseidon2;
const poseidonHash3 = Poseidon.poseidon3;

const STATUS_ACTIVE = 1n;
const STATUS_FROZEN = 2n;

// The 1-based witness index of a public signal of this circuit.
const pi = (signal) =>
  witnessIndex("deposit_kyc_non_repudiation_enforced", signal);

describe("deposit_kyc_non_repudiation_enforced circuit tests", () => {
  let circuit;
  // circom_tester accumulates every failed assert into one error string for the
  // life of the process, so only the freshly appended stack describes the failure
  // under test. See test/util/witness-errors.js.
  const rejects = newRejectionTracker();
  let smtKYC;
  let smtComplianceAllActive, smtComplianceRecipientFrozen;

  const Alice = {};
  const Bob = {};
  const Arbiter = {};
  const Enforcer = {};

  before(async function () {
    this.timeout(60000);

    circuit = await wasm_tester(
      join(
        __dirname,
        "../../circuits/deposit_kyc_non_repudiation_enforced.circom",
      ),
    );

    let keypair = genKeypair();
    Alice.privKey = keypair.privKey;
    Alice.pubKey = keypair.pubKey;

    keypair = genKeypair();
    Bob.privKey = keypair.privKey;
    Bob.pubKey = keypair.pubKey;

    keypair = genKeypair();
    Arbiter.privKey = keypair.privKey;
    Arbiter.pubKey = keypair.pubKey;

    keypair = genKeypair();
    Enforcer.privKey = keypair.privKey;
    Enforcer.pubKey = keypair.pubKey;

    // initialize the identity Sparse Merkle Tree
    smtKYC = new Merkletree(
      new InMemoryDB(str2Bytes("kyc")),
      true,
      SMT_HEIGHT_IDENTITY,
    );
    await smtKYC.add(poseidonHash2(Alice.pubKey), poseidonHash2(Alice.pubKey));
    await smtKYC.add(poseidonHash2(Bob.pubKey), poseidonHash2(Bob.pubKey));

    // all ACTIVE (happy path)
    smtComplianceAllActive = new Merkletree(
      new InMemoryDB(str2Bytes("comp-all-active")),
      true,
      SMT_HEIGHT_COMPLIANCE,
    );
    await smtComplianceAllActive.add(
      poseidonHash2(Alice.pubKey),
      poseidonHash3([...Alice.pubKey, STATUS_ACTIVE]),
    );
    await smtComplianceAllActive.add(
      poseidonHash2(Bob.pubKey),
      poseidonHash3([...Bob.pubKey, STATUS_ACTIVE]),
    );

    // Bob FROZEN (recipient FROZEN test)
    smtComplianceRecipientFrozen = new Merkletree(
      new InMemoryDB(str2Bytes("comp-recip-frozen")),
      true,
      SMT_HEIGHT_COMPLIANCE,
    );
    await smtComplianceRecipientFrozen.add(
      poseidonHash2(Alice.pubKey),
      poseidonHash3([...Alice.pubKey, STATUS_ACTIVE]),
    );
    await smtComplianceRecipientFrozen.add(
      poseidonHash2(Bob.pubKey),
      poseidonHash3([...Bob.pubKey, STATUS_FROZEN]),
    );
  });

  // Build circuit inputs for a standard 2-output deposit.
  // output 1 goes to Alice, output 2 goes to Bob.
  async function buildDepositInputs(complianceSmt) {
    const outputValues = [100, 200];

    const salt1 = newSalt();
    const output1 = poseidonHash([
      BigInt(outputValues[0]),
      salt1,
      ...Alice.pubKey,
    ]);
    const salt2 = newSalt();
    const output2 = poseidonHash([
      BigInt(outputValues[1]),
      salt2,
      ...Bob.pubKey,
    ]);
    const outputCommitments = [output1, output2];

    const encryptionNonce = newEncryptionNonce();
    const ephemeralKeypair = genKeypair();
    const encryptInputs = stringifyBigInts({
      encryptionNonce,
      ecdhPrivateKey: formatPrivKeyForBabyJub(ephemeralKeypair.privKey),
    });

    const kycProofAlice = await smtKYC.generateCircomVerifierProof(
      poseidonHash2(Alice.pubKey),
      ZERO_HASH,
    );
    const kycProofBob = await smtKYC.generateCircomVerifierProof(
      poseidonHash2(Bob.pubKey),
      ZERO_HASH,
    );
    const identitiesRoot = kycProofAlice.root.bigInt();

    const compProofAlice = await complianceSmt.generateCircomVerifierProof(
      poseidonHash2(Alice.pubKey),
      ZERO_HASH,
    );
    const compProofBob = await complianceSmt.generateCircomVerifierProof(
      poseidonHash2(Bob.pubKey),
      ZERO_HASH,
    );
    const complianceRoot = compProofAlice.root.bigInt();

    const circuitInputs = {
      outputCommitments,
      outputValues,
      outputSalts: [salt1, salt2],
      outputOwnerPublicKeys: [Alice.pubKey, Bob.pubKey],
      identitiesRoot,
      identitiesMerkleProof: [
        kycProofAlice.siblings.map((s) => s.bigInt()),
        kycProofBob.siblings.map((s) => s.bigInt()),
      ],
      complianceRoot,
      complianceMerkleProof: [
        compProofAlice.siblings.map((s) => s.bigInt()),
        compProofBob.siblings.map((s) => s.bigInt()),
      ],
      arbiterPublicKey: Arbiter.pubKey,
      enforcerPublicKey: Enforcer.pubKey,
      ...encryptInputs,
    };

    return {
      circuitInputs,
      outputValues,
      salts: { salt1, salt2 },
      outputCommitments,
      identitiesRoot,
      complianceRoot,
      encryptionNonce,
      ephemeralKeypair,
    };
  }

  it("should succeed for valid deposit, verify amount binding and authority decryption", async function () {
    this.timeout(60000);

    const {
      circuitInputs,
      outputValues,
      salts,
      outputCommitments,
      identitiesRoot,
      complianceRoot,
      encryptionNonce,
      ephemeralKeypair,
    } = await buildDepositInputs(smtComplianceAllActive);

    const witness = await circuit.calculateWitness(circuitInputs, true);
    // calculateWitness evaluates the asserts; checkConstraints evaluates the
    // R1CS system, which is where an under-constrained signal shows up.
    await circuit.checkConstraints(witness);

    // Public-signal indices come from test/lib/aenknre-signal-layout.js, which
    // public-signal-layout.js checks against the compiled .sym. Circom orders
    // public signals by declaration order in the template, not by the order of
    // the `{ public [...] }` list, so they cannot be re-derived by hand here.

    // amount binding: out == sum(outputValues)
    expect(witness[pi("out")]).to.equal(
      BigInt(outputValues[0] + outputValues[1]),
    );

    expect(witness[pi("outputCommitments[0]")]).to.equal(
      BigInt(outputCommitments[0]),
    );
    expect(witness[pi("outputCommitments[1]")]).to.equal(
      BigInt(outputCommitments[1]),
    );
    expect(witness[pi("identitiesRoot")]).to.equal(identitiesRoot);
    expect(witness[pi("complianceRoot")]).to.equal(complianceRoot);
    expect(witness[pi("encryptionNonce")]).to.equal(BigInt(encryptionNonce));
    expect(witness[pi("arbiterPublicKey[0]")]).to.equal(Arbiter.pubKey[0]);
    expect(witness[pi("arbiterPublicKey[1]")]).to.equal(Arbiter.pubKey[1]);
    expect(witness[pi("enforcerPublicKey[0]")]).to.equal(Enforcer.pubKey[0]);
    expect(witness[pi("enforcerPublicKey[1]")]).to.equal(Enforcer.pubKey[1]);

    // receiver decryption: Alice decrypts output 1
    let cipherText = witness.slice(4, 8);
    let recoveredKey = genEcdhSharedKey(Alice.privKey, ephemeralKeypair.pubKey);
    let plainText = poseidonDecrypt(
      cipherText,
      recoveredKey,
      encryptionNonce,
      2,
    );
    expect(plainText).to.deep.equal([BigInt(outputValues[0]), salts.salt1]);

    // Bob decrypts output 2
    cipherText = witness.slice(8, 12);
    recoveredKey = genEcdhSharedKey(Bob.privKey, ephemeralKeypair.pubKey);
    plainText = poseidonDecrypt(cipherText, recoveredKey, encryptionNonce, 2);
    expect(plainText).to.deep.equal([BigInt(outputValues[1]), salts.salt2]);

    // arbiter decrypts the 14-element authority plaintext
    const arbiterKey = genEcdhSharedKey(
      Arbiter.privKey,
      ephemeralKeypair.pubKey,
    );
    const arbiterCipherText = witness.slice(12, 28);
    const arbiterPlainText = poseidonDecrypt(
      arbiterCipherText,
      arbiterKey,
      encryptionNonce,
      14,
    );
    // depositor pubkey = ecdhPublicKey (from ecdhPrivateKey via BabyPbk)
    const depositorPubKey = [
      witness[pi("ecdhPublicKey[0]")],
      witness[pi("ecdhPublicKey[1]")],
    ];
    expect(arbiterPlainText).to.deep.equal([
      depositorPubKey[0], // depositor public key
      depositorPubKey[1],
      0n, // input fields zeroed for deposit
      0n,
      0n,
      0n,
      Alice.pubKey[0], // output 1 owner
      Alice.pubKey[1],
      Bob.pubKey[0], // output 2 owner
      Bob.pubKey[1],
      BigInt(outputValues[0]), // output values and salts
      salts.salt1,
      BigInt(outputValues[1]),
      salts.salt2,
    ]);

    // enforcer decrypts the same schema with a different ECDH key
    const enforcerKey = genEcdhSharedKey(
      Enforcer.privKey,
      ephemeralKeypair.pubKey,
    );
    const enforcerCipherText = witness.slice(28, 44);
    const enforcerPlainText = poseidonDecrypt(
      enforcerCipherText,
      enforcerKey,
      encryptionNonce,
      14,
    );
    expect(enforcerPlainText).to.deep.equal(arbiterPlainText);

    // non-authority cannot decrypt arbiter ciphertext
    expect(function () {
      poseidonDecrypt(arbiterCipherText, recoveredKey, encryptionNonce, 14);
    }).to.throw();

    // non-authority cannot decrypt enforcer ciphertext
    expect(function () {
      poseidonDecrypt(enforcerCipherText, recoveredKey, encryptionNonce, 14);
    }).to.throw();
  });

  it("should fail because output recipient has FROZEN compliance status", async function () {
    this.timeout(60000);

    const { circuitInputs } = await buildDepositInputs(
      smtComplianceRecipientFrozen,
    );

    await rejects(circuit, circuitInputs);
  });

  // Build a deposit whose second output slot is disabled (commitment == 0) but
  // whose preimage fields for that slot are attacker-chosen.
  async function buildDisabledSlotDeposit({ ghostValue, ghostSalt }) {
    const outputValues = [100, ghostValue];
    const salt1 = newSalt();
    const output1 = poseidonHash([
      BigInt(outputValues[0]),
      salt1,
      ...Alice.pubKey,
    ]);

    const encryptionNonce = newEncryptionNonce();
    const ephemeralKeypair = genKeypair();

    const kycProofAlice = await smtKYC.generateCircomVerifierProof(
      poseidonHash2(Alice.pubKey),
      ZERO_HASH,
    );
    const compProofAlice =
      await smtComplianceAllActive.generateCircomVerifierProof(
        poseidonHash2(Alice.pubKey),
        ZERO_HASH,
      );

    return {
      encryptionNonce,
      ephemeralKeypair,
      circuitInputs: {
        outputCommitments: [output1, 0n],
        outputValues,
        outputSalts: [salt1, ghostSalt],
        outputOwnerPublicKeys: [Alice.pubKey, Bob.pubKey],
        identitiesRoot: kycProofAlice.root.bigInt(),
        identitiesMerkleProof: [
          kycProofAlice.siblings.map((s) => s.bigInt()),
          Array(SMT_HEIGHT_IDENTITY).fill(0n),
        ],
        complianceRoot: compProofAlice.root.bigInt(),
        complianceMerkleProof: [
          compProofAlice.siblings.map((s) => s.bigInt()),
          Array(SMT_HEIGHT_COMPLIANCE).fill(0n),
        ],
        arbiterPublicKey: Arbiter.pubKey,
        enforcerPublicKey: Enforcer.pubKey,
        ...stringifyBigInts({
          encryptionNonce,
          ecdhPrivateKey: formatPrivKeyForBabyJub(ephemeralKeypair.privKey),
        }),
      },
    };
  }

  it("should fail when a disabled output slot carries value", async function () {
    this.timeout(60000);

    // The commitment is zero, so CheckHashes skips the slot and no note is
    // minted for it — but its value still lands in `out`, which the contract
    // uses as the ERC-20 amount to pull. The depositor is charged 600 for 100
    // units of notes, and the chain's own accounting disagrees with the tree.
    const { circuitInputs } = await buildDisabledSlotDeposit({
      ghostValue: 500,
      ghostSalt: newSalt(),
    });

    await rejects(circuit, circuitInputs);
  });

  it("should keep a disabled output slot out of the authority record", async function () {
    this.timeout(60000);

    // The authority plaintext is assembled from the raw preimage fields,
    // so a disabled slot could still publish an owner key and salt of the
    // prover's choosing. An auditor reconciling the record against the
    // commitment set finds an entry that matches no commitment.
    const { circuitInputs, encryptionNonce, ephemeralKeypair } =
      await buildDisabledSlotDeposit({ ghostValue: 0, ghostSalt: newSalt() });

    const witness = await circuit.calculateWitness(circuitInputs, true);
    await circuit.checkConstraints(witness);

    const arbiterKey = genEcdhSharedKey(
      Arbiter.privKey,
      ephemeralKeypair.pubKey,
    );
    const plainText = poseidonDecrypt(
      witness.slice(12, 28),
      arbiterKey,
      encryptionNonce,
      14,
    );

    // slot 2 of the 14-element authority schema: owner key at 8-9, value/salt at 12-13
    expect(plainText[8]).to.equal(0n);
    expect(plainText[9]).to.equal(0n);
    expect(plainText[12]).to.equal(0n);
    expect(plainText[13]).to.equal(0n);
  });

  it("should fail when minting to an output owner key with x == 0", async function () {
    this.timeout(60000);

    // On the deposit path: shields value to a key present in neither the
    // identities tree nor the compliance tree, because both skip on x == 0.
    const outputValues = [777, 0];
    const salt1 = newSalt();
    const output1 = poseidonHash([BigInt(outputValues[0]), salt1, 0n, 1n]);

    const kycProofAlice = await smtKYC.generateCircomVerifierProof(
      poseidonHash2(Alice.pubKey),
      ZERO_HASH,
    );
    const compProofAlice =
      await smtComplianceAllActive.generateCircomVerifierProof(
        poseidonHash2(Alice.pubKey),
        ZERO_HASH,
      );
    const encryptionNonce = newEncryptionNonce();
    const ephemeralKeypair = genKeypair();

    await rejects(circuit, {
      outputCommitments: [output1, 0n],
      outputValues,
      outputSalts: [salt1, 0n],
      outputOwnerPublicKeys: [
        [0n, 1n],
        [0n, 1n],
      ],
      identitiesRoot: kycProofAlice.root.bigInt(),
      identitiesMerkleProof: [
        Array(SMT_HEIGHT_IDENTITY).fill(0n),
        Array(SMT_HEIGHT_IDENTITY).fill(0n),
      ],
      complianceRoot: compProofAlice.root.bigInt(),
      complianceMerkleProof: [
        Array(SMT_HEIGHT_COMPLIANCE).fill(0n),
        Array(SMT_HEIGHT_COMPLIANCE).fill(0n),
      ],
      arbiterPublicKey: Arbiter.pubKey,
      enforcerPublicKey: Enforcer.pubKey,
      ...stringifyBigInts({
        encryptionNonce,
        ecdhPrivateKey: formatPrivKeyForBabyJub(ephemeralKeypair.privKey),
      }),
    });
  });

  it("should fail when the ephemeral key is zero", async function () {
    this.timeout(60000);

    // On the deposit path the ephemeral public key doubles as
    // the depositor's identity in the authority record, so a zero scalar both
    // makes every ciphertext world-readable and records the depositor as the
    // curve identity.
    const { circuitInputs } = await buildDisabledSlotDeposit({
      ghostValue: 0,
      ghostSalt: 0n,
    });
    circuitInputs.ecdhPrivateKey = 0;

    await rejects(circuit, circuitInputs);
  });

  it("should fail when the deposit recipient is not KYC-registered", async function () {
    this.timeout(60000);

    // Negative KYC coverage on the deposit path: shielding value to an identity
    // that is absent from the identities tree must be refused.
    const stranger = genKeypair();
    const outputValues = [100, 0];
    const salt1 = newSalt();
    const output1 = poseidonHash([
      BigInt(outputValues[0]),
      salt1,
      ...stranger.pubKey,
    ]);
    const kycProofAlice = await smtKYC.generateCircomVerifierProof(
      poseidonHash2(Alice.pubKey),
      ZERO_HASH,
    );
    const compProofAlice =
      await smtComplianceAllActive.generateCircomVerifierProof(
        poseidonHash2(Alice.pubKey),
        ZERO_HASH,
      );
    const encryptionNonce = newEncryptionNonce();
    const ephemeralKeypair = genKeypair();

    await rejects(circuit, {
      outputCommitments: [output1, 0n],
      outputValues,
      outputSalts: [salt1, 0n],
      outputOwnerPublicKeys: [stranger.pubKey, stranger.pubKey],
      identitiesRoot: kycProofAlice.root.bigInt(),
      identitiesMerkleProof: [
        Array(SMT_HEIGHT_IDENTITY).fill(0n),
        Array(SMT_HEIGHT_IDENTITY).fill(0n),
      ],
      complianceRoot: compProofAlice.root.bigInt(),
      complianceMerkleProof: [
        Array(SMT_HEIGHT_COMPLIANCE).fill(0n),
        Array(SMT_HEIGHT_COMPLIANCE).fill(0n),
      ],
      arbiterPublicKey: Arbiter.pubKey,
      enforcerPublicKey: Enforcer.pubKey,
      ...stringifyBigInts({
        encryptionNonce,
        ecdhPrivateKey: formatPrivKeyForBabyJub(ephemeralKeypair.privKey),
      }),
    });
  });

  it("should succeed with a disabled output slot (commitment == 0)", async function () {
    this.timeout(60000);

    const outputValues = [300, 0];
    const salt1 = newSalt();
    const output1 = poseidonHash([
      BigInt(outputValues[0]),
      salt1,
      ...Alice.pubKey,
    ]);
    const outputCommitments = [output1, 0n];

    const encryptionNonce = newEncryptionNonce();
    const ephemeralKeypair = genKeypair();
    const encryptInputs = stringifyBigInts({
      encryptionNonce,
      ecdhPrivateKey: formatPrivKeyForBabyJub(ephemeralKeypair.privKey),
    });

    const kycProofAlice = await smtKYC.generateCircomVerifierProof(
      poseidonHash2(Alice.pubKey),
      ZERO_HASH,
    );

    const compProofAlice =
      await smtComplianceAllActive.generateCircomVerifierProof(
        poseidonHash2(Alice.pubKey),
        ZERO_HASH,
      );

    const witness = await circuit.calculateWitness(
      {
        outputCommitments,
        outputValues,
        outputSalts: [salt1, 0n],
        // A disabled slot's owner key is inert: the curve check is fed the
        // Base8 padding instead of this value, the KYC/compliance key is zeroed,
        // and CheckHashes is gated off by the zero commitment. Any value works;
        // a real key is used only to keep the fixture readable.
        outputOwnerPublicKeys: [Alice.pubKey, Alice.pubKey],
        identitiesRoot: kycProofAlice.root.bigInt(),
        identitiesMerkleProof: [
          kycProofAlice.siblings.map((s) => s.bigInt()),
          Array(SMT_HEIGHT_IDENTITY).fill(0n), // disabled slot
        ],
        complianceRoot: compProofAlice.root.bigInt(),
        complianceMerkleProof: [
          compProofAlice.siblings.map((s) => s.bigInt()),
          Array(SMT_HEIGHT_COMPLIANCE).fill(0n), // disabled slot
        ],
        arbiterPublicKey: Arbiter.pubKey,
        enforcerPublicKey: Enforcer.pubKey,
        ...encryptInputs,
      },
      true,
    );

    expect(witness[pi("out")]).to.equal(300n); // out == sum(outputValues)
    expect(witness[pi("outputCommitments[1]")]).to.equal(0n);
  });

  it("should fail because output commitment does not match preimage", async function () {
    this.timeout(60000);

    const { circuitInputs } = await buildDepositInputs(smtComplianceAllActive);

    // tamper: supply wrong value but keep original commitment
    circuitInputs.outputValues = [999, 200];

    await rejects(circuit, circuitInputs);
  });
});
