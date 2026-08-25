const { expect } = require("chai");
const { join } = require("path");
const { wasm: wasm_tester } = require("circom_tester");
const {
  genKeypair,
  genEcdhSharedKey,
  formatPrivKeyForBabyJub,
} = require("maci-crypto");
const { ethers } = require("ethers");
const {
  Poseidon,
  newSalt,
  enforcementNullifier,
  ENFORCEMENT_NULLIFIER_DOMAIN_TAG,
  ENFORCEMENT_NULLIFIER_DOMAIN_TAG_PREIMAGE,
} = require("../../index.js");

const poseidon2 = Poseidon.poseidon2;
const poseidon3 = Poseidon.poseidon3;
const poseidon4 = Poseidon.poseidon4;

// BN254 scalar field modulus.
const FIELD_P =
  21888242871839275222246405745257275088548364400416034343698204186575808495617n;

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

    const expected = enforcementNullifier(
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

    // The circuit output (using ENFORCEMENT_NULLIFIER_DOMAIN_TAG) must differ from the wrong-tag value
    expect(witness[1]).to.not.equal(wrongTagNullifier);
    // And it must match the correctly-tagged JS computation
    const correct = enforcementNullifier(
      owner.privKey,
      enforcer.pubKey,
      commitment,
    );
    expect(witness[1]).to.equal(correct);
  });

  it("the domain tag is keccak256 of its documented preimage, reduced mod p", () => {
    // P3-13 / D-2: the tag is what separates an enforcement nullifier from an
    // owner nullifier of the same arity. Nothing derived it from the string it
    // is documented to come from, so a typo in either would have gone unnoticed
    // and the two nullifier families could collide.
    const derived =
      BigInt(
        ethers.keccak256(
          ethers.toUtf8Bytes(ENFORCEMENT_NULLIFIER_DOMAIN_TAG_PREIMAGE),
        ),
      ) % FIELD_P;
    expect(derived).to.equal(ENFORCEMENT_NULLIFIER_DOMAIN_TAG);
  });
});
