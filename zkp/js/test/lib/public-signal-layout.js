// Copyright © 2025 Kaleido, Inc.
//
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
// Circom does NOT order public inputs by the `{ public [...] }` list — it orders
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

const ARTIFACTS =
  process.env.CIRCUITS_ROOT ||
  path.resolve(__dirname, "..", "..", "..", "artifacts");
const SOLIDITY = path.resolve(__dirname, "..", "..", "..", "..", "solidity");

// Expected public-signal order, index 1..nPublic, read off the compiled .sym.
// Regenerate with:
//   awk -F, '$2>=1 && $2<=<nPublic> {print $2"  "$4}' <circuit>.sym | sort -n -k1
// dims: null = scalar, N = N-element array, [R, C] = 2-D array.
const CIRCUITS = [
  {
    name: "anon_enc_nullifier_kyc_non_repudiation_enforced",
    piLenConstant: "PI_LEN_TRANSFER",
    nPublic: 58,
    layout: [
      ["ecdhPublicKey", 2],
      ["encryptedValuesForReceiver", [2, 4]],
      ["encryptedValuesForArbiter", 16],
      ["encryptedValuesForEnforcer", 16],
      ["ownerNullifiers", 2],
      ["enforcementNullifiers", 2],
      ["utxosRoot", null],
      ["enabledInputs", 2],
      ["identitiesRoot", null],
      ["complianceRoot", null],
      ["outputCommitments", 2],
      ["encryptionNonce", null],
      ["arbiterPublicKey", 2],
      ["enforcerPublicKey", 2],
    ],
  },
  {
    name: "deposit_kyc_non_repudiation_enforced",
    piLenConstant: "PI_LEN_DEPOSIT",
    nPublic: 52,
    layout: [
      ["out", null],
      ["ecdhPublicKey", 2],
      ["encryptedValuesForReceiver", [2, 4]],
      ["encryptedValuesForArbiter", 16],
      ["encryptedValuesForEnforcer", 16],
      ["outputCommitments", 2],
      ["identitiesRoot", null],
      ["complianceRoot", null],
      ["encryptionNonce", null],
      ["arbiterPublicKey", 2],
      ["enforcerPublicKey", 2],
    ],
  },
  {
    name: "withdraw_nullifier_kyc_enforced",
    piLenConstant: "PI_LEN_WITHDRAW",
    nPublic: 51,
    layout: [
      ["ecdhPublicKey", 2],
      ["encryptedValuesForArbiter", 16],
      ["encryptedValuesForEnforcer", 16],
      ["amount", null],
      ["ownerNullifiers", 2],
      ["enforcementNullifiers", 2],
      ["outputCommitments", 1],
      ["utxosRoot", null],
      ["identitiesRoot", null],
      ["complianceRoot", null],
      ["enabledInputs", 2],
      ["encryptionNonce", null],
      ["arbiterPublicKey", 2],
      ["enforcerPublicKey", 2],
      ["recipient", null],
    ],
  },
  {
    name: "forced_transfer_nullifier_kyc_enforced",
    piLenConstant: "PI_LEN_FORCED_TRANSFER",
    nPublic: 56,
    layout: [
      ["ecdhPublicKey", 2],
      ["encryptedValuesForReceiver", [2, 4]],
      ["encryptedValuesForArbiter", 16],
      ["encryptedValuesForEnforcer", 16],
      ["enforcementNullifiers", 2],
      ["outputCommitments", 2],
      ["utxosRoot", null],
      ["identitiesRoot", null],
      ["complianceRoot", null],
      ["enabledInputs", 2],
      ["enforcerPublicKey", 2],
      ["encryptionNonce", null],
      ["arbiterPublicKey", 2],
    ],
  },
];

// Flatten [name, dims] entries into the per-index signal names circom emits.
// dims is null for a scalar, a number for a 1-D array, or [rows, cols] for 2-D.
function expand(layout) {
  const names = [];
  for (const [name, dims] of layout) {
    if (dims === null) {
      names.push(`main.${name}`);
    } else if (Array.isArray(dims)) {
      for (let i = 0; i < dims[0]; i++) {
        for (let j = 0; j < dims[1]; j++)
          names.push(`main.${name}[${i}][${j}]`);
      }
    } else {
      for (let i = 0; i < dims; i++) names.push(`main.${name}[${i}]`);
    }
  }
  return names;
}

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

        const verifier = fs.readFileSync(
          path.join(
            SOLIDITY,
            "contracts",
            "verifiers",
            "impl",
            `${circuit.name}.sol`,
          ),
          "utf8",
        );
        const arity = verifier.match(/uint\[(\d+)\] calldata _pubSignals/);
        expect(arity, "verifier has no _pubSignals signature").to.not.be.null;
        expect(Number(arity[1])).to.equal(circuit.nPublic);

        const codec = fs.readFileSync(
          path.join(SOLIDITY, "contracts", "lib", "aenknre_codec.sol"),
          "utf8",
        );
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
