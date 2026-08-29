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

include "./check-babyjub-public-key.circom";
include "../node_modules/circomlib/circuits/comparators.circom";

// CheckOutputSlots settles what a disabled output slot may carry, and hands
// back one enable flag per slot for the checks that follow it.
//
// An output slot is disabled by publishing a zero commitment, which is the same
// signal Kyc and ComplianceStatus read when they skip a slot. Left alone, such
// a slot still reaches the value sum and still presents an owner key that no
// curve check ever saw. Its value then balances conservation while no note
// records where it went, and its key may be an off-curve pair or one of the two
// curve points whose x coordinate is zero, which every consumer of a key
// misreads. Deriving the flag once and applying both checks against it closes
// that gap in one place for every circuit that mints outputs.
//
//   - check that a disabled slot carries no value
//   - check that every output owner key lies on the BabyJubJub curve and has a
//     non-zero x coordinate
//
// A disabled slot has no key of its own and its raw pair may be (0, 0), which
// is not on the curve, so it is padded with the BabyJubJub generator. The
// padding is a genuine prime-order point, so it satisfies the same check a live
// key does instead of side-stepping it.
//
// `enabled[i]` is 1 exactly when slot i carries a non-zero commitment. A caller
// masks the slot's prover-chosen fields with it before they reach the identity,
// compliance and authority-audit paths, where a field belonging to no note
// would otherwise be read as belonging to one.
template CheckOutputSlots(nOutputs) {
  signal input outputCommitments[nOutputs];
  signal input outputValues[nOutputs];
  signal input outputOwnerPublicKeys[nOutputs][2];

  signal output enabled[nOutputs];

  var isCommitmentZero[nOutputs];
  for (var i = 0; i < nOutputs; i++) {
    isCommitmentZero[i] = IsZero()(in <== outputCommitments[i]);
    enabled[i] <== 1 - isCommitmentZero[i];
  }

  for (var i = 0; i < nOutputs; i++) {
    isCommitmentZero[i] * outputValues[i] === 0;
  }

  for (var i = 0; i < nOutputs; i++) {
    var checkedKey[2];
    checkedKey[0] = enabled[i] * outputOwnerPublicKeys[i][0] + isCommitmentZero[i] * BabyJubBase8X();
    checkedKey[1] = enabled[i] * outputOwnerPublicKeys[i][1] + isCommitmentZero[i] * BabyJubBase8Y();
    CheckBabyJubPublicKey()(publicKey <== checkedKey);
  }
}
