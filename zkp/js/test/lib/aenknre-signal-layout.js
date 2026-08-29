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

// The AENKNR-E public-signal layout, as one table.
//
// Circom does not order public inputs by the `{ public [...] }` list — it orders
// them by declaration order in the template. A hand-written ordering snapshot is
// therefore untrustworthy, and one in the transfer suite was in fact wrong: it
// placed outputCommitments where utxosRoot actually sits.
//
// This module is the single declaration of that order. `public-signal-layout.js`
// checks it against the compiled `.sym`, against the generated verifier's
// `_pubSignals` arity and against `PI_LEN_*` in
// `solidity/contracts/lib/aenknre_codec.sol`; the witness suites and the proving
// suites index into it rather than counting positions by hand.
//
// It is a plain module rather than a mocha spec so that both kinds of suite can
// require it.

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

// Returns the table entry for a circuit, by its registered name.
function circuitFor(name) {
  const circuit = CIRCUITS.find((c) => c.name === name);
  if (!circuit) {
    throw new Error(`no AENKNR-E signal layout declared for "${name}"`);
  }
  return circuit;
}

// The per-index public-signal names for a circuit, in order. `publicSignals[i]`
// is `signalNames(name)[i]`; the same signal is `witness[i + 1]`, because
// `witness[0]` is the constant 1.
function signalNames(name) {
  return expand(circuitFor(name).layout).map((n) => n.replace(/^main\./, ""));
}

// The 0-based index of a signal within `publicSignals`. `signal` is a flat name
// as `signalNames` produces it, so an array element is `"ownerNullifiers[1]"`.
function publicSignalIndex(name, signal) {
  const index = signalNames(name).indexOf(signal);
  if (index < 0) {
    throw new Error(`"${signal}" is not a public signal of "${name}"`);
  }
  return index;
}

// The index of a signal within the witness vector, which leads with the
// constant 1.
function witnessIndex(name, signal) {
  return publicSignalIndex(name, signal) + 1;
}

module.exports = {
  CIRCUITS,
  expand,
  circuitFor,
  signalNames,
  publicSignalIndex,
  witnessIndex,
};
