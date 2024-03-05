// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

struct OTTPUser {
  PublicKey[] publicKeys;
  address[2] recovery;
  address sudo;
}

enum PublicKeyFormat {
  DEFAULT,
  SMART_ACCOUNT,
  CUSTOM
}

struct PublicKey {
  PublicKeyFormat format;
  bytes key;
  address sigVerifier;
  bytes4 verifyFnSelector; // we could decide isValidSignature(bytes)
}

// bytes4(keccak256("isValidSignature(bytes32,(uint8,bytes,address,bytes4),bytes)"))
bytes4 constant MAGICVALUE = 0xbaca03f5;

bytes4 constant SIG_VERIFICATION_FAILED = 0xffffffff;
