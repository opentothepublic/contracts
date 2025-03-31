// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {SignatureExpired} from "../library/Errors.sol";
import {PublicKey, SIG_V_F, SIG_V_S} from "@~/library/Structs.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";

/**
 * @title ERC1271
 * @dev This abstract contract implements the EIP-1271 interface for signature validation.
 */
abstract contract RcEcdsa is EIP712 {
  using ECDSA for bytes32;

  /*//////////////////////////////////////////////////////////////
    // Constants for the type hashes used in signature verification.
    //////////////////////////////////////////////////////////////*/

  // keccak256("isValidRecoverySignature(uint256 oid,uint256 nonce,uint256 deadline,address[2] memory recovery_addresses)")
  bytes32 public constant RECOVERY_TYPEHASH =
    0x1f3a4b2ef1e798b1fdeb2b404a9fe1ffa26e2f2130694011807dcb8985b32943;

  constructor() EIP712("OTTP Signature Verifier", "1") {}

  /**
   * @dev Validates a recovery signature.
   * @param oid The object ID.
   * @param nonce The nonce value.
   * @param deadline The deadline for the signature.
   * @param rcs The addresses used for recovery.
   * @param signature The signature to be validated.
   * @return The result of the recovery signature validation.
   */
  function is_valid_recovery_signature(
    uint256 oid,
    uint256 nonce,
    uint256 deadline,
    address[2] memory rcs,
    bytes calldata signature
  ) public view returns (bytes4) {
    if (block.timestamp > deadline) revert SignatureExpired();
    bytes32 hash = _hashTypedDataV4(
      keccak256(abi.encode(RECOVERY_TYPEHASH, oid, nonce, deadline, rcs[0], rcs[1]))
    );

    return validate_one_of_2_signers(hash, signature, rcs) ? SIG_V_S : SIG_V_F;
  }

  /**
   * @dev Validates a signature against one of two possible signers.
   * @param hash The hash of the signed data.
   * @param signature The signature to validate.
   * @param signers The addresses of the possible signers.
   * @return True if the signature is valid and matches one of the signers, false otherwise.
   */
  function validate_one_of_2_signers(
    bytes32 hash,
    bytes calldata signature,
    address[2] memory signers
  ) internal view returns (bool) {
    require(total(signature) == 1, ECDSA.ECDSAInvalidSignatureLength(signature.length));
    address left = recover(hash, signers[0], signature);

    if (left != signers[0]) {
      address right = recover(hash, signers[1], signature);
      return right == signers[1];
    }

    return true;
  }

  /**
   * @dev Returns the number of signatures.
   * @param signatures The signatures to count.
   * @return result - The number of signatures.
   */
  function total(bytes calldata signatures) internal pure returns (uint256 result) {
    uint256 len = signatures.length;
    assembly {
      switch len
      case 65 {
        result := 1
      }
      case 130 {
        result := 2
      }
      default {
        result := 0
      }
    }
  }

  /**
   * @dev Verifies a signature.
   * @param hash The hash of the signed data.
   * @param signer The address of the signer.
   * @param signature The signature to verify.
   * @return The address that signed the hash or address(0) if verification failed.
   */
  function recover(
    bytes32 hash,
    address signer,
    bytes memory signature
  ) private view returns (address) {
    if (is_contract(signer)) {
      (bool success, bytes memory ret) = signer.staticcall(
        abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
      );
      require(success && abi.decode(ret, (bytes4)) == SIG_V_S, ECDSA.ECDSAInvalidSignature());
      return signer;
    }

    return hash.recover(signature);
  }

  /**
   * @dev Checks if an address is a contract.
   * @param account The address to check.
   * @return True if the address is a contract, false otherwise.
   */
  function is_contract(address account) internal view returns (bool) {
    uint256 size;
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }
}
