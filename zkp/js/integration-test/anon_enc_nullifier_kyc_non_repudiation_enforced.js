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
const { groth16 } = require("snarkjs");
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
  loadCircuit,
  newEncryptionNonce,
  poseidonDecrypt,
  kycHash,
  enforcementNullifier,
} = require("../index.js");
const { loadProvingKeys, expectEveryPublicSignalBound } = require("./utils.js");
const { signalNames } = require("../test/lib/aenknre-signal-layout.js");

const CIRCUIT_NAME = "anon_enc_nullifier_kyc_non_repudiation_enforced";

// publicSignals[i] is SIGNAL_NAMES[i]; the same signal is witness[i + 1],
// because witness[0] is the constant 1. The order is declared once in
// test/lib/aenknre-signal-layout.js and checked there against the compiled
// .sym, the generated verifier's _pubSignals arity and PI_LEN_* in
// solidity/contracts/lib/aenknre_codec.sol.
const SIGNAL_NAMES = signalNames(CIRCUIT_NAME);

const SMT_HEIGHT_UTXO = 32;
const SMT_HEIGHT_IDENTITY = 20;
const SMT_HEIGHT_COMPLIANCE = 20;
const poseidonHash = Poseidon.poseidon4;
const poseidonHash2 = Poseidon.poseidon2;
const poseidonHash3 = Poseidon.poseidon3;

const STATUS_ACTIVE = 1n;

