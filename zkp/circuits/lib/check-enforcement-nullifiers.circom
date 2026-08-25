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

include "./check-non-zero.circom";
include "./enforcement-nullifier.circom";

// CheckEnforcementNullifiers validates that each public enforcement nullifier
// in a batch is correctly derived from its corresponding input commitment via ECDH.
//
//   - check that enforcementNullifiers[i] is the derived tag when slot i is
//     enabled, and zero when it is disabled
//
// The slot is gated by the caller's enable flag, not by the tag being zero.
// Reading "tag == 0" as "slot disabled" let a prover consume a real note while
// publishing no tag, which is the only thing that stops the note being spent
// again on the other nullifier domain.
//
// inputCommitments must be the same preimage array used for UTXO SMT inclusion
// so that the enforcement nullifier is provably bound to the same note.
//
// Precondition: enabled[i] is boolean — CheckEnabledInputs establishes that at
// the call site.
template CheckEnforcementNullifiers(nInputs) {
  signal input enforcementNullifiers[nInputs];
  signal input inputCommitments[nInputs];
  signal input counterpartyPublicKey[2];
  // The caller's private key, already formatted for BabyJub
  // (formatPrivKeyForBabyJub applied on the JS side).
  signal input ecdhKey;
  signal input enabled[nInputs];

  // The shared ECDH key depends only on (ecdhKey, counterpartyPublicKey), which
  // are the same for every slot, so it is derived once rather than per slot.
  // A zero ECDH scalar makes the shared secret the curve identity, so every tag
  // in the batch would be derivable from public data alone.
  CheckNonZero()(in <== ecdhKey);

  signal k0;
  k0 <== EnforcementNullifierKey()(
    counterpartyPublicKey <== counterpartyPublicKey,
    ecdhKey <== ecdhKey
  );

  for (var i = 0; i < nInputs; i++) {
    var calculatedNullifier;
    calculatedNullifier = EnforcementNullifierFromKey()(
      inputCommitment <== inputCommitments[i],
      k0 <== k0
    );

    // enabled = 1 → the public tag must equal the in-circuit derivation.
    // enabled = 0 → the public tag must be zero.
    enforcementNullifiers[i] === enabled[i] * calculatedNullifier;
  }
}