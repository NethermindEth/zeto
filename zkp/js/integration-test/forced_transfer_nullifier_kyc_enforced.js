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

const CIRCUIT_NAME = "forced_transfer_nullifier_kyc_enforced";

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
const STATUS_FROZEN = 2n;

describe("forced_transfer_nullifier_kyc_enforced circuit tests", () => {
  let circuit, provingKeyFile, verificationKey;
  let smtUtxo, smtKYC, smtCompliance;

  // Alice is the frozen owner whose notes are seized; Bob is the active recipient
  const Alice = {};
  const Bob = {};
  const Arbiter = {};
  const Enforcer = {};

  before(async () => {
    circuit = await loadCircuit(CIRCUIT_NAME);
    ({ provingKeyFile, verificationKey } = loadProvingKeys(CIRCUIT_NAME));

    for (const party of [Alice, Bob, Arbiter, Enforcer]) {
      const keypair = genKeypair();
      party.privKey = keypair.privKey;
      party.pubKey = keypair.pubKey;
    }

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

    for (const [party, status] of [
      [Alice, STATUS_FROZEN],
      [Bob, STATUS_ACTIVE],
    ]) {
      const identity = kycHash(party.pubKey);
      await smtKYC.add(identity, identity);
      await smtCompliance.add(
        poseidonHash2(party.pubKey),
        poseidonHash3([...party.pubKey, status]),
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

    // The enforcer marks the seized notes from ECDH(enforcerPriv, ownerPub),
    // never holding Alice's key. Diffie-Hellman symmetry is what makes the mark
    // recognizable: Alice reaches the same tag from ECDH(ownerPriv, enforcerPub),
    // so the seizure lands in the same nullifier domain her own spends use.
    const enforcementNullifiers = inputCommitments.map((c) =>
      enforcementNullifier(Enforcer.privKey, Alice.pubKey, c),
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
      ...Bob.pubKey,
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
        enforcementNullifiers,
        inputCommitments,
        inputValues,
        inputSalts: [salt1, salt2],
        seizedOwnerPublicKey: Alice.pubKey,
        enforcerPrivateKey: formatPrivKeyForBabyJub(Enforcer.privKey),
        utxosRoot,
        utxosMerkleProof: [
          utxoProof1.siblings.map((s) => s.bigInt()),
          utxoProof2.siblings.map((s) => s.bigInt()),
        ],
        enabledInputs: [1, 1],
        identitiesRoot,
        // nOutputs + 1 proofs: [seized owner, output1 owner, output2 owner]
        identitiesMerkleProof: [
          kycProofAlice.siblings.map((s) => s.bigInt()),
          kycProofBob.siblings.map((s) => s.bigInt()),
          kycProofBob.siblings.map((s) => s.bigInt()),
        ],
        complianceRoot,
        complianceMerkleProof: [
          compProofAlice.siblings.map((s) => s.bigInt()),
          compProofBob.siblings.map((s) => s.bigInt()),
          compProofBob.siblings.map((s) => s.bigInt()),
        ],
        outputCommitments,
        outputValues,
        outputSalts: [salt3, salt4],
        outputOwnerPublicKeys: [Bob.pubKey, Bob.pubKey],
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

    expect(publicSignals.length).to.equal(56);
    const signals = publicSignals.map(BigInt);

    expect(signals.slice(0, 2)).to.deep.equal(ephemeralKeypair.pubKey);

    // seizure publishes the enforcement tags alone: the enforcer cannot compute
    // the owner nullifiers, and this circuit declares none
    expect(signals.slice(42, 44)).to.deep.equal(enforcementNullifiers);
    expect(signals.slice(44, 46)).to.deep.equal(outputCommitments);
    expect(signals[46]).to.equal(utxosRoot);
    expect(signals[47]).to.equal(identitiesRoot);
    // the root of a compliance tree holding Alice as FROZEN and Bob as ACTIVE
    expect(signals[48]).to.equal(complianceRoot);
    expect(signals.slice(49, 51)).to.deep.equal([1n, 1n]);
    expect(signals.slice(51, 53)).to.deep.equal(Enforcer.pubKey);
    expect(signals[53]).to.equal(encryptionNonce);
    expect(signals.slice(54, 56)).to.deep.equal(Arbiter.pubKey);

    // The seizure target stays confidential: neither the seized owner nor the
    // notes taken from her reach the chain. Every non-ciphertext index is
    // pinned above and the length is pinned with them, so a circuit change that
    // published either would fail those assertions first — this is the property
    // they add up to, stated rather than re-asserted.

    const sharedKey = (party) =>
      genEcdhSharedKey(party.privKey, ephemeralKeypair.pubKey);
    const bobKey = sharedKey(Bob);
    expect(
      poseidonDecrypt(signals.slice(2, 6), bobKey, encryptionNonce, 2),
    ).to.deep.equal([BigInt(outputValues[0]), salt3]);
    expect(
      poseidonDecrypt(signals.slice(6, 10), bobKey, encryptionNonce, 2),
    ).to.deep.equal([BigInt(outputValues[1]), salt4]);

    const arbiterPlaintext = poseidonDecrypt(
      signals.slice(10, 26),
      sharedKey(Arbiter),
      encryptionNonce,
      14,
    );
    // the audit record names Alice, the frozen owner, as the sender — not the
    // enforcer who assembled and proved the transaction
    expect(arbiterPlaintext).to.deep.equal([
      Alice.pubKey[0], // seized owner public key
      Alice.pubKey[1],
      BigInt(inputValues[0]), // input values interleaved with input salts
      salt1,
      BigInt(inputValues[1]),
      salt2,
      Bob.pubKey[0], // output owner public keys
      Bob.pubKey[1],
      Bob.pubKey[0],
      Bob.pubKey[1],
      BigInt(outputValues[0]), // output values interleaved with output salts
      salt3,
      BigInt(outputValues[1]),
      salt4,
    ]);
    expect(
      poseidonDecrypt(
        signals.slice(26, 42),
        sharedKey(Enforcer),
        encryptionNonce,
        14,
      ),
    ).to.deep.equal(arbiterPlaintext);

    // the tampered value must differ from outputValues[0], or the recomputed
    // commitment equals the original and nothing is actually tampered
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
