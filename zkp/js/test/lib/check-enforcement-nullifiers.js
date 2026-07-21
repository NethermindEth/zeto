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

const ENF_DOMAIN_TAG = 21455947405572920533869930548514094044543253524099188107381343679564123236615n;

function computeEnforcementNullifier(ecdhPrivKey, counterpartyPubKey, commitment) {
  const shared = genEcdhSharedKey(ecdhPrivKey, counterpartyPubKey);
  const k0 = poseidon2([shared[0], shared[1]]);
  return poseidon3([commitment, k0, ENF_DOMAIN_TAG]);
}

describe("CheckEnforcementNullifiers circuit tests", () => {
  let circuit;
  const owner = {};
  const enforcer = {};

  before(async function () {
    this.timeout(60000);

    circuit = await wasm_tester(
      join(__dirname, "../circuits/check-enforcement-nullifiers.circom"),
    );

    let kp = genKeypair();
    owner.privKey = kp.privKey;
    owner.pubKey = kp.pubKey;
    owner.formattedKey = formatPrivKeyForBabyJub(owner.privKey);

    kp = genKeypair();
    enforcer.privKey = kp.privKey;
    enforcer.pubKey = kp.pubKey;
  });

  // ── helper: build two valid commitments and their enforcement nullifiers ──
  function makeInputs() {
    const c1 = poseidon4([100n, newSalt(), ...owner.pubKey]);
    const c2 = poseidon4([200n, newSalt(), ...owner.pubKey]);
    const n1 = computeEnforcementNullifier(owner.privKey, enforcer.pubKey, c1);
    const n2 = computeEnforcementNullifier(owner.privKey, enforcer.pubKey, c2);
    return {
      inputCommitments: [c1, c2],
      enforcementNullifiers: [n1, n2],
    };
  }

  it("all slots enabled with correct nullifiers should pass", async () => {
    const { inputCommitments, enforcementNullifiers } = makeInputs();

    let error;
    try {
      await circuit.calculateWitness(
        {
          enforcementNullifiers,
          inputCommitments,
          counterpartyPublicKey: enforcer.pubKey,
          ecdhKey: owner.formattedKey,
        },
        true,
      );
    } catch (e) {
      error = e;
    }
    expect(error).to.be.undefined;
  });

  it("should fail when one nullifier is tampered", async () => {
    const { inputCommitments, enforcementNullifiers } = makeInputs();

    // Flip a single bit in the first nullifier — any non-matching value suffices
    const tampered = [...enforcementNullifiers];
    tampered[0] = enforcementNullifiers[0] + 1n;

    let error;
    try {
      await circuit.calculateWitness(
        {
          enforcementNullifiers: tampered,
          inputCommitments,
          counterpartyPublicKey: enforcer.pubKey,
          ecdhKey: owner.formattedKey,
        },
        true,
      );
    } catch (e) {
      error = e;
    }
    expect(error).to.not.be.undefined;
  });

  it("disabled slot (nullifier == 0) should bypass the check regardless of commitment", async () => {
    const { inputCommitments, enforcementNullifiers } = makeInputs();

    // Disable slot 1 by zeroing its nullifier; commitment value is irrelevant.
    // If the bypass logic is broken the circuit would try to match 0 against the
    // derived nullifier (which is never 0 for a valid commitment) and fail.
    const withDisabled = [enforcementNullifiers[0], 0n];

    let error;
    try {
      await circuit.calculateWitness(
        {
          enforcementNullifiers: withDisabled,
          inputCommitments,
          counterpartyPublicKey: enforcer.pubKey,
          ecdhKey: owner.formattedKey,
        },
        true,
      );
    } catch (e) {
      error = e;
    }
    expect(error).to.be.undefined;
  });

  it("disabled slot with a non-zero but incorrect nullifier should fail", async () => {
    // nullifier != 0, so the IsZero bypass does NOT fire.
    // The circuit must then compare 1n against the derived nullifier → mismatch → fail.
    const { inputCommitments, enforcementNullifiers } = makeInputs();

    const withBadNonZero = [enforcementNullifiers[0], 1n];

    let error;
    try {
      await circuit.calculateWitness(
        {
          enforcementNullifiers: withBadNonZero,
          inputCommitments,
          counterpartyPublicKey: enforcer.pubKey,
          ecdhKey: owner.formattedKey,
        },
        true,
      );
    } catch (e) {
      error = e;
    }
    expect(error).to.not.be.undefined;
  });
});