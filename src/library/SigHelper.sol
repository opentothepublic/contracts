// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

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
    bytes calldata signature,
    bytes32 hash,
    address signer
  ) public pure returns (bool) {
    return hash.recover(signature) == signer;
  }

  /**
   * checks two signatures against a hash signed by two addresses
   * @param signatures  The signature to be checked
   * @param hash       Bytes32 digets
   * @param signers    Expected valid signers
   */
  function validateTwoSignatures(
    bytes calldata signatures,
    bytes32 hash,
    address[2] memory signers
  ) public pure returns (bool) {
    if (total(signatures) != 2) revert InvalidSignatureLength();
    (bytes memory sig0, bytes memory sig1) = extractTwoECDSASignatures(signatures);
    return hash.recover(sig0) == signers[0] && hash.recover(sig1) == signers[1];
  }

  /**
   * checks a signature against a hash possibly signed by one of two addresses
   * @param signature  The signature to be checked
   * @param hash       Bytes32 digets
   * @param signers    Expected valid signers
   */
  function validateOneOfTwoSigners(
    bytes calldata signature,
    bytes32 hash,
    address[2] memory signers
  ) public pure returns (bool) {
    if (total(signature) != 1) revert InvalidSignatureLength();
    address signer = hash.recover(signature);
    return signer == signers[0] || signer == signers[1];
  }

  /**
   * checks a signature against a hash possibly signed by one of three addresses
   * @param signature  The signature to be checked
   * @param hash       Bytes32 digets
   * @param signers    Expected valid signers
   */
  function validateOneOfThreeSigners(
    bytes calldata signature,
    bytes32 hash,
    address[3] memory signers
  ) public pure returns (bool) {
    if (total(signature) != 1) revert InvalidSignatureLength();
    address signer = hash.recover(signature);
    return signer == signers[0] || signer == signers[1] || signer == signers[2];
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
}
