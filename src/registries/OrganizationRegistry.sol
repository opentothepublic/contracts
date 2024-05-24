// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Organization, OrganizationLevel, PublicKey, Identity} from "@~/library/Structs.sol";
import {UserRegistry} from "./UserRegistry.sol";
import {Sudo} from "../utils/Sudo.sol";
import "../library/Errors.sol";

contract OrganizationRegistry {
    UserRegistry internal immutable user_registry;

    Sudo internal immutable sudo;

    mapping(uint256 orgId => Organization) organizations;

    constructor(UserRegistry _user_registry, Sudo _sudo) {
        user_registry = _user_registry;
        sudo = _sudo;
    }

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

    function organization_level(uint256 orgId) public view returns (OrganizationLevel) {
        return organizations[orgId].level;
    }

    function organization_uri(uint256 orgId) public view returns (string memory) {
        return organizations[orgId].offchain_uri;
    }

    function is_organization_verified(uint256 orgId) public view returns (bool) {
        return organizations[orgId].is_verified;
    }

    function get_parent_organization(uint256 orgId) public view returns (uint256, string memory) {
        return (
            organizations[orgId].association,
            organizations[orgId].association == 0
                ? "none"
                : organizations[organizations[orgId].association].offchain_uri
        );
    }

    function add_managed_identity(uint256 orgId, uint256 userId) public only_organization_owner(orgId) {
        Identity memory user = user_registry.get_user_identity(userId);
        organizations[orgId].managed_identities.push(user);
    }

    function remove_managed_identity(uint256 orgId, uint256 userId) public only_organization_owner(orgId) {
        Identity[] memory managed_identities = organizations[orgId].managed_identities;
        Identity memory user = user_registry.get_user_identity(userId);

        for (uint256 i = 0; i < managed_identities.length; i++) {
            if (managed_identities[i].handle == user.handle) {
                organizations[orgId].managed_identities[i] = managed_identities[managed_identities.length - 1];
                organizations[orgId].managed_identities.pop();
                break;
            }
        }
    }

    function transfer_organization_ownership(uint256 orgId, uint256 new_owner) public only_organization_owner(orgId) {
        organizations[orgId].owner = user_registry.get_user_identity(new_owner);
    }

    function verify_organization(uint256 orgId) public {
        require(msg.sender == address(sudo), NotSudo());
        require(!organizations[orgId].is_verified, AlreadyVerified());
        organizations[orgId].is_verified = true;
    }

    function create_first_level_organization(uint256 orgId, string calldata offchain_uri, uint256 attester_id)
        public
        only_registry
        returns (uint256)
    {
        Identity memory identity = user_registry.get_user_identity(attester_id);
        require(identity.public_keys.length > 0, InvalidIdentity());

        return create_organization(orgId, offchain_uri, OrganizationLevel.FirstLevel, 0, identity, false);
    }

    function create_second_level_organization(
        uint256 orgId,
        string calldata offchain_uri,
        uint256 association,
        uint256 attester_id
    ) public only_registry returns (uint256) {
        Identity memory identity = user_registry.get_user_identity(attester_id);
        require(identity.public_keys.length > 0, InvalidIdentity());

        Organization memory org = organizations[association];
        require(org.level == OrganizationLevel.FirstLevel, InvalidOrgLevel());
        require(org.owner.public_keys[0].key == identity.public_keys[0].key, InvalidOrgAssociation());

        return create_organization(
            orgId, offchain_uri, OrganizationLevel.SecondLevel, association, identity, org.is_verified
        );
    }

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
