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

// The compliance status values carried in the third slot of a compliance tree
// leaf, `Poseidon(3)([pubKeyX, pubKeyY, STATUS])`.
//
// These are baked in at compile time wherever they are used, so a prover cannot
// substitute one for the other. Naming them here keeps the leaf encoding, which
// the off-chain publisher has to match exactly, in a single place rather than at
// every site that compares a status. Changing either value invalidates every
// published compliance root.

function STATUS_ACTIVE() {
    return 1;
}

function STATUS_FROZEN() {
    return 2;
}
