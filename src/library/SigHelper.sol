// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import {ERC1271_SUCCESS} from "@~/library/Structs.sol";

error InvalidSignatureLength();

library SignatureVerifier {
  using ECDSA for bytes32;

  function extractTwoECDSASignatures(
    bytes memory _fullSignature
  ) public pure returns (bytes memory sig0, bytes memory sig1) {
    sig0 = new bytes(65);
    sig1 = new bytes(65);

    assembly {
      let r0 := mload(add(_fullSignature, 0x20))
      let s0 := mload(add(_fullSignature, 0x40))
      let v0 := and(mload(add(_fullSignature, 0x41)), 0xff)

      mstore(add(sig0, 0x20), r0)
      mstore(add(sig0, 0x40), s0)
      mstore8(add(sig0, 0x60), v0)

      let r1 := mload(add(_fullSignature, 0x61))
      let s1 := mload(add(_fullSignature, 0x81))
      let v1 := and(mload(add(_fullSignature, 0x82)), 0xff)

      mstore(add(sig1, 0x20), r1)
      mstore(add(sig1, 0x40), s1)
      mstore8(add(sig1, 0x60), v1)
    }
  }

  /**
   * checks a single signature against a hash signed by an address
   * @param signature  The signature to be checked
   * @param hash       Bytes32 digets
   * @param signer     Expected valid signer
   */
  function validateOneSignature(
    bytes32 hash,
    bytes calldata signature,
    address signer
  ) public view returns (bool) {
    return verify(hash, signer, signature) == signer;
  }

  /**
   * checks two signatures against a hash signed by two addresses
   * @param signatures  The signature to be checked
   * @param hash       Bytes32 digets
   * @param signers    Expected valid signers
   */
  function validateTwoSignatures(
    bytes32 hash,
    bytes calldata signatures,
    address[2] memory signers
  ) public view returns (bool) {
    if (total(signatures) != 2) revert InvalidSignatureLength();
    (bytes memory sig0, bytes memory sig1) = extractTwoECDSASignatures(signatures);
    return
      verify(hash, signers[0], sig0) == signers[0] && verify(hash, signers[1], sig1) == signers[1];
  }

  /**
   * checks a signature against a hash possibly signed by one of two addresses
   * @param signature  The signature to be checked
   * @param hash       Bytes32 digets
   * @param signers    Expected valid signers
   */
  function validateOneOfTwoSigners(
    bytes32 hash,
    bytes calldata signature,
    address[2] memory signers
  ) public view returns (bool) {
    if (total(signature) != 1) revert InvalidSignatureLength();
    address signer0 = verify(hash, signers[0], signature);
    address signer1 = verify(hash, signers[1], signature);
    return signer0 == signers[0] || signer1 == signers[1];
  }

  /**
   * checks a signature against a hash possibly signed by one of three addresses
   * @param signature  The signature to be checked
   * @param hash       Bytes32 digets
   * @param signers    Expected valid signers
   */
  function validateOneOfThreeSigners(
    bytes32 hash,
    bytes calldata signature,
    address[3] memory signers
  ) public view returns (bool) {
    if (total(signature) != 1) revert InvalidSignatureLength();
    address signer0 = verify(hash, signers[0], signature);
    address signer1 = verify(hash, signers[1], signature);
    address signer2 = verify(hash, signers[2], signature);
    return signer0 == signers[0] || signer1 == signers[1] || signer2 == signers[2];
  }

  /**
   * Predicts the number of signatures in a single bytes value from its length
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
    }
  }

  /**
   * tries to verify the associated signature against an EOA or a Smart Account
   * currently only supports ERC-1271 for already deployed accounts
   * @dev See ERC-6492: https://eips.ethereum.org/EIPS/eip-6492
   * @param hash         Bytes32 digets
   * @param signer       Expected valid signer
   * @param signature    The signature to be checked
   */
  function verify(
    bytes32 hash,
    address signer,
    bytes memory signature
  ) public view returns (address) {
    if (!_isContract(signer)) {
      return hash.recover(signature);
    }

    (bool success, bytes memory ret) = signer.staticcall(
      abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
    );
    if (success && abi.decode(ret, (bytes4)) == ERC1271_SUCCESS) {
      return signer;
    }

    return address(0);
  }

  function _isContract(address account) internal view returns (bool) {
    uint256 size;
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }
}
