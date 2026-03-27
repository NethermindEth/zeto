pragma solidity >=0.7.0 <0.9.0;

import {Verifier_WithdrawNullifierKycEnforced} from "./impl/withdraw_nullifier_kyc_enforced.sol";

contract Groth16Verifier_WithdrawNullifierKycEnforced is
    Verifier_WithdrawNullifierKycEnforced
{
    function verify(
        uint[2] calldata _pA,
        uint[2][2] calldata _pB,
        uint[2] calldata _pC,
        uint[] calldata _pubSignals
    ) public view returns (bool) {
        uint256[50] memory fixedSizeInputs;
        for (uint256 i = 0; i < fixedSizeInputs.length; i++) {
            fixedSizeInputs[i] = _pubSignals[i];
        }
        return this.verifyProof(_pA, _pB, _pC, fixedSizeInputs);
    }
}
