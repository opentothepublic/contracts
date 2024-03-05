// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

struct OTTPUser {
  PublicKey[] publicKeys;
  address[2] recovery;
  address sudo;
}

enum PublicKeyFormat {
  STANDARD,
  CUSTOM
}

struct PublicKey {
  PublicKeyFormat format;
  bytes key;
  address sigVerifier;
  bytes4 verifyFunctionSeletor;
}
