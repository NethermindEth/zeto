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

/// @title Test-only ERC-20 that re-enters a Zeto contract from `transfer`
/// @dev Models a callback-capable backing asset. `withdraw` moves ERC-20 value
///   through this token, so if the Zeto contract has not yet recorded its
///   nullifiers as spent at that moment, the nested call sees them unspent and
///   can redeem the same note again.
///
///   The nested call's outcome is recorded rather than bubbled, so the outer
///   withdrawal still completes either way and the test can measure the total
///   value that actually left the Zeto contract.
contract ReentrantWithdrawERC20 is ERC20 {
    address private _target;
    bytes private _payload;
    bool private _armed;

    /// @notice Whether a nested call was attempted during the last transfer.
    bool public reentered;
    /// @notice Whether that nested call completed without reverting.
    bool public reentrySucceeded;

    constructor() ERC20("Reentrant ERC20", "REERC20") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    /// @notice Arm exactly one re-entrant call, issued from the next `transfer`.
    function arm(address target, bytes calldata payload) external {
        _target = target;
        _payload = payload;
        _armed = true;
        reentered = false;
        reentrySucceeded = false;
    }

    function transfer(
        address to,
        uint256 value
    ) public override returns (bool) {
        if (_armed) {
            _armed = false; // re-enter once, not unboundedly
            reentered = true;
            (bool ok, ) = _target.call(_payload);
            reentrySucceeded = ok;
        }
        return super.transfer(to, value);
    }
}
