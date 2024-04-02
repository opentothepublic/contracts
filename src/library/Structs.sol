// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

struct OTTPUser {
  bytes32 handle;
  PublicKey[] publicKeys;
  address[2] recovery;
  address sudo;
}

struct PublicKey {
  bytes key;
  address sigVerifier;
}

uint256 constant MAX_KEY_LENGTH = 3;

// bytes4(keccak256("isValidSignature(bytes32,(uint8,bytes,address,bytes4),bytes)"))
bytes4 constant MAGICVALUE = 0xbaca03f5;

bytes4 constant SIG_VERIFICATION_FAILED = 0xffffffff;

bytes4 constant ERC1271_SUCCESS = 0x1626ba7e;
