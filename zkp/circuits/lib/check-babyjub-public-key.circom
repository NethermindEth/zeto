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

include "../node_modules/circomlib/circuits/babyjub.circom";
include "../node_modules/circomlib/circuits/comparators.circom";

// CheckBabyJubPublicKey validates that a public key lies on the BabyJubJub curve
// by enforcing the twisted-Edwards equation: a*x^2 + y^2 = 1 + d*x^2*y^2.
//
// When to apply:
//   Apply to every externally-supplied public key before it enters an ECDH or
//   commitment-hash computation — specifically: enforcerPublicKey, arbiterPublicKey,
//   and outputOwnerPublicKeys[i].
//
// When NOT to apply:
//   Keys produced in-circuit via BabyPbk() are always on-curve by construction;
//   applying this check to them is redundant and wastes constraints.
//
// Scope of the check:
//   - check that the key satisfies the twisted-Edwards curve equation
//   - check that the key's x coordinate is non-zero
//
//   BabyCheck alone verifies curve membership but not prime-order subgroup
//   membership, and the only two curve points with x == 0 are exactly the two
//   that every consumer of a key misreads:
//     - Kyc and ComplianceStatus gate on `publicKey[0] == 0` and treat such a
//       key as a disabled slot, skipping the registration and status checks;
//     - EscalarMulAny replaces an x == 0 point with the Base8 generator, so the
//       ECDH shared secret for such a key collapses to privKey * Base8 — the
//       published ephemeral public key — leaving the ciphertext addressed to it
//       world-readable, and any nullifier derived against it publicly computable.
//   Rejecting x == 0 removes both readings at their source. The full cofactor
//   subgroup check is deliberately not done here: it costs roughly 250
//   constraints per key across ~14 key slots per circuit, and every exploit in
//   this family is the x == 0 case.
// The BabyJubJub generator, in the same coordinates circomlib's BabyPbk uses.
// It is the padding value for a slot that is switched off: a real prime-order
// point, so the padding satisfies every check a live key must satisfy and no
// branch is skipped for being degenerate. Do not scatter these literals.
function BabyJubBase8X() {
    return 5299619240641551281634865583518297030282874472190772894086521144482721001553;
}

function BabyJubBase8Y() {
    return 16950150798460657717958625567821834550301663161624707787222815936182638968203;
}

template CheckBabyJubPublicKey() {
    signal input publicKey[2];

    BabyCheck()(x <== publicKey[0], y <== publicKey[1]);

    signal xIsZero;
    xIsZero <== IsZero()(in <== publicKey[0]);
    xIsZero === 0;
}
