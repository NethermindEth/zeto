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
const { loadProvingKeys } = require("./utils.js");

const CIRCUIT_NAME = "withdraw_nullifier_kyc_enforced";

const SMT_HEIGHT_UTXO = 32;
const SMT_HEIGHT_IDENTITY = 20;
const SMT_HEIGHT_COMPLIANCE = 20;
const poseidonHash = Poseidon.poseidon4;
const poseidonHash2 = Poseidon.poseidon2;
const poseidonHash3 = Poseidon.poseidon3;

const STATUS_ACTIVE = 1n;

const BN254_P =
  21888242871839275222246405745257275088548364400416034343698204186575808495617n;

const ENF_DOMAIN_TAG =
  21455947405572920533869930548514094044543253524099188107381343679564123236615n;

// The contract injects the withdrawal recipient as `uint256(uint160(msg.sender))`,
// so an observer cannot copy a pending withdrawal and redirect the payout. The
// circuit places no statement on the value beyond a constraint that keeps the
// optimizer from deleting the signal.
const RECIPIENT = BigInt("0x1234567890123456789012345678901234567890");

function computeEnforcementNullifier(
  ecdhPrivKey,
  counterpartyPubKey,
  commitment,
) {
  const shared = genEcdhSharedKey(ecdhPrivKey, counterpartyPubKey);
  const k0 = poseidonHash2([shared[0], shared[1]]);
  return poseidonHash3([commitment, k0, ENF_DOMAIN_TAG]);
}

// publicSignals[i] is SIGNAL_NAMES[i]; the same signal is witness[i + 1], because
// witness[0] is the constant 1. Circom orders public signals by declaration order
// in the template, not by the order of the `{ public [...] }` list, so the order
// cannot be read off the .circom source. zkp/js/test/lib/public-signal-layout.js is
// the authority: it pins this order against the compiled .sym, and against the
// generated verifier's _pubSignals arity and PI_LEN_WITHDRAW in
// solidity/contracts/lib/aenknre_codec.sol. Trailing numbers are 0-based group
// starts, so you can check an assertion's bare index without summing the widths.
const SIGNAL_NAMES = [
  ["ecdhPublicKey", 2], // 0
  ["encryptedValuesForArbiter", 16], // 2
  ["encryptedValuesForEnforcer", 16], // 18
  ["amount", 1], // 34
  ["ownerNullifiers", 2], // 35
  ["enforcementNullifiers", 2], // 37
  ["outputCommitments[0]", 1], // 39
  ["utxosRoot", 1], // 40
  ["identitiesRoot", 1], // 41
  ["complianceRoot", 1], // 42
  ["enabledInputs", 2], // 43
  ["encryptionNonce", 1], // 45
  ["arbiterPublicKey", 2], // 46
  ["enforcerPublicKey", 2], // 48
  ["recipient", 1], // 50
].flatMap(([name, width]) =>
  width === 1
    ? [name]
    : Array.from({ length: width }, (_, i) => `${name}[${i}]`),
);

