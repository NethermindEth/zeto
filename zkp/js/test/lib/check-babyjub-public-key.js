const { expect } = require("chai");
const { join } = require("path");
const { wasm: wasm_tester } = require("circom_tester");
const { genKeypair } = require("maci-crypto");

describe("CheckBabyJubPublicKey circuit tests", () => {
  let circuit;

  before(async function () {
    this.timeout(60000);

    circuit = await wasm_tester(
      join(__dirname, "../circuits/check-babyjub-public-key.circom"),
    );
  });

  it("should accept a valid on-curve prime-order public key", async () => {
    // genKeypair() always produces a BabyJub prime-order point
    const { pubKey } = genKeypair();

    let error;
    try {
      await circuit.calculateWitness({ publicKey: pubKey }, true);
    } catch (e) {
      error = e;
    }
    expect(error).to.be.undefined;
  });

  it("should reject an off-curve point", async () => {
    // (1, 1) does not satisfy the BabyJub equation:
    //   168700*1 + 1 = 168701  ≠  1 + 168696*1 = 168697
    const offCurvePoint = [1n, 1n];

    let error;
    try {
      await circuit.calculateWitness({ publicKey: offCurvePoint }, true);
    } catch (e) {
      error = e;
    }
    expect(error).to.not.be.undefined;
  });

  it("should reject the BabyJub identity point", async () => {
    // The additive identity (0, 1) satisfies the curve equation:
    //   168700*0 + 1 = 1  =  1 + 168696*0 = 1  ✓
    // so BabyCheck alone accepts it. This used to be asserted as expected
    // behaviour. It is not: every consumer of a key reads x == 0 as something
    // else — Kyc and ComplianceStatus as "slot disabled", EscalarMulAny as
    // "use the Base8 generator" — so the key silently disables the checks that
    // were supposed to guard it.
    const identity = [0n, 1n];

    let error;
    try {
      await circuit.calculateWitness({ publicKey: identity }, true);
    } catch (e) {
      error = e;
    }
    expect(error).to.not.be.undefined;
  });

  it("should reject the 2-torsion point", async () => {
    // (0, p-1) is the only other curve point with x == 0, and carries the same
    // three misreadings.
    const FIELD_P =
      21888242871839275222246405745257275088548364400416034343698204186575808495617n;
    const twoTorsion = [0n, FIELD_P - 1n];

    let error;
    try {
      await circuit.calculateWitness({ publicKey: twoTorsion }, true);
    } catch (e) {
      error = e;
    }
    expect(error).to.not.be.undefined;
  });
});
