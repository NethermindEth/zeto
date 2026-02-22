const { expect } = require("chai");
const { join } = require("path");
const { wasm: wasm_tester } = require("circom_tester");
const {
  genKeypair,
  genEcdhSharedKey,
  formatPrivKeyForBabyJub,
} = require("maci-crypto");
const { Poseidon, newSalt } = require("../../index.js");

const poseidon2 = Poseidon.poseidon2;
const poseidon3 = Poseidon.poseidon3;
const poseidon4 = Poseidon.poseidon4;

// Must match the ENF_DOMAIN_TAG constant in enforcement_nullifier.circom:
//   keccak256("zeto.enforcement.nullifier.v1") mod p
const ENF_DOMAIN_TAG = 21455947405572920533869930548514094044543253524099188107381343679564123236615n;

// Reproduce the in-circuit derivation in JS.
function computeEnforcementNullifier(ecdhPrivKey, counterpartyPubKey, commitment) {
  const shared = genEcdhSharedKey(ecdhPrivKey, counterpartyPubKey);
  const k0 = poseidon2([shared[0], shared[1]]);
  return poseidon3([commitment, k0, ENF_DOMAIN_TAG]);
}

describe("EnforcementNullifier circuit tests", () => {
  let circuit;
  const owner = {};
  const enforcer = {};

  before(async function () {
    this.timeout(60000);

    circuit = await wasm_tester(
      join(__dirname, "../circuits/enforcement_nullifier.circom"),
    );

    let kp = genKeypair();
    owner.privKey = kp.privKey;
    owner.pubKey = kp.pubKey;
    owner.formattedKey = formatPrivKeyForBabyJub(owner.privKey);

    kp = genKeypair();
    enforcer.privKey = kp.privKey;
    enforcer.pubKey = kp.pubKey;
    enforcer.formattedKey = formatPrivKeyForBabyJub(enforcer.privKey);
  });

  it("owner path: should produce the correct enforcement nullifier", async () => {
    const commitment = poseidon4([100n, newSalt(), ...owner.pubKey]);

    const witness = await circuit.calculateWitness(
      {
        inputCommitment: commitment,
        counterpartyPublicKey: enforcer.pubKey,
        ecdhKey: owner.formattedKey,
      },
      true,
    );

    const expected = computeEnforcementNullifier(
      owner.privKey,
      enforcer.pubKey,
      commitment,
    );

    // witness[1] is the single output signal `out`
    expect(witness[1]).to.equal(expected);
  });

  it("DH symmetry: enforcer path should produce the same nullifier as the owner path", async () => {
    const commitment = poseidon4([50n, newSalt(), ...owner.pubKey]);

    // Owner computes with their key against enforcer's public key
    const ownerWitness = await circuit.calculateWitness(
      {
        inputCommitment: commitment,
        counterpartyPublicKey: enforcer.pubKey,
        ecdhKey: owner.formattedKey,
      },
      true,
    );

    // Enforcer computes with their key against owner's public key
    const enforcerWitness = await circuit.calculateWitness(
      {
        inputCommitment: commitment,
        counterpartyPublicKey: owner.pubKey,
        ecdhKey: enforcer.formattedKey,
      },
      true,
    );

    // ECDH(ownerKey, enforcerPub) == ECDH(enforcerKey, ownerPub) — DH symmetry
    expect(ownerWitness[1]).to.equal(enforcerWitness[1]);
  });

  it("different commitment should produce a different nullifier", async () => {
    const salt = newSalt();
    const commitment1 = poseidon4([100n, salt, ...owner.pubKey]);
    const commitment2 = poseidon4([200n, salt, ...owner.pubKey]);

    const w1 = await circuit.calculateWitness(
      {
        inputCommitment: commitment1,
        counterpartyPublicKey: enforcer.pubKey,
        ecdhKey: owner.formattedKey,
      },
      true,
    );
    const w2 = await circuit.calculateWitness(
      {
        inputCommitment: commitment2,
        counterpartyPublicKey: enforcer.pubKey,
        ecdhKey: owner.formattedKey,
      },
      true,
    );

    expect(w1[1]).to.not.equal(w2[1]);
  });

  it("different domain tag should produce a different nullifier (domain separation check)", async () => {
    const commitment = poseidon4([75n, newSalt(), ...owner.pubKey]);

    const witness = await circuit.calculateWitness(
      {
        inputCommitment: commitment,
        counterpartyPublicKey: enforcer.pubKey,
        ecdhKey: owner.formattedKey,
      },
      true,
    );

    // Compute what the nullifier would be with an incorrect domain tag
    const shared = genEcdhSharedKey(owner.privKey, enforcer.pubKey);
    const k0 = poseidon2([shared[0], shared[1]]);
    const wrongTagNullifier = poseidon3([commitment, k0, 0n]);

    // The circuit output (using ENF_DOMAIN_TAG) must differ from the wrong-tag value
    expect(witness[1]).to.not.equal(wrongTagNullifier);
    // And it must match the correctly-tagged JS computation
    const correct = computeEnforcementNullifier(owner.privKey, enforcer.pubKey, commitment);
    expect(witness[1]).to.equal(correct);
  });
});