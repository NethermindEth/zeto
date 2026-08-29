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
const { join } = require("path");
const { wasm: wasm_tester } = require("circom_tester");
const { genKeypair } = require("maci-crypto");
const { Poseidon, newSalt } = require("../../index.js");

const poseidon4 = Poseidon.poseidon4;

// A pair that fails the twisted-Edwards equation, so it lies on no curve point.
const OFF_CURVE_KEY = [1n, 1n];

// The curve identity. It satisfies the curve equation, so BabyCheck alone
// accepts it, and its zero x coordinate is what Kyc, ComplianceStatus and
// EscalarMulAny each misread.
const IDENTITY_KEY = [0n, 1n];

// A disabled slot publishes a zero commitment and no key of its own.
const DISABLED_KEY = [0n, 0n];

// Runs the wrapper and reports whether the constraint system accepted the
// assignment, so each case reads as one expectation rather than a try/catch.
async function accepts(circuit, inputs) {
  try {
    const witness = await circuit.calculateWitness(inputs, true);
    await circuit.checkConstraints(witness);
    return true;
  } catch (e) {
    return false;
  }
}

describe("CheckOutputSlots circuit tests", () => {
  let circuit;
  const owner = {};

  before(async function () {
    this.timeout(60000);

    circuit = await wasm_tester(
      join(__dirname, "../circuits/check-output-slots.circom"),
    );
    const kp = genKeypair();
    owner.pubKey = kp.pubKey.map((c) => BigInt(c));
  });

  function commitment(value) {
    return poseidon4([value, newSalt(), ...owner.pubKey]);
  }

  it("two live slots should pass and report both as enabled", async () => {
    const witness = await circuit.calculateWitness(
      {
        outputCommitments: [commitment(100n), commitment(200n)],
        outputValues: [100n, 200n],
        outputOwnerPublicKeys: [owner.pubKey, owner.pubKey],
      },
      true,
    );
    await circuit.checkConstraints(witness);
    // Witness index 0 holds the constant one, and `enabled` is the only output.
    expect(witness[1]).to.equal(1n);
    expect(witness[2]).to.equal(1n);
  });

  it("a disabled slot should pass and report as disabled", async () => {
    const witness = await circuit.calculateWitness(
      {
        outputCommitments: [commitment(100n), 0n],
        outputValues: [100n, 0n],
        outputOwnerPublicKeys: [owner.pubKey, DISABLED_KEY],
      },
      true,
    );
    await circuit.checkConstraints(witness);
    expect(witness[1]).to.equal(1n);
    expect(witness[2]).to.equal(0n);
  });

  it("a disabled slot may not carry value", async () => {
    // Without this the slot's value still balances the conservation sum while
    // nothing records where it went.
    expect(
      await accepts(circuit, {
        outputCommitments: [commitment(100n), 0n],
        outputValues: [100n, 200n],
        outputOwnerPublicKeys: [owner.pubKey, DISABLED_KEY],
      }),
    ).to.be.false;
  });

  it("a live slot may not carry an off-curve owner key", async () => {
    expect(
      await accepts(circuit, {
        outputCommitments: [commitment(100n), commitment(200n)],
        outputValues: [100n, 200n],
        outputOwnerPublicKeys: [owner.pubKey, OFF_CURVE_KEY],
      }),
    ).to.be.false;
  });

  it("a live slot may not carry an owner key whose x coordinate is zero", async () => {
    // The curve check alone accepts the identity. Kyc and ComplianceStatus then
    // treat the slot as disabled, and EscalarMulAny substitutes the generator,
    // so the key has to be refused here.
    expect(
      await accepts(circuit, {
        outputCommitments: [commitment(100n), commitment(200n)],
        outputValues: [100n, 200n],
        outputOwnerPublicKeys: [owner.pubKey, IDENTITY_KEY],
      }),
    ).to.be.false;
  });

  it("a disabled slot may carry any owner key", async () => {
    // The generator padding is what lets the pair (0, 0) through, and it stands
    // in for whatever the prover supplied. The masking a caller applies to a
    // disabled slot's key is what keeps that key out of the paths downstream.
    expect(
      await accepts(circuit, {
        outputCommitments: [commitment(100n), 0n],
        outputValues: [100n, 0n],
        outputOwnerPublicKeys: [owner.pubKey, OFF_CURVE_KEY],
      }),
    ).to.be.true;
  });

  it("a live slot may carry the value zero", async () => {
    // Only a disabled slot is forced to zero; a zero-value note is
    // legitimate.
    expect(
      await accepts(circuit, {
        outputCommitments: [commitment(100n), commitment(0n)],
        outputValues: [100n, 0n],
        outputOwnerPublicKeys: [owner.pubKey, owner.pubKey],
      }),
    ).to.be.true;
  });
});
