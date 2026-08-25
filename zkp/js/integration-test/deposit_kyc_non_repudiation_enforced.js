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
} = require("../index.js");
const { loadProvingKeys, expectEveryPublicSignalBound } = require("./utils.js");
const { signalNames } = require("../test/lib/aenknre-signal-layout.js");

const CIRCUIT_NAME = "deposit_kyc_non_repudiation_enforced";

// publicSignals[i] is SIGNAL_NAMES[i]; the same signal is witness[i + 1],
// because witness[0] is the constant 1. The order is declared once in
// test/lib/aenknre-signal-layout.js and checked there against the compiled
// .sym, the generated verifier's _pubSignals arity and PI_LEN_* in
// solidity/contracts/lib/aenknre_codec.sol.
const SIGNAL_NAMES = signalNames(CIRCUIT_NAME);

const SMT_HEIGHT_IDENTITY = 20;
const SMT_HEIGHT_COMPLIANCE = 20;
const poseidonHash = Poseidon.poseidon4;
const poseidonHash2 = Poseidon.poseidon2;
const poseidonHash3 = Poseidon.poseidon3;

const STATUS_ACTIVE = 1n;

describe("deposit_kyc_non_repudiation_enforced circuit tests", () => {
  let circuit, provingKeyFile, verificationKey;
  let smtKYC, smtCompliance;

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

  it("should return true for valid witness and false when public signals are tampered", async () => {
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

    expect(publicSignals.length).to.equal(52);
    const signals = publicSignals.map(BigInt);

    // `out` is the amount the contract transfers over ERC-20 on deposit
    expect(publicSignals[0]).to.equal("300");

    expect(signals.slice(1, 3)).to.deep.equal(ephemeralKeypair.pubKey);
    expect(signals[1]).to.not.equal(0n);

    expect(signals.slice(43, 45)).to.deep.equal(outputCommitments);
    expect(signals[45]).to.equal(identitiesRoot);
    expect(signals[46]).to.equal(complianceRoot);
    expect(signals[47]).to.equal(encryptionNonce);
    expect(signals.slice(48, 50)).to.deep.equal(Arbiter.pubKey);
    expect(signals.slice(50, 52)).to.deep.equal(Enforcer.pubKey);

    const sharedKey = (party) =>
      genEcdhSharedKey(party.privKey, ephemeralKeypair.pubKey);
    expect(
      poseidonDecrypt(
        signals.slice(3, 7),
        sharedKey(Alice),
        encryptionNonce,
        2,
      ),
    ).to.deep.equal([BigInt(outputValues[0]), salt1]);
    expect(
      poseidonDecrypt(signals.slice(7, 11), sharedKey(Bob), encryptionNonce, 2),
    ).to.deep.equal([BigInt(outputValues[1]), salt2]);

    const arbiterPlaintext = poseidonDecrypt(
      signals.slice(11, 27),
      sharedKey(Arbiter),
      encryptionNonce,
      14,
    );
    expect(arbiterPlaintext).to.deep.equal([
      // the sender slot carries the ephemeral ecdhPublicKey, which no KYC check
      // binds to an identity; the depositor is attributable only via msg.sender
      ephemeralKeypair.pubKey[0],
      ephemeralKeypair.pubKey[1],
      0n, // a deposit consumes no input, so it forges no input audit record
      0n,
      0n,
      0n,
      Alice.pubKey[0], // output owner public keys
      Alice.pubKey[1],
      Bob.pubKey[0],
      Bob.pubKey[1],
      BigInt(outputValues[0]), // output values interleaved with output salts
      salt1,
      BigInt(outputValues[1]),
      salt2,
    ]);
    expect(
      poseidonDecrypt(
        signals.slice(27, 43),
        sharedKey(Enforcer),
        encryptionNonce,
        14,
      ),
    ).to.deep.equal(arbiterPlaintext);

    // the tampered value must differ from outputValues[0], or the recomputed
    // commitment equals the original and nothing is actually tampered
    const tamperedOutputHash = poseidonHash([
      BigInt(500),
      salt1,
      ...Alice.pubKey,
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
