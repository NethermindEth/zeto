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
pragma solidity ^0.8.27;

interface IZetoNullifierStorageView {
    /**
     * @dev Checks whether a nullifier has been spent.
     *
     * @param n The nullifier to check.
     * @return True if the nullifier is spent; false otherwise.
     */
    function nullifierSpent(uint256 n) external view returns (bool);
}
