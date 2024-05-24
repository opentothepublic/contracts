// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/**
 * @title Nonce
 * @dev This abstract contract is used to manage EIP-1271 nonces during signature verification.
 */
abstract contract Nonce {
    /**
     * @dev Mapping from OID to nonce value.
     */
    mapping(uint256 oid => uint256 nonce) internal nonces;

    /**
     * @dev Increments the nonce for a given OID.
     * @param oid The OID for which to increment the nonce.
     */
    function increment_nonce(uint256 oid) public {
        nonces[oid]++;
    }

    /**
     * @dev Returns the current nonce for a given OID.
     * @param oid The OID for which to retrieve the nonce.
     * @return The current nonce value.
     */
    function get_nonce(uint256 oid) public view returns (uint256) {
        return nonces[oid];
    }
}
