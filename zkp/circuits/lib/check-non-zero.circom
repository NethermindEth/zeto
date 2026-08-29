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

// CheckNonZero rejects a zero field element.
//   - check that in != 0
//
// Used on the x coordinate of every point derived from a secret scalar. A scalar
// of zero — or any multiple of the subgroup order — sends the derived point to
// the curve identity, whose x is zero. That collapses an ECDH shared secret to a
// value every observer can compute, so the ciphertexts it protects are readable
// by anyone and the nullifiers derived from it are publicly forgeable. Checking
// the derived x rather than the scalar catches every such scalar at once.
template CheckNonZero() {
    signal input in;

    signal isZero;
    isZero <== IsZero()(in <== in);
    isZero === 0;
}
