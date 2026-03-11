pragma solidity ^0.8.27;

import {Commonlib} from "./lib/common/common.sol";
import {IZetoInitializable} from "./lib/interfaces/izeto_initializable.sol";
import {Zeto_AnonEncNullifierNonRepudiation} from "./zeto_anon_enc_nullifier_non_repudiation.sol";
import {Registry} from "./lib/registry.sol";
import {ComplianceRootRegistry} from "./lib/compliance_root_registry.sol";

/// @title A Zeto based fungible token with anonymity, encryption, nullifiers,
///   KYC, compliance enforcement, non-repudiation, and enforcer-initiated seizure
/// @author Kaleido, Inc.
/// @dev Extends the non-repudiation variant with:
///        - KYC registry membership enforcement via identities SMT
///        - Compliance status enforcement (ACTIVE/FROZEN) via compliance SMT
///        - Dual-authority non-repudiation (arbiter + enforcer ciphertexts)
///        - Enforcement nullifiers for enforcer-initiated forced transfers
///        - forcedTransfer path for seizure of frozen user UTXOs
contract Zeto_AnonEncNullifierKycNonRepudiationEnforced is
    Zeto_AnonEncNullifierNonRepudiation,
    Registry,
    ComplianceRootRegistry
{
    function initialize(
        string calldata name,
        string calldata symbol,
        address initialOwner,
        IZetoInitializable.VerifiersInfo calldata verifiers
    ) public override initializer {
        __ZetoAnonEncNullifierKycNonRepudiationEnforced_init(
            name,
            symbol,
            initialOwner,
            verifiers
        );
    }

    function __ZetoAnonEncNullifierKycNonRepudiationEnforced_init(
        string calldata name_,
        string calldata symbol_,
        address initialOwner,
        IZetoInitializable.VerifiersInfo calldata verifiers
    ) internal onlyInitializing {
        __Registry_init();
        __ComplianceRootRegistry_init();
        __ZetoAnonEncNullifierNonRepudiation_init(
            name_,
            symbol_,
            initialOwner,
            verifiers
        );
    }

    function constructPublicInputs(
        uint256[] memory nullifiers,
        uint256[] memory outputs,
        bytes memory proof,
        bool inputsLocked
    )
        internal
        virtual
        override
        returns (uint256[] memory, Commonlib.Proof memory)
    {
        return
            super.constructPublicInputs(
                nullifiers,
                outputs,
                proof,
                inputsLocked
            );
    }

    function constructPublicInputsForDeposit(
        uint256 amount,
        uint256[] memory outputs,
        bytes memory proof
    )
        public
        virtual
        override
        returns (uint256[] memory, Commonlib.Proof memory)
    {
        return super.constructPublicInputsForDeposit(amount, outputs, proof);
    }

    function constructPublicInputsForWithdraw(
        uint256 amount,
        uint256[] memory nullifiers,
        uint256 output,
        bytes memory proof
    )
        internal
        virtual
        override
        returns (uint256[] memory, Commonlib.Proof memory)
    {
        return
            super.constructPublicInputsForWithdraw(
                amount,
                nullifiers,
                output,
                proof
            );
    }

    function emitTransferEvent(
        uint256[] memory nullifiers,
        uint256[] memory outputs,
        bytes memory proof,
        bytes memory data
    ) internal virtual override {
        super.emitTransferEvent(nullifiers, outputs, proof, data);
    }

    function extraInputs()
        internal
        view
        virtual
        override
        returns (uint256[] memory)
    {
        uint256[] memory extras = new uint256[](1);
        extras[0] = getIdentitiesRoot();
        return extras;
    }

    function extraInputsForDeposit()
        internal
        view
        virtual
        override
        returns (uint256[] memory)
    {
        uint256[] memory extras = new uint256[](1);
        extras[0] = getIdentitiesRoot();
        return extras;
    }

    function forcedTransfer(
        uint256[] calldata outputs,
        bytes calldata proof,
        bytes calldata data
    ) public onlyOwner {
        //TODO
    }
}