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

include "../node_modules/circomlib/circuits/comparators.circom";

// CheckEnabledInputs gives every input slot exactly one enable flag, and makes
// the rest of the slot follow it.
//
// Without this, each per-slot check keys off its own prover-chosen zero — a zero
// commitment skips CheckHashes, a zero nullifier skips CheckNullifiers, a zero
// enable flag skips the SMT inclusion proof — while the value sums are not gated
// at all. A slot can therefore be switched off at every check that could refuse
// it and still contribute its value, which mints tokens from nothing.
//
//   - check that enabled[i] is boolean
//   - check that commitments[i] is zero exactly when slot i is disabled
//   - check that values[i] is zero when slot i is disabled
//
// A slot that is enabled may still carry the value zero: a zero-value note is
// legitimate, so the value binding is one-directional by design.
template CheckEnabledInputs(nInputs) {
  signal input enabled[nInputs];
  signal input commitments[nInputs];
  signal input values[nInputs];

  for (var i = 0; i < nInputs; i++) {
    enabled[i] * (enabled[i] - 1) === 0;

    var isCommitmentZero;
    isCommitmentZero = IsZero()(in <== commitments[i]);
    isCommitmentZero === 1 - enabled[i];

    (1 - enabled[i]) * values[i] === 0;
  }
}

// CheckSlotTags binds a per-slot public tag — an owner nullifier, or any other
// value the chain relies on being published for a spent slot — to the same
// enable flag, so a live slot cannot suppress its tag.
//
//   - check that tags[i] is zero exactly when slot i is disabled
//
// Precondition: enabled[i] is boolean. CheckEnabledInputs establishes that, and
// every call site here runs it over the same flags.
template CheckSlotTags(nInputs) {
  signal input enabled[nInputs];
  signal input tags[nInputs];

  for (var i = 0; i < nInputs; i++) {
    var isTagZero;
    isTagZero = IsZero()(in <== tags[i]);
    isTagZero === 1 - enabled[i];
  }
}
