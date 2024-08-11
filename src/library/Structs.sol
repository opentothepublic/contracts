// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/**
 * @dev Enumeration for different levels of an organization.
 *      - FirstLevel: Represents a first-level organization.
 *      - SecondLevel: Represents a second-level organization.
 */
enum OrganizationLevel {
    FirstLevel,
    SecondLevel
}

/**
 * @dev Enumeration for different labels that can be assigned to objects.
 *      - Project: Represents a project.
 *      - Proposal: Represents a proposal.
 *      - Milestone: Represents a milestone.
 */
enum Label {
    Project,
    Proposal,
    Milestone
}

/**
 * @dev Structure representing a block in the system.
 * @param user The identity of the user who created the block.
 * @param timestamp The timestamp when the block was created.
 * @param content The content of the block.
 */
struct Block {
    Identity user;
    uint64 timestamp;
    string content;
}

/**
 * @dev Structure representing a public key.
 * @param key The address of the public key.
 * @param signature_verifier The address of the signature verifier.
 */
struct PublicKey {
    address key;
    address signature_verifier;
}

/**
 * @dev Structure representing an identity.
 * @param handle The handle associated with the identity.
 * @param public_keys An array of public keys associated with the identity.
 * @param recovery_addresses An array of two recovery addresses.
 */
struct Identity {
    bytes32 handle;
    PublicKey[] public_keys;
    address[2] recovery_addresses;
}

/**
 * @dev Structure representing an organization.
 * @param offchain_uri The URI for off-chain data associated with the organization.
 * @param level The level of the organization.
 * @param owner The identity of the owner of the organization.
 * @param managed_identities An array of identities managed by the organization.
 * @param association The ID of the associated parent organization, if any.
 */
struct Organization {
    string offchain_uri;
    OrganizationLevel level;
    Identity owner;
    Identity[] managed_identities;
    uint256 association;
}

/**
 * @dev Structure representing an object.
 * @param offchain_uri The URI for off-chain data associated with the object.
 * @param label The label assigned to the object.
 * @param owner The identity of the owner of the object.
 * @param blocks An array of blocks associated with the object.
 */
struct Object {
    string offchain_uri;
    Label label;
    Identity owner;
    Block[] blocks;
}

/**
 * @dev Constant representing the maximum number of public keys allowed.
 */
uint256 constant MAX_PUBLIC_KEYS_LENGTH = 3;

/**
 * @dev Constant representing the maximum number of managed keys allowed.
 */
uint256 constant MAX_MANAGED_KEYS_LENGTH = 5;

/**
 * @dev Constant representing the magic value for valid signatures.
 *      - bytes4(keccak256("isValidSignature(bytes32,(uint8,bytes,address,bytes4),bytes)"))
 */
bytes4 constant MAGICVALUE = 0xbaca03f5;

/**
 * @dev Constant representing the failure value for signature verification.
 */
bytes4 constant SIG_VERIFICATION_FAILED = 0xffffffff;

/**
 * @dev Constant representing the success value for ERC1271 signature verification.
 */
bytes4 constant ERC1271_SUCCESS = 0x1626ba7e;
