// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

enum OrganizationLevel {
    FirstLevel,
    SecondLevel
}

enum Label {
    Project,
    Proposal,
    Milestone
}

struct Block {
    Identity user;
    uint64 timestamp;
    bytes content;
}

struct PublicKey {
    address key;
    address signature_verifier;
}

struct Identity {
    bytes32 handle;
    PublicKey[] public_keys;
    address[2] recovery_addresses;
}

struct Organization {
    string name;
    string url;
    OrganizationLevel level;
    Identity owner;
    Identity[] managed_identities;
    uint256 association;
    bool is_verified;
}

struct Object {
    string title;
    string description;
    Label label;
    Identity owner;
    Block[] blocks;
}

uint256 constant MAX_PUBLIC_KEYS_LENGTH = 3;

uint256 constant MAX_MANAGED_KEYS_LENGTH = 5;

// bytes4(keccak256("isValidSignature(bytes32,(uint8,bytes,address,bytes4),bytes)"))
bytes4 constant MAGICVALUE = 0xbaca03f5;

bytes4 constant SIG_VERIFICATION_FAILED = 0xffffffff;

bytes4 constant ERC1271_SUCCESS = 0x1626ba7e;
