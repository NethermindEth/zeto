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

// CipherTextLength returns the number of field elements SymmetricEncrypt emits
// for a plaintext of `plainTextLength` elements.
//
// Poseidon sponge encryption absorbs the plaintext in blocks of three, so the
// plaintext is zero-padded up to a multiple of three. Each block emits three
// ciphertext elements, and one authentication tag follows the last block.
//
// A circuit that declares its own `signal output` for a ciphertext has to size
// that array exactly as SymmetricEncrypt sizes `cipherText`. The padding maps
// three consecutive plaintext lengths onto the same ciphertext length, so an
// array that compiles is no evidence that the length behind it is right.
// Reading both from one place is.
function CipherTextLength(plainTextLength) {
    var padded = plainTextLength;
    if (padded % 3 != 0) {
        padded += (3 - (padded % 3));
    }
    return padded + 1;
}
