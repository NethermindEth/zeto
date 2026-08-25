// Copyright © 2024 Kaleido, Inc.
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

const path = require("path");
const { readFileSync } = require("fs");
const { expect } = require("chai");
const { groth16 } = require("snarkjs");

function provingKeysRoot() {
  const PROVING_KEYS_ROOT = process.env.PROVING_KEYS_ROOT;
  if (!PROVING_KEYS_ROOT) {
    throw new Error("PROVING_KEYS_ROOT env var is not set");
  }
  return PROVING_KEYS_ROOT;
}

function circuitsRoot() {
  const CIRCUITS_ROOT = process.env.CIRCUITS_ROOT;
  if (!CIRCUITS_ROOT) {
    throw new Error("CIRCUITS_ROOT env var is not set");
  }
  return CIRCUITS_ROOT;
}

function loadProvingKeys(type) {
  const provingKeyFile = path.join(provingKeysRoot(), `${type}.zkey`);
  const verificationKey = JSON.parse(
    new TextDecoder().decode(
      readFileSync(path.join(provingKeysRoot(), `${type}-vkey.json`)),
    ),
  );
  return {
    provingKeyFile,
    wasmFile: path.join(circuitsRoot(), `${type}_js/${type}.wasm`),
    verificationKey,
  };
}

// BN254 scalar field modulus. The generated verifiers call it `r` and
// lib/util.js calls it `F`; it is the scalar field, not the base field, so
// `BN254_P` — the name the proving tests used — is the one name that is wrong.
const R =
  21888242871839275222246405745257275088548364400416034343698204186575808495617n;

// Asserts that every public signal is bound by the verification key rather than
// merely published. A signal declared public but constrained by nothing gets an
// identity IC point and is therefore free to move, which neither the witness
// suite nor the Solidity suite would notice.
//
// `names` comes from test/lib/aenknre-signal-layout.js, which
// test/lib/public-signal-layout.js checks against the compiled .sym, so the
// failure message names the signal that actually moved.
async function expectEveryPublicSignalBound(
  verificationKey,
  publicSignals,
  proof,
  names,
) {
  for (let i = 0; i < publicSignals.length; i++) {
    const swept = publicSignals.slice();
    swept[i] = ((BigInt(swept[i]) + 1n) % R).toString();
    expect(
      await groth16.verify(verificationKey, swept, proof),
      `signal ${i} (${names[i]}) is not bound by the verification key`,
    ).to.be.false;
  }
}

module.exports = { loadProvingKeys, expectEveryPublicSignalBound, R };
