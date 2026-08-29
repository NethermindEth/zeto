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

describe("CheckEnabledInputs circuit tests", () => {
  let circuit;
  const owner = {};

  before(async function () {
    this.timeout(60000);
    circuit = await wasm_tester(
      join(__dirname, "../circuits/check-enabled-inputs.circom"),
    );
    const kp = genKeypair();
    owner.pubKey = kp.pubKey;
  });

  function commitment(value) {
    return poseidon4([value, newSalt(), ...owner.pubKey]);
  }

  it("two live slots carrying value should pass", async () => {
    expect(
      await accepts(circuit, {
        enabled: [1, 1],
        commitments: [commitment(100n), commitment(200n)],
        values: [100n, 200n],
      }),
    ).to.be.true;
  });

  it("a disabled slot with a zero commitment and zero value should pass", async () => {
    expect(
      await accepts(circuit, {
        enabled: [1, 0],
        commitments: [commitment(100n), 0n],
        values: [100n, 0n],
      }),
    ).to.be.true;
  });

  it("an enabled slot may carry the value zero", async () => {
    // The value binding is one-directional by design: a zero-value note is
    // legitimate, so only a disabled slot is forced to zero.
    expect(
      await accepts(circuit, {
        enabled: [1, 1],
        commitments: [commitment(100n), commitment(0n)],
        values: [100n, 0n],
      }),
    ).to.be.true;
  });

  it("a disabled slot may not contribute value", async () => {
    // This is the mint-from-nothing case the gadget exists for: every per-slot
    // check keys off its own zero, so a slot switched off everywhere that could
    // refuse it would still be summed.
    expect(
      await accepts(circuit, {
        enabled: [1, 0],
        commitments: [commitment(100n), 0n],
        values: [100n, 200n],
      }),
    ).to.be.false;
  });

  it("a disabled slot may not carry a commitment", async () => {
    expect(
      await accepts(circuit, {
        enabled: [1, 0],
        commitments: [commitment(100n), commitment(200n)],
        values: [100n, 0n],
      }),
    ).to.be.false;
  });

  it("an enabled slot may not zero its commitment", async () => {
    expect(
      await accepts(circuit, {
        enabled: [1, 1],
        commitments: [commitment(100n), 0n],
        values: [100n, 200n],
      }),
    ).to.be.false;
  });

  it("the enable flag must be boolean", async () => {
    expect(
      await accepts(circuit, {
        enabled: [1, 2],
        commitments: [commitment(100n), commitment(200n)],
        values: [100n, 200n],
      }),
    ).to.be.false;
  });
});

describe("CheckSlotTags circuit tests", () => {
  let circuit;

  before(async function () {
    this.timeout(60000);
    circuit = await wasm_tester(
      join(__dirname, "../circuits/check-slot-tags.circom"),
    );
  });

  it("a live slot publishing its tag should pass", async () => {
    expect(await accepts(circuit, { enabled: [1, 1], tags: [7n, 9n] })).to.be
      .true;
  });

  it("a disabled slot carrying a zero tag should pass", async () => {
    expect(await accepts(circuit, { enabled: [1, 0], tags: [7n, 0n] })).to.be
      .true;
  });

  it("a live slot may not suppress its tag", async () => {
    expect(await accepts(circuit, { enabled: [1, 1], tags: [7n, 0n] })).to.be
      .false;
  });

  it("a disabled slot may not publish a tag", async () => {
    expect(await accepts(circuit, { enabled: [1, 0], tags: [7n, 9n] })).to.be
      .false;
  });
});
