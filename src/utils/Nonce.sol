// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

abstract contract Nonce {
    mapping(uint256 oid => uint256) internal nonces;

    function increment_nonce(uint256 oid) public {
        nonces[oid]++;
    }

    function get_nonce(uint256 oid) public view returns (uint256) {
        return nonces[oid];
    }
}
