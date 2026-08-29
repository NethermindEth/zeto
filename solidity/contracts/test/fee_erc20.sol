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

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title Test-only ERC-20 that short-credits transfers, or fails without reverting
/// @dev Models the two non-standard behaviors a deposit must not trust:
///   a fee-on-transfer token, where the recipient receives less than `value`
///   while the call still reports success; and a token whose `transferFrom`
///   returns `false` rather than reverting.
contract FeeOnTransferERC20 is ERC20 {
    /// @notice Fee withheld on `transferFrom`, in basis points.
    uint16 public feeBps;
    /// @notice When set, `transferFrom` reports failure and moves nothing.
    bool public failTransferFrom;

    constructor() ERC20("Fee ERC20", "FEEERC20") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function setFeeBps(uint16 bps) external {
        feeBps = bps;
    }

    function setFailTransferFrom(bool value) external {
        failTransferFrom = value;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override returns (bool) {
        if (failTransferFrom) {
            return false;
        }
        _spendAllowance(from, _msgSender(), value);
        uint256 fee = (value * feeBps) / 10000;
        _transfer(from, to, value - fee);
        if (fee > 0) {
            _burn(from, fee);
        }
        return true;
    }
}
