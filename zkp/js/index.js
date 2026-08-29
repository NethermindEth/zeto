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

const path = require('path');
const { readFileSync } = require('fs');
const Poseidon = require('poseidon-lite');
const {
  newSalt,
  newEncryptionNonce,
  poseidonDecrypt,
  encodeProof,
  getProofHash,
  tokenUriHash,
  kycHash,
  enforcementNullifier,
  ENFORCEMENT_NULLIFIER_DOMAIN_TAG,
  ENFORCEMENT_NULLIFIER_DOMAIN_TAG_PREIMAGE,
  bitsToBytes,
  bytesToBits,
  publicKeyFromSeed,
  recoverMlKemCiphertextBytes,
} = require('./lib/util.js');

function loadCircuit(type) {
  if (!type) {
    throw new Error('The circuit name must be provided');
  }
  const circuitsRoot = process.env.CIRCUITS_ROOT;
  if (!circuitsRoot) {
    throw new Error('CIRCUITS_ROOT is not set');
  }
  const WitnessCalculator = require(path.join(circuitsRoot, `${type}_js/witness_calculator.js`));
  const buffer = readFileSync(path.join(circuitsRoot, `${type}_js/${type}.wasm`));
  return WitnessCalculator(buffer);
}

module.exports = {
  loadCircuit,
  Poseidon,
  newSalt,
  newEncryptionNonce,
  tokenUriHash,
  kycHash,
  enforcementNullifier,
  ENFORCEMENT_NULLIFIER_DOMAIN_TAG,
  ENFORCEMENT_NULLIFIER_DOMAIN_TAG_PREIMAGE,
  poseidonDecrypt,
  encodeProof,
  getProofHash,
  bitsToBytes,
  bytesToBits,
  publicKeyFromSeed,
  recoverMlKemCiphertextBytes,
};
