// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@~/library/Structs.sol";
import "@~/library/SigHelper.sol";

contract ERC1271 is EIP712 {
  using SignatureVerifier for bytes32;

  bytes32 public constant SUDO_TYPEHASH =
    keccak256("isValidSudoSignature(uint256 oid,uint256 nonce,uint256 deadline, address sudo)");

  bytes32 public constant RECOVERY_TYPEHASH =
    keccak256(
      "isValidRecoverySignature(uint256 oid,uint256 nonce,uint256 deadline, address recovery1, address recovery2)"
    );

  bytes32 public constant RECOVERY_OR_SUDO_TYPEHASH =
    keccak256(
      "isValidSudoOrRecoverySignature(uint256 oid,uint256 nonce,uint256 deadline, address recovery1, address recovery2, address sudo)"
    );

  error SignatureExpired();

  constructor() EIP712("OTTP Signature Verifier", "1") {}

  // fnsig -> baca03f5
  function isValidSignature(
    bytes32 hash,
    PublicKey memory publickey,
    bytes calldata signature
  ) external view returns (bytes4 magicValue) {
    if (publickey.sigVerifier == address(0)) return SIG_VERIFICATION_FAILED;

    if (publickey.sigVerifier == address(this)) {
      return _verify(hash, publickey, signature) ? MAGICVALUE : SIG_VERIFICATION_FAILED;
    }

    return _verify(hash, publickey, signature, "") ? MAGICVALUE : SIG_VERIFICATION_FAILED;
  }

  function isValidSudoSignature(
    uint256 oid,
    uint256 nonce,
    uint256 deadline,
    address sudo,
    bytes memory signature
  ) external view returns (bytes4 magicValue) {
    if (block.timestamp > deadline) revert SignatureExpired();
    return
      _hashTypedDataV4(keccak256(abi.encode(SUDO_TYPEHASH, oid, nonce, deadline, sudo)))
        .validateOneSignature(signature, sudo)
        ? MAGICVALUE
        : SIG_VERIFICATION_FAILED;
  }

  function isValidRecoverySignature(
    uint256 oid,
    uint256 nonce,
    uint256 deadline,
    address recovery1,
    address recovery2,
    bytes memory signature
  ) external view returns (bytes4 magicValue) {
    if (block.timestamp > deadline) revert SignatureExpired();
    return
      _hashTypedDataV4(
        keccak256(abi.encode(RECOVERY_TYPEHASH, oid, nonce, deadline, recovery1, recovery2))
      ).validateOneOfTwoSigners(signature, [recovery1, recovery2])
        ? MAGICVALUE
        : SIG_VERIFICATION_FAILED;
  }

  function isValidSudoOrRecoverySignature(
    uint256 oid,
    uint256 nonce,
    uint256 deadline,
    address recovery1,
    address recovery2,
    address sudo,
    bytes memory signature
  ) external view returns (bytes4 magicValue) {
    if (block.timestamp > deadline) revert SignatureExpired();
    return
      _hashTypedDataV4(
        keccak256(
          abi.encode(RECOVERY_OR_SUDO_TYPEHASH, oid, nonce, deadline, recovery1, recovery2, sudo)
        )
      ).validateOneOfThreeSigners(signature, [recovery1, recovery2, sudo])
        ? MAGICVALUE
        : SIG_VERIFICATION_FAILED;
  }

  function _verify(
    bytes32 hash,
    PublicKey memory publickey,
    bytes calldata signature
  ) internal view returns (bool) {
    address signer = address(bytes20(publickey.key));
    return _hashTypedDataV4(hash).validateOneSignature(signature, signer);
  }

  function _verify(
    bytes32 hash,
    PublicKey memory publickey,
    bytes calldata signature,
    bytes memory data
  ) internal view returns (bool) {
    return
      _hashTypedDataV4(hash).validateOneSignature(
        abi.encode(publickey.key, signature, data),
        publickey.sigVerifier
      );
  }
}
