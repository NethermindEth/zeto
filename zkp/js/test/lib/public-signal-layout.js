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

// The durable control for the AENKNR-E public-signal layout.
//
// Circom does not order public inputs by the `{ public [...] }` list — it orders
// them by declaration order in the template. A hand-written ordering snapshot is
// therefore untrustworthy, and one in the transfer suite was in fact wrong: it
// placed outputCommitments where utxosRoot actually sits. This test reads the
// order back out of the compiled `.sym`, so a circuit change that shifts a public
// signal fails here rather than silently repointing a contract field.
//
// It also pins the three numbers that must agree at the contract boundary:
//   circuit nPublic == generated verifier `_pubSignals` arity == PI_LEN_* in
//   solidity/contracts/lib/aenknre_codec.sol

const { expect } = require("chai");
const fs = require("fs");
const path = require("path");
const readline = require("readline");
const { CIRCUITS, expand } = require("./aenknre-signal-layout.js");

const ARTIFACTS =
  process.env.CIRCUITS_ROOT ||
  path.resolve(__dirname, "..", "..", "..", "artifacts");
const SOLIDITY = path.resolve(__dirname, "..", "..", "..", "..", "solidity");

// Read the public range (witness index 1..nPublic) out of a .sym file. The files
// run to tens of megabytes, so this streams rather than reading them whole.
async function readPublicRange(symPath, nPublic) {
  const found = new Array(nPublic + 1);
  const rl = readline.createInterface({
    input: fs.createReadStream(symPath),
    crlfDelay: Infinity,
  });
  for await (const line of rl) {
    const parts = line.split(",");
    if (parts.length < 4) continue;
    const witnessIndex = Number(parts[1]);
    if (witnessIndex >= 1 && witnessIndex <= nPublic) {
      // a witness index can carry several labels; the first is the signal itself
      if (found[witnessIndex] === undefined) {
        found[witnessIndex] = parts.slice(3).join(",");
      }
    }
  }
  return found;
}

describe("AENKNR-E public signal layout", () => {
  for (const circuit of CIRCUITS) {
    describe(circuit.name, () => {
      const symPath = path.join(ARTIFACTS, `${circuit.name}.sym`);
      const vkeyPath = path.join(ARTIFACTS, `${circuit.name}-vkey.json`);
      const verifierPath = path.join(
        SOLIDITY,
        "contracts",
        "verifiers",
        "impl",
        `${circuit.name}.sol`,
      );
      const codecPath = path.join(
        SOLIDITY,
        "contracts",
        "lib",
        "aenknre_codec.sol",
      );

      // The circuit artifacts are gitignored build output and the two Solidity
      // files arrive later in the stack, so each test skips on what it reads
      // rather than failing with ENOENT on a file that is legitimately absent.
      before(function () {
        if (!fs.existsSync(symPath) || !fs.existsSync(vkeyPath)) {
          this.skip();
        }
      });

      it("the compiled .sym public range matches the declared layout", async function () {
        this.timeout(60000);
        const actual = await readPublicRange(symPath, circuit.nPublic);
        const expected = expand(circuit.layout);
        expect(expected.length).to.equal(
          circuit.nPublic,
          "declared layout does not add up to nPublic",
        );
        for (let i = 1; i <= circuit.nPublic; i++) {
          expect(actual[i]).to.equal(
            expected[i - 1],
            `public signal ${i} is ${actual[i]}, declared ${expected[i - 1]}`,
          );
        }
      });

      it("nPublic, the verifier arity and the codec constant all agree", function () {
        const vkey = JSON.parse(fs.readFileSync(vkeyPath, "utf8"));
        expect(vkey.nPublic).to.equal(circuit.nPublic);

        if (!fs.existsSync(verifierPath) || !fs.existsSync(codecPath)) {
          this.skip();
        }

        const verifier = fs.readFileSync(verifierPath, "utf8");
        const arity = verifier.match(/uint\[(\d+)\] calldata _pubSignals/);
        expect(arity, "verifier has no _pubSignals signature").to.not.be.null;
        expect(Number(arity[1])).to.equal(circuit.nPublic);

        const codec = fs.readFileSync(codecPath, "utf8");
        const constant = codec.match(
          new RegExp(`${circuit.piLenConstant}\\s*=\\s*(\\d+)`),
        );
        expect(constant, `codec has no ${circuit.piLenConstant}`).to.not.be
          .null;
        expect(Number(constant[1])).to.equal(circuit.nPublic);
      });
    });
  }
});
