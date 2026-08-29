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
pragma circom 2.2.2;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/comparators.circom";
include "../node_modules/circomlib/circuits/smt/smtverifier.circom";

// ComplianceStatus verifies that each identity in a batch holds a specific
// compliance status in the compliance Sparse Merkle Tree.
//
// Leaf encoding (off-chain service calls addLeaf(leafKey, leafValue)):
//   leafKey   = Poseidon(2)([pubKeyX, pubKeyY])
//   leafValue = Poseidon(3)([pubKeyX, pubKeyY, STATUS])
//
// STATUS is a compile-time template parameter, never a runtime signal.
// This prevents a prover from supplying a different status value while
// reusing a structurally valid proof from a different STATUS instantiation.
//   STATUS = 1 -> ACTIVE
//   STATUS = 2 -> FROZEN
//
// Zero public key -> SMT check is disabled (same pubkey-zero gating as kyc.circom).
// UNKNOWN identities (absent from the tree) cannot produce a valid inclusion
// proof, so they are automatically rejected without any exclusion-proof path.
template ComplianceStatus(nIdentities, nComplianceSMTLevels, STATUS) {
  signal input publicKeys[nIdentities][2];
  signal input root;
  signal input merkleProof[nIdentities][nComplianceSMTLevels];

  for (var i = 0; i < nIdentities; i++) {
    var leafKey;
    leafKey = Poseidon(2)(inputs <== [publicKeys[i][0], publicKeys[i][1]]);

    var leafValue;
    leafValue = Poseidon(3)(inputs <== [publicKeys[i][0], publicKeys[i][1], STATUS]);

    var isPubKeyZero;
    isPubKeyZero = IsZero()(in <== publicKeys[i][0]);

    var smtEnabled = 1 - isPubKeyZero;

    var siblings[nComplianceSMTLevels];
    for (var j = 0; j < nComplianceSMTLevels; j++) {
      siblings[j] = merkleProof[i][j];
    }

    SMTVerifier(nComplianceSMTLevels)(
      enabled   <== smtEnabled,
      root      <== root,
      siblings  <== siblings,
      key       <== leafKey,
      value     <== leafValue,
      fnc       <== 0,    // 0 = inclusion proof
      oldKey    <== 0,
      oldValue  <== 0,
      isOld0    <== 0
    );
  }
}