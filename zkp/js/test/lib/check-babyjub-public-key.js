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

  it("should accept the BabyJub identity point (BabyCheck validates curve membership, not subgroup order)", async () => {
    // The additive identity (0, 1) satisfies the curve equation:
    //   168700*0 + 1 = 1  =  1 + 168696*0 = 1  ✓
    // BabyCheck enforces only the curve equation; it does NOT reject low-order
    // points such as this identity or the 2-torsion point (0, p-1).
    // This is expected behaviour — see the comment in check-babyjub-public-key.circom.
    const identity = [0n, 1n];

    let error;
    try {
      await circuit.calculateWitness({ publicKey: identity }, true);
    } catch (e) {
      error = e;
    }
    expect(error).to.be.undefined;
  });
});
