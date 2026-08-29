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

include "../../../circuits/lib/cipher-text-length.circom";

// Evaluates the function across a contiguous range of plaintext lengths so that
// one witness covers every residue class rather than a single production value.
template CipherTextLengths(maxPlainTextLength) {
  signal output lengths[maxPlainTextLength + 1];

  for (var i = 0; i <= maxPlainTextLength; i++) {
    lengths[i] <== CipherTextLength(i);
  }
}

component main = CipherTextLengths(16);