describe("main circuit tests for Zeto fungible tokens with encryption, KYC, non-repudiation, and enforcement nullifiers", () => {
  let circuit, provingKeyFile, verificationKey;
  let smtUtxo, smtKYC, smtCompliance;

  const Alice = {};
  const Bob = {};
  const Arbiter = {};
  const Enforcer = {};
  let senderPrivateKey;

  before(async () => {
    circuit = await loadCircuit(CIRCUIT_NAME);
    ({ provingKeyFile, verificationKey } = loadProvingKeys(CIRCUIT_NAME));

    for (const party of [Alice, Bob, Arbiter, Enforcer]) {
      const keypair = genKeypair();
      party.privKey = keypair.privKey;
      party.pubKey = keypair.pubKey;
    }
    senderPrivateKey = formatPrivKeyForBabyJub(Alice.privKey);

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
    smtCompliance = new Merkletree(
      new InMemoryDB(str2Bytes("compliance")),
      true,
      SMT_HEIGHT_COMPLIANCE,
    );

    for (const party of [Alice, Bob]) {
      const identity = kycHash(party.pubKey);
      await smtKYC.add(identity, identity);
      await smtCompliance.add(
        poseidonHash2(party.pubKey),
        poseidonHash3([...party.pubKey, STATUS_ACTIVE]),
      );
    }
  });

  it("should generate a valid proof that can be verified successfully and fail when public signals are tampered", async () => {
    const inputValues = [32, 40];
    const outputValues = [20, 52];

    const salt1 = newSalt();
    const input1 = poseidonHash([
      BigInt(inputValues[0]),
      salt1,
      ...Alice.pubKey,
    ]);
    const salt2 = newSalt();
    const input2 = poseidonHash([
      BigInt(inputValues[1]),
      salt2,
      ...Alice.pubKey,
    ]);
    const inputCommitments = [input1, input2];

    const ownerNullifiers = [
      poseidonHash3([BigInt(inputValues[0]), salt1, senderPrivateKey]),
      poseidonHash3([BigInt(inputValues[1]), salt2, senderPrivateKey]),
    ];

    // the enforcement domain marks the same inputs under ECDH(owner, enforcer)
    const enforcementNullifiers = inputCommitments.map((c) =>
      enforcementNullifier(Alice.privKey, Enforcer.pubKey, c),
    );

    await smtUtxo.add(input1, input1);
    await smtUtxo.add(input2, input2);
    const utxoProof1 = await smtUtxo.generateCircomVerifierProof(
      input1,
      ZERO_HASH,
    );
    const utxoProof2 = await smtUtxo.generateCircomVerifierProof(
      input2,
      ZERO_HASH,
    );
    const utxosRoot = utxoProof1.root.bigInt();

    const salt3 = newSalt();
    const output1 = poseidonHash([
      BigInt(outputValues[0]),
      salt3,
      ...Bob.pubKey,
    ]);
    const salt4 = newSalt();
    const output2 = poseidonHash([
      BigInt(outputValues[1]),
      salt4,
      ...Alice.pubKey,
    ]);
    const outputCommitments = [output1, output2];

    const kycProofAlice = await smtKYC.generateCircomVerifierProof(
      kycHash(Alice.pubKey),
      ZERO_HASH,
    );
    const kycProofBob = await smtKYC.generateCircomVerifierProof(
      kycHash(Bob.pubKey),
      ZERO_HASH,
    );
    const identitiesRoot = kycProofAlice.root.bigInt();

    const compProofAlice = await smtCompliance.generateCircomVerifierProof(
      poseidonHash2(Alice.pubKey),
      ZERO_HASH,
    );
    const compProofBob = await smtCompliance.generateCircomVerifierProof(
      poseidonHash2(Bob.pubKey),
      ZERO_HASH,
    );
    const complianceRoot = compProofAlice.root.bigInt();

    const encryptionNonce = newEncryptionNonce();
    const ephemeralKeypair = genKeypair();
    const encryptInputs = stringifyBigInts({
      encryptionNonce,
      ecdhPrivateKey: formatPrivKeyForBabyJub(ephemeralKeypair.privKey),
    });

    const startTime = Date.now();
    const witness = await circuit.calculateWTNSBin(
      {
        ownerNullifiers,
        enforcementNullifiers,
        inputCommitments,
        inputValues,
        inputSalts: [salt1, salt2],
        inputOwnerPrivateKey: senderPrivateKey,
        utxosRoot,
        utxosMerkleProof: [
          utxoProof1.siblings.map((s) => s.bigInt()),
          utxoProof2.siblings.map((s) => s.bigInt()),
        ],
        enabledInputs: [1, 1],
        identitiesRoot,
        identitiesMerkleProof: [
          kycProofAlice.siblings.map((s) => s.bigInt()),
          kycProofBob.siblings.map((s) => s.bigInt()),
          kycProofAlice.siblings.map((s) => s.bigInt()),
        ],
        complianceRoot,
        complianceMerkleProof: [
          compProofAlice.siblings.map((s) => s.bigInt()),
          compProofBob.siblings.map((s) => s.bigInt()),
          compProofAlice.siblings.map((s) => s.bigInt()),
        ],
        outputCommitments,
        outputValues,
        outputSalts: [salt3, salt4],
        outputOwnerPublicKeys: [Bob.pubKey, Alice.pubKey],
        arbiterPublicKey: Arbiter.pubKey,
        enforcerPublicKey: Enforcer.pubKey,
        ...encryptInputs,
      },
      true,
    );

    const { proof, publicSignals } = await groth16.prove(
      provingKeyFile,
      witness,
    );
    console.log("Proving time: ", (Date.now() - startTime) / 1000, "s");

    let verifyResult = await groth16.verify(
      verificationKey,
      publicSignals,
      proof,
    );
    expect(verifyResult).to.be.true;

    expect(publicSignals.length).to.equal(58);
    const signals = publicSignals.map(BigInt);

    expect(signals.slice(0, 2)).to.deep.equal(ephemeralKeypair.pubKey);

    expect(signals.slice(42, 44)).to.deep.equal(ownerNullifiers);
    expect(signals.slice(44, 46)).to.deep.equal(enforcementNullifiers);
    expect(signals[46]).to.equal(utxosRoot);
    expect(signals.slice(47, 49)).to.deep.equal([1n, 1n]);
    expect(signals[49]).to.equal(identitiesRoot);
    expect(signals[50]).to.equal(complianceRoot);
    expect(signals.slice(51, 53)).to.deep.equal(outputCommitments);
    expect(signals[53]).to.equal(encryptionNonce);
    expect(signals.slice(54, 56)).to.deep.equal(Arbiter.pubKey);
    expect(signals.slice(56, 58)).to.deep.equal(Enforcer.pubKey);

    const sharedKey = (party) =>
      genEcdhSharedKey(party.privKey, ephemeralKeypair.pubKey);
    const bobKey = sharedKey(Bob);
    expect(
      poseidonDecrypt(signals.slice(2, 6), bobKey, encryptionNonce, 2),
    ).to.deep.equal([BigInt(outputValues[0]), salt3]);

    // the change output is encrypted to Alice, so Bob's key cannot open it
    expect(function () {
      poseidonDecrypt(signals.slice(6, 10), bobKey, encryptionNonce, 2);
    }).to.throw(
      "The last ciphertext element must match the second item of the permuted state",
    );

    const aliceKey = sharedKey(Alice);
    expect(
      poseidonDecrypt(signals.slice(6, 10), aliceKey, encryptionNonce, 2),
    ).to.deep.equal([BigInt(outputValues[1]), salt4]);

    const arbiterCiphertext = signals.slice(10, 26);
    const enforcerCiphertext = signals.slice(26, 42);
    const arbiterKey = sharedKey(Arbiter);
    const enforcerKey = sharedKey(Enforcer);
    const arbiterPlaintext = poseidonDecrypt(
      arbiterCiphertext,
      arbiterKey,
      encryptionNonce,
      14,
    );
    expect(arbiterPlaintext).to.deep.equal([
      Alice.pubKey[0], // input owner public key
      Alice.pubKey[1],
      BigInt(inputValues[0]), // input values interleaved with input salts
      salt1,
      BigInt(inputValues[1]),
      salt2,
      Bob.pubKey[0], // output owner public keys
      Bob.pubKey[1],
      Alice.pubKey[0],
      Alice.pubKey[1],
      BigInt(outputValues[0]), // output values interleaved with output salts
      salt3,
      BigInt(outputValues[1]),
      salt4,
    ]);
    expect(
      poseidonDecrypt(enforcerCiphertext, enforcerKey, encryptionNonce, 14),
    ).to.deep.equal(arbiterPlaintext);

    // Same strictness as the receiver stream above: a bare .to.throw() would
    // also pass on an unrelated failure, such as a length mismatch introduced
    // by a future change to these slice indices. The message differs from the
    // receiver stream's because a 14-element authority plaintext fails its
    // padding check before it reaches the permuted-state check.
    for (const ciphertext of [arbiterCiphertext, enforcerCiphertext]) {
      expect(function () {
        poseidonDecrypt(ciphertext, bobKey, encryptionNonce, 14);
      }).to.throw("The last element of the message must be 0");
    }

    const tamperedOutputHash = poseidonHash([
      BigInt(100),
      salt3,
      ...Bob.pubKey,
    ]);
    const tamperedPublicSignals = publicSignals.map((ps) =>
      ps.toString() === outputCommitments[0].toString()
        ? tamperedOutputHash
        : ps,
    );
    verifyResult = await groth16.verify(
      verificationKey,
      tamperedPublicSignals,
      proof,
    );
    expect(verifyResult).to.be.false;

    // every public signal must be bound by the key, not merely published
    await expectEveryPublicSignalBound(
      verificationKey,
      publicSignals,
      proof,
      SIGNAL_NAMES,
    );
  }).timeout(600000);
});