describe("withdraw_nullifier_kyc_enforced circuit tests", () => {
  let circuit, provingKeyFile, verificationKey;
  let smtUtxo, smtKYC, smtCompliance;

  const Alice = {};
  const Arbiter = {};
  const Enforcer = {};
  let senderPrivateKey;

  before(async () => {
    circuit = await loadCircuit(CIRCUIT_NAME);
    ({ provingKeyFile, verificationKey } = loadProvingKeys(CIRCUIT_NAME));

    for (const party of [Alice, Arbiter, Enforcer]) {
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

    const identity = kycHash(Alice.pubKey);
    await smtKYC.add(identity, identity);
    await smtCompliance.add(
      poseidonHash2(Alice.pubKey),
      poseidonHash3([...Alice.pubKey, STATUS_ACTIVE]),
    );
  });

  it("should generate a valid proof that can be verified successfully and fail when public signals are tampered", async () => {
    const inputValues = [32, 40];
    const outputValues = [2];
    const amount = inputValues[0] + inputValues[1] - outputValues[0];

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
      computeEnforcementNullifier(Alice.privKey, Enforcer.pubKey, c),
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
      ...Alice.pubKey,
    ]);
    const outputCommitments = [output1];

    const kycProofAlice = await smtKYC.generateCircomVerifierProof(
      kycHash(Alice.pubKey),
      ZERO_HASH,
    );
    const identitiesRoot = kycProofAlice.root.bigInt();

    const compProofAlice = await smtCompliance.generateCircomVerifierProof(
      poseidonHash2(Alice.pubKey),
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
        amount,
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
        // nOutputs + 1 proofs: [sender, changeOutputOwner], both Alice
        identitiesMerkleProof: [
          kycProofAlice.siblings.map((s) => s.bigInt()),
          kycProofAlice.siblings.map((s) => s.bigInt()),
        ],
        complianceRoot,
        complianceMerkleProof: [
          compProofAlice.siblings.map((s) => s.bigInt()),
          compProofAlice.siblings.map((s) => s.bigInt()),
        ],
        outputCommitments,
        outputValues,
        outputSalts: [salt3],
        outputOwnerPublicKeys: [Alice.pubKey],
        arbiterPublicKey: Arbiter.pubKey,
        enforcerPublicKey: Enforcer.pubKey,
        recipient: RECIPIENT,
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

    expect(publicSignals.length).to.equal(51);
    const signals = publicSignals.map(BigInt);

    expect(signals.slice(0, 2)).to.deep.equal(ephemeralKeypair.pubKey);
    expect(signals[0]).to.not.equal(0n);

    // `amount` is the value the contract pays out over ERC-20 on withdrawal
    expect(publicSignals[34]).to.equal("70");

    expect(signals.slice(35, 37)).to.deep.equal(ownerNullifiers);
    expect(signals.slice(37, 39)).to.deep.equal(enforcementNullifiers);
    expect(signals[39]).to.equal(outputCommitments[0]);
    expect(signals[40]).to.equal(utxosRoot);
    expect(signals[41]).to.equal(identitiesRoot);
    expect(signals[42]).to.equal(complianceRoot);
    expect(signals.slice(43, 45)).to.deep.equal([1n, 1n]);
    expect(signals[45]).to.equal(encryptionNonce);
    expect(signals.slice(46, 48)).to.deep.equal(Arbiter.pubKey);
    expect(signals.slice(48, 50)).to.deep.equal(Enforcer.pubKey);
    expect(signals[50]).to.equal(RECIPIENT);

    const sharedKey = (party) =>
      genEcdhSharedKey(party.privKey, ephemeralKeypair.pubKey);
    const arbiterPlaintext = poseidonDecrypt(
      signals.slice(2, 18),
      sharedKey(Arbiter),
      encryptionNonce,
      14,
    );
    // withdraw publishes no per-receiver stream, so the change output is
    // accountable only through this authority plaintext: it names Alice, the
    // sender, as the change owner, and pads the virtual second output with zeros
    // rather than a forged record
    expect(arbiterPlaintext).to.deep.equal([
      Alice.pubKey[0], // input owner public key
      Alice.pubKey[1],
      BigInt(inputValues[0]), // input values interleaved with input salts
      salt1,
      BigInt(inputValues[1]),
      salt2,
      Alice.pubKey[0], // change output owner public key
      Alice.pubKey[1],
      0n,
      0n,
      BigInt(outputValues[0]), // change value and salt
      salt3,
      0n,
      0n,
    ]);
    expect(
      poseidonDecrypt(
        signals.slice(18, 34),
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
    for (let i = 0; i < publicSignals.length; i++) {
      const swept = publicSignals.slice();
      swept[i] = ((BigInt(swept[i]) + 1n) % BN254_P).toString();
      expect(
        await groth16.verify(verificationKey, swept, proof),
        `signal ${i} (${SIGNAL_NAMES[i]}) is not bound by the verification key`,
      ).to.be.false;
    }
  }).timeout(600000);
});
