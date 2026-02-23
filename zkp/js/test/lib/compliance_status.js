const { expect } = require("chai");
const { join } = require("path");
const { wasm: wasm_tester } = require("circom_tester");
const { genKeypair } = require("maci-crypto");
const { Poseidon } = require("../../index.js");
const { Merkletree, InMemoryDB, str2Bytes } = require("@iden3/js-merkletree");

const poseidon2 = Poseidon.poseidon2;
const poseidon3 = Poseidon.poseidon3;

// nComplianceSMTLevels used in both the test circuits and the trees
const SMT_HEIGHT = 10;

const STATUS_ACTIVE = 1n;
const STATUS_FROZEN = 2n;

// Mirrors the in-circuit leaf encoding:
//   leafKey   = Poseidon(2)([pkX, pkY])
//   leafValue = Poseidon(3)([pkX, pkY, status])
function leafKey(pubKey) {
  return poseidon2(pubKey);
}
function leafValue(pubKey, status) {
  return poseidon3([...pubKey, status]);
}

// Return circuit inputs for a single-identity compliance proof.
async function buildProofInputs(smt, pubKey) {
  const key = leafKey(pubKey);
  const root = await smt.root();
  const proof = await smt.generateCircomVerifierProof(key, root);
  return {
    publicKeys: [pubKey],
    root: root.bigInt(),
    merkleProof: [proof.siblings.map((s) => s.bigInt())],
  };
}

describe("ComplianceStatus circuit tests", () => {
  let activeCircuit, frozenCircuit;
  let activeSmt, frozenSmt;
  const alice = {};

  before(async function () {
    this.timeout(60000);

    activeCircuit = await wasm_tester(
      join(__dirname, "../circuits/compliance_status_active.circom"),
    );
    frozenCircuit = await wasm_tester(
      join(__dirname, "../circuits/compliance_status_frozen.circom"),
    );

    const kp = genKeypair();
    alice.privKey = kp.privKey;
    alice.pubKey = kp.pubKey;

    // activeSmt: Alice is ACTIVE (leafValue uses STATUS=1)
    activeSmt = new Merkletree(new InMemoryDB(str2Bytes("")), true, SMT_HEIGHT);
    await activeSmt.add(
      leafKey(alice.pubKey),
      leafValue(alice.pubKey, STATUS_ACTIVE),
    );

    // frozenSmt: Alice is FROZEN (leafValue uses STATUS=2)
    frozenSmt = new Merkletree(new InMemoryDB(str2Bytes("")), true, SMT_HEIGHT);
    await frozenSmt.add(
      leafKey(alice.pubKey),
      leafValue(alice.pubKey, STATUS_FROZEN),
    );
  });

  it("ACTIVE identity with correct proof should pass STATUS=1 circuit", async () => {
    const inputs = await buildProofInputs(activeSmt, alice.pubKey);

    let error;
    try {
      await activeCircuit.calculateWitness(inputs, true);
    } catch (e) {
      error = e;
    }
    expect(error).to.be.undefined;
  });

  it("ACTIVE-tree proof should fail STATUS=2 (FROZEN) circuit — compile-time STATUS prevents cross-instantiation reuse", async () => {
    // The tree was built with leafValue = Poseidon(pk, pk, 1).
    // The STATUS=2 circuit expects leafValue = Poseidon(pk, pk, 2).
    // The SMTVerifier will reject the proof because the leaf hashes diverge.
    const inputs = await buildProofInputs(activeSmt, alice.pubKey);

    let error;
    try {
      await frozenCircuit.calculateWitness(inputs, true);
    } catch (e) {
      error = e;
    }
    expect(error).to.not.be.undefined;
  });

  it("FROZEN identity with correct proof should pass STATUS=2 circuit", async () => {
    const inputs = await buildProofInputs(frozenSmt, alice.pubKey);

    let error;
    try {
      await frozenCircuit.calculateWitness(inputs, true);
    } catch (e) {
      error = e;
    }
    expect(error).to.be.undefined;
  });

  it("zero public key slot should bypass SMT check regardless of proof", async () => {
    // pubkey-zero gating: IsZero(pubKey[0]) == 1 → smtEnabled = 0 → SMTVerifier skipped.
    // We pass a zero-filled merkle proof; if the gating is broken the SMTVerifier
    // would try to verify a garbage proof and fail.
    const zeroPubKey = [0n, 0n];
    const zeroProof = Array(SMT_HEIGHT).fill(0n);
    const rootVal = (await activeSmt.root()).bigInt();

    let error;
    try {
      await activeCircuit.calculateWitness(
        {
          publicKeys: [zeroPubKey],
          root: rootVal,
          merkleProof: [zeroProof],
        },
        true,
      );
    } catch (e) {
      error = e;
    }
    expect(error).to.be.undefined;
  });

  it("tampered root should fail", async () => {
    const inputs = await buildProofInputs(activeSmt, alice.pubKey);
    // Corrupt the root by incrementing it
    inputs.root = inputs.root + 1n;

    let error;
    try {
      await activeCircuit.calculateWitness(inputs, true);
    } catch (e) {
      error = e;
    }
    expect(error).to.not.be.undefined;
  });
});
