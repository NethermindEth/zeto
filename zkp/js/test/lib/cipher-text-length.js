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

// The wrapper evaluates the function for every plaintext length from 0 to this
// bound and exposes the results as its outputs.
const MAX_PLAIN_TEXT_LENGTH = 16;

// The length the four AENKNR-E circuits pass to SymmetricEncrypt, and the arity
// their arbiter and enforcer ciphertext outputs are declared with.
const AUTHORITY_PLAINTEXT_LENGTH = 14;
const AUTHORITY_CIPHER_TEXT_LENGTH = 16;

// Rounds up to a multiple of three, then adds the authentication tag. Written
// independently of the circom implementation so the test compares two
// derivations rather than restating one.
function expectedCipherTextLength(plainTextLength) {
  return 3 * Math.ceil(plainTextLength / 3) + 1;
}

describe("cipher-text-length circuit tests", () => {
  let circuit;
  let witness;

  before(async function () {
    this.timeout(60000);

    circuit = await wasm_tester(
      join(__dirname, "../circuits/cipher-text-length.circom"),
    );
    witness = await circuit.calculateWitness({}, true);
    await circuit.checkConstraints(witness);
  });

  // Witness index 0 holds the constant one, and the outputs follow in order.
  function lengthFor(plainTextLength) {
    return witness[1 + plainTextLength];
  }

  it("should emit one authentication tag for an empty plaintext", async () => {
    expect(lengthFor(0)).to.equal(1n);
  });

  it("should match an independent derivation across every residue class", async () => {
    for (let i = 0; i <= MAX_PLAIN_TEXT_LENGTH; i++) {
      expect(lengthFor(i)).to.equal(BigInt(expectedCipherTextLength(i)));
    }
  });

  it("should leave a plaintext that already fills whole blocks unpadded", async () => {
    for (let i = 0; i <= MAX_PLAIN_TEXT_LENGTH; i += 3) {
      expect(lengthFor(i)).to.equal(BigInt(i + 1));
    }
  });

  it("should size the authority ciphertext the AENKNR-E circuits declare", async () => {
    expect(lengthFor(AUTHORITY_PLAINTEXT_LENGTH)).to.equal(
      BigInt(AUTHORITY_CIPHER_TEXT_LENGTH),
    );
  });
});
