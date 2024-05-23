// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {SignatureExpired} from "../library/Errors.sol";
import {MAGICVALUE, PublicKey, SIG_VERIFICATION_FAILED} from "@~/library/Structs.sol";
import {SignatureVerifier} from "@~/library/SigHelper.sol";

abstract contract ERC1271 is EIP712 {
    using SignatureVerifier for bytes32;

    bytes32 public constant SUDO_TYPEHASH =
        keccak256("isValidSudoSignature(uint256 oid,uint256 nonce,uint256 deadline, address sudo)");

    bytes32 public constant RECOVERY_TYPEHASH = keccak256(
        "isValidRecoverySignature(uint256 oid,uint256 nonce,uint256 deadline, address recovery1, address recovery2)"
    );

    constructor() EIP712("OTTP Signature Verifier", "1") {}

    // fnsig -> baca03f5
    function is_valid_signature(bytes32 hash, PublicKey memory public_key, bytes calldata signature)
        public
        view
        returns (bytes4 magicValue)
    {
        if (public_key.signature_verifier == address(0)) return SIG_VERIFICATION_FAILED;

        if (public_key.signature_verifier != address(this)) return SIG_VERIFICATION_FAILED;

        return _hashTypedDataV4(hash).validate_one_signer(signature, address(bytes20(public_key.key)))
            ? MAGICVALUE
            : SIG_VERIFICATION_FAILED;
    }

    function is_valid_signature(bytes32 hash, PublicKey memory public_key, bytes calldata signature, bytes memory data)
        public
        view
        returns (bytes4)
    {
        if (public_key.signature_verifier == address(0)) return SIG_VERIFICATION_FAILED;

        return _hashTypedDataV4(hash).validate_one_signer(
            abi.encode(public_key.key, signature, data), public_key.signature_verifier
        ) ? MAGICVALUE : SIG_VERIFICATION_FAILED;
    }

    function is_valid_recovery_signature(
        uint256 oid,
        uint256 nonce,
        uint256 deadline,
        address[2] memory recovery_addresses,
        bytes calldata signature
    ) public view returns (bytes4) {
        if (block.timestamp > deadline) revert SignatureExpired();
        return _hashTypedDataV4(
            keccak256(abi.encode(RECOVERY_TYPEHASH, oid, nonce, deadline, recovery_addresses[0], recovery_addresses[1]))
        ).validate_one_of_two_signers(signature, recovery_addresses) ? MAGICVALUE : SIG_VERIFICATION_FAILED;
    }
}
