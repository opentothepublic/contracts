// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Organization, OrganizationLevel, PublicKey, Identity} from "@~/library/Structs.sol";
import {UserRegistry} from "./UserRegistry.sol";
import {Sudo} from "../utils/Sudo.sol";
import "../library/Errors.sol";

contract OrganizationRegistry {
    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Emitted when a new organization is created.
     * @param orgId The unique identifier of the organization.
     * @param level The level of the organization.
     * @param owner The address of the organization owner.
     * @param association The associated parent organization ID, if any.
     * @param is_verified Whether the organization is verified.
     */
    event OrganizationCreated(
        uint256 indexed orgId, OrganizationLevel level, address owner, uint256 association, bool is_verified
    );

    /**
     * @dev Emitted when an organization is verified.
     * @param orgId The unique identifier of the organization.
     */
    event OrganizationVerified(uint256 indexed orgId);

    /**
     * @dev Emitted when an organization ownership is transferred.
     * @param orgId The unique identifier of the organization.
     * @param newOwner The address of the new owner.
     */
    event OrganizationOwnershipTransferred(uint256 indexed orgId, address newOwner);

    /**
     * @dev Emitted when a managed identity is added to an organization.
     * @param orgId The unique identifier of the organization.
     * @param userId The unique identifier of the managed user.
     */
    event ManagedIdentityAdded(uint256 indexed orgId, uint256 indexed userId);

    /**
     * @dev Emitted when a managed identity is removed from an organization.
     * @param orgId The unique identifier of the organization.
     * @param userId The unique identifier of the managed user.
     */
    event ManagedIdentityRemoved(uint256 indexed orgId, uint256 indexed userId);

    /*//////////////////////////////////////////////////////////////
                              VARIABLES
    //////////////////////////////////////////////////////////////*/

    UserRegistry internal immutable user_registry;
    Sudo internal immutable sudo;

    /*//////////////////////////////////////////////////////////////
                              MAPPINGS
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => Organization) organizations;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(UserRegistry _user_registry, Sudo _sudo) {
        user_registry = _user_registry;
        sudo = _sudo;
    }

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier only_organization_owner(uint256 orgId) {
        PublicKey[] memory public_keys = organizations[orgId].owner.public_keys;
        bool found = false;
        for (uint256 i = 0; i < public_keys.length; i++) {
            if (public_keys[i].key == msg.sender) {
                found = true;
                break;
            }
        }

        require(found, NotOrganizationOwner());
        _;
    }

    modifier only_registry() {
        require(msg.sender == address(sudo.oid_registry()), NotRegistry());
        _;
    }

    /*//////////////////////////////////////////////////////////////
                          EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Creates a first-level organization.
     * @param orgId The unique identifier of the organization.
     * @param offchain_uri The URI of the organization's offchain data.
     * @param attester_id The unique identifier of the attester.
     * @return The unique identifier of the created organization.
     */
    function create_first_level_organization(uint256 orgId, string calldata offchain_uri, uint256 attester_id)
        external
        only_registry
        returns (uint256)
    {
        Identity memory identity = user_registry.get_user_identity(attester_id);
        require(identity.public_keys.length > 0, InvalidIdentity());

        uint256 newOrgId = create_organization(orgId, offchain_uri, OrganizationLevel.FirstLevel, 0, identity, false);
        emit OrganizationCreated(newOrgId, OrganizationLevel.FirstLevel, identity.public_keys[0].key, 0, false);
        return newOrgId;
    }

    /**
     * @dev Creates a second-level organization.
     * @param orgId The unique identifier of the organization.
     * @param offchain_uri The URI of the organization's offchain data.
     * @param association The unique identifier of the associated parent organization.
     * @param attester_id The unique identifier of the attester.
     * @return The unique identifier of the created organization.
     */
    function create_second_level_organization(
        uint256 orgId,
        string calldata offchain_uri,
        uint256 association,
        uint256 attester_id
    ) external only_registry returns (uint256) {
        Identity memory identity = user_registry.get_user_identity(attester_id);
        require(identity.public_keys.length > 0, InvalidIdentity());

        Organization memory org = organizations[association];
        require(org.level == OrganizationLevel.FirstLevel, InvalidOrgLevel());
        require(org.owner.public_keys[0].key == identity.public_keys[0].key, InvalidOrgAssociation());

        uint256 newOrgId = create_organization(
            orgId, offchain_uri, OrganizationLevel.SecondLevel, association, identity, org.is_verified
        );
        emit OrganizationCreated(
            newOrgId, OrganizationLevel.SecondLevel, identity.public_keys[0].key, association, org.is_verified
        );
        return newOrgId;
    }

    /**
     * @dev Adds a managed identity to an organization.
     * @param orgId The unique identifier of the organization.
     * @param userId The unique identifier of the user.
     */
    function add_managed_identity(uint256 orgId, uint256 userId) external only_organization_owner(orgId) {
        Identity memory user = user_registry.get_user_identity(userId);
        organizations[orgId].managed_identities.push(user);
        emit ManagedIdentityAdded(orgId, userId);
    }

    /**
     * @dev Removes a managed identity from an organization.
     * @param orgId The unique identifier of the organization.
     * @param userId The unique identifier of the user.
     */
    function remove_managed_identity(uint256 orgId, uint256 userId) external only_organization_owner(orgId) {
        Identity[] storage managed_identities = organizations[orgId].managed_identities;
        Identity memory user = user_registry.get_user_identity(userId);

        for (uint256 i = 0; i < managed_identities.length; i++) {
            if (managed_identities[i].handle == user.handle) {
                managed_identities[i] = managed_identities[managed_identities.length - 1];
                managed_identities.pop();
                emit ManagedIdentityRemoved(orgId, userId);
                break;
            }
        }
    }

    /**
     * @dev Transfers the ownership of an organization.
     * @param orgId The unique identifier of the organization.
     * @param new_owner The unique identifier of the new owner.
     */
    function transfer_organization_ownership(uint256 orgId, uint256 new_owner)
        external
        only_organization_owner(orgId)
    {
        Identity memory newOwnerIdentity = user_registry.get_user_identity(new_owner);
        organizations[orgId].owner = newOwnerIdentity;
        emit OrganizationOwnershipTransferred(orgId, newOwnerIdentity.public_keys[0].key);
    }

    /**
     * @dev Verifies an organization.
     * @param orgId The unique identifier of the organization.
     */
    function verify_organization(uint256 orgId) external {
        require(msg.sender == address(sudo), NotSudo());
        require(!organizations[orgId].is_verified, AlreadyVerified());
        organizations[orgId].is_verified = true;
        emit OrganizationVerified(orgId);
    }

    /*//////////////////////////////////////////////////////////////
                           PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Returns the level of an organization.
     * @param orgId The unique identifier of the organization.
     * @return The level of the organization.
     */
    function organization_level(uint256 orgId) public view returns (OrganizationLevel) {
        return organizations[orgId].level;
    }

    /**
     * @dev Returns the URI of an organization.
     * @param orgId The unique identifier of the organization.
     * @return The URI of the organization.
     */
    function organization_uri(uint256 orgId) public view returns (string memory) {
        return organizations[orgId].offchain_uri;
    }

    /**
     * @dev Checks if an organization is verified.
     * @param orgId The unique identifier of the organization.
     * @return True if the organization is verified, false otherwise.
     */
    function is_organization_verified(uint256 orgId) public view returns (bool) {
        return organizations[orgId].is_verified;
    }

    /**
     * @dev Returns the parent organization of a given organization.
     * @param orgId The unique identifier of the organization.
     * @return The unique identifier of the parent organization and its URI.
     */
    function get_parent_organization(uint256 orgId) public view returns (uint256, string memory) {
        return (
            organizations[orgId].association,
            organizations[orgId].association == 0
                ? "none"
                : organizations[organizations[orgId].association].offchain_uri
        );
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Creates a new organization.
     * @param orgId The unique identifier of the organization.
     * @param offchain_uri The URI of the organization's offchain data.
     * @param level The level of the organization.
     * @param association The associated parent organization ID, if any.
     * @param owner The identity of the organization owner.
     * @param is_verified Whether the organization is verified.
     * @return The unique identifier of the created organization.
     */
    function create_organization(
        uint256 orgId,
        string calldata offchain_uri,
        OrganizationLevel level,
        uint256 association,
        Identity memory owner,
        bool is_verified
    ) internal returns (uint256) {
        Identity[] memory managed_identities;
        organizations[orgId] = Organization(offchain_uri, level, owner, managed_identities, association, is_verified);
        return orgId;
    }
}
