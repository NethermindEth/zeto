pragma solidity ^0.8.27;

import {Commonlib} from "./lib/common/common.sol";
import {IAENKNRECodec} from "./lib/interfaces/iaenknre_codec.sol";
import {IGroth16Verifier} from "./lib/interfaces/izeto_verifier.sol";
import {IZetoEnforcedEvents} from "./lib/interfaces/izeto_enforced.sol";
import {IZetoInitializable} from "./lib/interfaces/izeto_initializable.sol";
import {AENKNREStorage} from "./lib/zeto_aenknre_storage.sol";
import {Zeto_AnonNullifier} from "./zeto_anon_nullifier.sol";
import {Registry} from "./lib/registry.sol";
import {ComplianceRootRegistry} from "./lib/compliance_root_registry.sol";

/// @title AENKNR-E Transfer Facet
/// @dev Implements the four proof paths (transfer, deposit, withdraw,
///   forcedTransfer) for the AENKNR-E token. Deployed separately and
///   called via DELEGATECALL from the router contract. Inherits the same
///   base chain as the router to guarantee identical storage layout.
contract Zeto_AENKNRETransferFacet is
    Zeto_AnonNullifier,
    Registry,
    ComplianceRootRegistry,
    IZetoEnforcedEvents
{
    using AENKNREStorage for *;

    struct _DecodedProof_EventFields {
        uint256[] enforcementNullifiers;
        uint256 encryptionNonce;
        uint256[2] ecdhPublicKey;
        uint256[] encryptedValuesForReceiver;
        uint256[] encryptedValuesForArbiter;
        uint256[] encryptedValuesForEnforcer;
    }

    function _s() private pure returns (AENKNREStorage.Layout storage) {
        return AENKNREStorage.layout();
    }

    function _requireEnforcerSet() private view {
        if (!_s().enforcerSet) revert EnforcerNotSet();
    }

    // ── Codec interaction ──
    //
    // The codec is an external contract called via STATICCALL. Return data
    // is parsed with assembly helpers rather than Solidity's ABI decoder.
    //
    // Return ABI layouts (word indices):
    //   buildTransfer:       [0:off_pi, 1:off_enfN, 2-9:proofWords]
    //   buildDeposit:        [0:off_pi, 1-8:proofWords]
    //   buildWithdraw:       [0:off_pi, 1:off_enfN, 2-9:proofWords]
    //   buildForcedTransfer: [0:off_pi, 1:off_enfN, 2:root, 3-10:proofWords]

    function _callCodec(
        bytes memory callData
    ) private view returns (bytes memory ret) {
        address codec = address(_s().codec);
        bool ok;
        /// @solidity memory-safe-assembly
        assembly {
            let cdLen := mload(callData)
            let cdPtr := add(callData, 0x20)
            ok := staticcall(gas(), codec, cdPtr, cdLen, 0, 0)
            let rLen := returndatasize()
            ret := mload(0x40)
            mstore(ret, rLen)
            mstore(0x40, add(add(ret, 0x20), rLen))
            returndatacopy(add(ret, 0x20), 0, rLen)
        }
        require(ok, "Codec call failed");
    }

    function _toProof(
        bytes memory ret,
        uint256 pwHead
    ) private pure returns (Commonlib.Proof memory ps) {
        uint256 base;
        /// @solidity memory-safe-assembly
        assembly {
            base := add(add(ret, 0x20), mul(pwHead, 0x20))
        }
        ps.pA[0] = _wordAt(base, 0);
        ps.pA[1] = _wordAt(base, 1);
        ps.pB[0][0] = _wordAt(base, 2);
        ps.pB[0][1] = _wordAt(base, 3);
        ps.pB[1][0] = _wordAt(base, 4);
        ps.pB[1][1] = _wordAt(base, 5);
        ps.pC[0] = _wordAt(base, 6);
        ps.pC[1] = _wordAt(base, 7);
    }

    function _wordAt(uint256 base, uint256 idx) private pure returns (uint256 v) {
        /// @solidity memory-safe-assembly
        assembly {
            v := mload(add(base, mul(idx, 0x20)))
        }
    }

    function _readDynArray(
        bytes memory data,
        uint256 headIdx
    ) private pure returns (uint256[] memory arr) {
        /// @solidity memory-safe-assembly
        assembly {
            let base := add(data, 0x20)
            let offset := mload(add(base, mul(headIdx, 0x20)))
            let arrSrc := add(base, offset)
            let len := mload(arrSrc)
            arr := mload(0x40)
            let sz := add(0x20, mul(len, 0x20))
            mstore(0x40, add(arr, sz))
            mstore(arr, len)
            let s := add(arrSrc, 0x20)
            let d := add(arr, 0x20)
            for { let i := 0 } lt(i, len) { i := add(i, 1) } {
                mstore(add(d, mul(i, 0x20)), mload(add(s, mul(i, 0x20))))
            }
        }
    }

    function _readWord(
        bytes memory data,
        uint256 headIdx
    ) private pure returns (uint256 v) {
        /// @solidity memory-safe-assembly
        assembly {
            v := mload(add(add(data, 0x20), mul(headIdx, 0x20)))
        }
    }

    // ── Enforcement nullifiers ──

    function _checkEnforcementNullifiersUnspent(
        uint256[] memory enfNullifiers
    ) private view {
        AENKNREStorage.Layout storage s = _s();
        for (uint256 i = 0; i < enfNullifiers.length; ++i) {
            if (enfNullifiers[i] == 0) continue;
            if (s.enforcementNullifierSpent[enfNullifiers[i]])
                revert EnforcementNullifierAlreadySpent(enfNullifiers[i]);
        }
    }

    function _markEnforcementNullifiersSpent(
        uint256[] memory enfNullifiers
    ) private {
        AENKNREStorage.Layout storage s = _s();
        for (uint256 i = 0; i < enfNullifiers.length; ++i) {
            if (enfNullifiers[i] != 0)
                s.enforcementNullifierSpent[enfNullifiers[i]] = true;
        }
    }

    // ── Args encoding ──
    //
    // The codec accepts (bytes proof, bytes args). The args parameter is
    // constructed as: abi.encode(params...) ++ rawCtx(192 bytes).
    // The codec splits the decode accordingly.

    function _encodeArgs(
        bytes memory head,
        bytes memory ctx
    ) private pure returns (bytes memory buf) {
        /// @solidity memory-safe-assembly
        assembly {
            let hLen := mload(head)
            let cLen := mload(ctx)
            let totalLen := add(hLen, cLen)
            buf := mload(0x40)
            mstore(buf, totalLen)
            mstore(0x40, add(add(buf, 0x20), totalLen))
            let d := add(buf, 0x20)
            let s := add(head, 0x20)
            for { let i := 0 } lt(i, hLen) { i := add(i, 0x20) } {
                mstore(add(d, i), mload(add(s, i)))
            }
            let d2 := add(d, hLen)
            let s2 := add(ctx, 0x20)
            for { let i := 0 } lt(i, cLen) { i := add(i, 0x20) } {
                mstore(add(d2, i), mload(add(s2, i)))
            }
        }
    }

    /// @dev Encodes ProofContext as 6 raw words:
    ///   [idRoot, compRoot, arbiterPub[0], arbiterPub[1], enforcerPub[0], enforcerPub[1]]
    function _encodeCtx() private view returns (bytes memory buf) {
        AENKNREStorage.Layout storage s = _s();
        /// @solidity memory-safe-assembly
        assembly {
            buf := mload(0x40)
            mstore(buf, 192)
            mstore(0x40, add(add(buf, 0x20), 192))
        }
        uint256 v = getIdentitiesRoot();
        /// @solidity memory-safe-assembly
        assembly { mstore(add(buf, 0x20), v) }
        v = getComplianceRoot();
        /// @solidity memory-safe-assembly
        assembly { mstore(add(buf, 0x40), v) }
        v = s.arbiterPub[0];
        /// @solidity memory-safe-assembly
        assembly { mstore(add(buf, 0x60), v) }
        v = s.arbiterPub[1];
        /// @solidity memory-safe-assembly
        assembly { mstore(add(buf, 0x80), v) }
        v = s.enforcerPub[0];
        /// @solidity memory-safe-assembly
        assembly { mstore(add(buf, 0xa0), v) }
        v = s.enforcerPub[1];
        /// @solidity memory-safe-assembly
        assembly { mstore(add(buf, 0xc0), v) }
    }

    // ── Public input construction overrides ──

    function constructPublicInputs(
        uint256[] memory nullifiers,
        uint256[] memory outputs,
        bytes memory proof,
        bool
    ) internal virtual override returns (uint256[] memory, Commonlib.Proof memory) {
        _requireEnforcerSet();
        bytes memory args = _encodeArgs(abi.encode(nullifiers, outputs), _encodeCtx());
        bytes memory ret = _callCodec(
            abi.encodeWithSelector(IAENKNRECodec.buildTransfer.selector, proof, args)
        );
        uint256[] memory enfN = _readDynArray(ret, 1);
        _s().pendingEnfNullifiers = enfN;
        _checkEnforcementNullifiersUnspent(enfN);
        return (_readDynArray(ret, 0), _toProof(ret, 2));
    }

    function constructPublicInputsForDeposit(
        uint256 amount,
        uint256[] memory outputs,
        bytes memory proof
    ) public virtual override returns (uint256[] memory, Commonlib.Proof memory) {
        _requireEnforcerSet();
        bytes memory args = _encodeArgs(abi.encode(amount, outputs), _encodeCtx());
        bytes memory ret = _callCodec(
            abi.encodeWithSelector(IAENKNRECodec.buildDeposit.selector, proof, args)
        );
        return (_readDynArray(ret, 0), _toProof(ret, 1));
    }

    function constructPublicInputsForWithdraw(
        uint256 amount,
        uint256[] memory nullifiers,
        uint256 output,
        bytes memory proof
    ) internal virtual override returns (uint256[] memory, Commonlib.Proof memory) {
        _requireEnforcerSet();
        bytes memory args = _encodeArgs(abi.encode(amount, nullifiers, output), _encodeCtx());
        bytes memory ret = _callCodec(
            abi.encodeWithSelector(IAENKNRECodec.buildWithdraw.selector, proof, args)
        );
        uint256[] memory enfN = _readDynArray(ret, 1);
        _s().pendingEnfNullifiers = enfN;
        _checkEnforcementNullifiersUnspent(enfN);
        return (_readDynArray(ret, 0), _toProof(ret, 2));
    }

    function processInputsAndOutputs(
        uint256[] memory inputs,
        uint256[] memory outputs,
        bool inputsLocked
    ) internal virtual override {
        super.processInputsAndOutputs(inputs, outputs, inputsLocked);
        // mark enforcement nullifiers staged during constructPublicInputs
        uint256[] storage pending = _s().pendingEnfNullifiers;
        for (uint256 i = 0; i < pending.length; ++i) {
            if (pending[i] != 0)
                _s().enforcementNullifierSpent[pending[i]] = true;
        }
    }

    // ── Event emission ──

    function emitTransferEvent(
        uint256[] memory nullifiers,
        uint256[] memory outputs,
        bytes memory proof,
        bytes memory data
    ) internal virtual override {
        _DecodedProof_EventFields memory dp = _readTransferEventFields(proof);
        emit UTXOTransferNonRepudiationEnforced(
            nullifiers, outputs,
            dp.enforcementNullifiers, dp.encryptionNonce, dp.ecdhPublicKey,
            dp.encryptedValuesForReceiver, dp.encryptedValuesForArbiter,
            dp.encryptedValuesForEnforcer,
            _s().arbiterKeyId, msg.sender, data
        );
    }

    // ── Forced transfer ──

    function forcedTransfer(
        uint256[] calldata outputs,
        bytes calldata proof,
        bytes calldata data
    ) public onlyOwner {
        _requireEnforcerSet();
        validateOutputs(outputs);

        bytes memory args = _encodeArgs(abi.encode(outputs), _encodeCtx());
        bytes memory ret = _callCodec(
            abi.encodeWithSelector(IAENKNRECodec.buildForcedTransfer.selector, proof, args)
        );

        uint256[] memory pi = _readDynArray(ret, 0);
        uint256[] memory enfN = _readDynArray(ret, 1);
        uint256 root = _readWord(ret, 2);
        validateRoot(root, false);
        _checkEnforcementNullifiersUnspent(enfN);

        Commonlib.Proof memory ps = _toProof(ret, 3);
        require(
            _s().forcedTransferVerifier.verify(ps.pA, ps.pB, ps.pC, pi),
            "Invalid proof"
        );

        _markEnforcementNullifiersSpent(enfN);
        processOutputs(outputs);
        _emitForcedTransferEvent(outputs, proof, data);
    }

    function _emitForcedTransferEvent(
        uint256[] calldata outputs,
        bytes calldata proof,
        bytes calldata data
    ) private {
        _DecodedProof_EventFields memory dp = _readForcedTransferEventFields(proof);
        emit UTXOForcedTransferEnforced(
            dp.enforcementNullifiers, outputs,
            dp.encryptionNonce, dp.ecdhPublicKey,
            dp.encryptedValuesForReceiver, dp.encryptedValuesForArbiter,
            dp.encryptedValuesForEnforcer,
            _s().arbiterKeyId, msg.sender, data
        );
    }

    // ── Proof event field readers ──
    // Word indices correspond to the ABI head of each proof encoding.

    function _readTransferEventFields(
        bytes memory proof
    ) private pure returns (_DecodedProof_EventFields memory dp) {
        dp.enforcementNullifiers = _readDynArray(proof, 1);
        dp.encryptionNonce = _readWord(proof, 2);
        dp.ecdhPublicKey[0] = _readWord(proof, 3);
        dp.ecdhPublicKey[1] = _readWord(proof, 4);
        dp.encryptedValuesForReceiver = _readDynArray(proof, 5);
        dp.encryptedValuesForArbiter = _readDynArray(proof, 6);
        dp.encryptedValuesForEnforcer = _readDynArray(proof, 7);
    }

    function _readForcedTransferEventFields(
        bytes memory proof
    ) private pure returns (_DecodedProof_EventFields memory dp) {
        dp.enforcementNullifiers = _readDynArray(proof, 0);
        dp.encryptionNonce = _readWord(proof, 3);
        dp.ecdhPublicKey[0] = _readWord(proof, 4);
        dp.ecdhPublicKey[1] = _readWord(proof, 5);
        dp.encryptedValuesForReceiver = _readDynArray(proof, 6);
        dp.encryptedValuesForArbiter = _readDynArray(proof, 7);
        dp.encryptedValuesForEnforcer = _readDynArray(proof, 8);
    }

    // ── Disabled initialization ──

    function initialize(
        string calldata,
        string calldata,
        address,
        IZetoInitializable.VerifiersInfo calldata
    ) public pure override {
        revert("Facet: use router");
    }
}
