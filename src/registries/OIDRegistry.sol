// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {Identity} from "@~/library/Structs.sol";
import {OIDResolver} from "../OIDResolver.sol";
import {UserRegistry} from "./UserRegistry.sol";
import {OrganizationRegistry} from "./OrganizationRegistry.sol";
import "../library/Errors.sol";

contract OIDRegistry is Initializable, UUPSUpgradeable {
    OIDResolver public resolver;

    UserRegistry internal user_registry;
    OrganizationRegistry internal organization_registry;

    uint256 public oid_counter;
    uint256 public org_id_counter;

    mapping(address user => uint256 oid) oid_of;

    mapping(uint256 fid => uint256 oid) fid_to_oid;

    modifier onlyResolver() {
        require(msg.sender == address(resolver), NotResolver());
        _;
    }

    modifier onlySudo() {
        require(msg.sender == address(resolver.sudo()), UnAuthorized());
        _;
    }

    modifier onlyUserRegistry() {
        require(msg.sender == address(user_registry), UnAuthorized());
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(OIDResolver _resolver, UserRegistry _user_registry, OrganizationRegistry _organization_registry)
        public
        initializer
    {
        resolver = _resolver;
        user_registry = _user_registry;
        organization_registry = _organization_registry;
    }

    function get_oid(uint256 _fid) public view returns (uint256) {
        return fid_to_oid[_fid];
    }

    function get_oid(address _address) public view returns (uint256) {
        return oid_of[_address];
    }

    function next_oid() internal returns (uint256) {
        return ++oid_counter;
    }

    function next_org_id() internal returns (uint256) {
        return ++org_id_counter;
    }

    function register() public {
        register(msg.sender, [address(0), address(0)]);
    }

    function register_with_recovery_addresses(address recovery_a, address recovery_b) public {
        register(msg.sender, [recovery_a, recovery_b]);
    }

    function register_with_fid(uint256 _fid, address _attester) public onlyResolver {
        link_fid(_fid, register(_attester, [address(0), address(0)]));
    }

    function register_organization() public onlyResolver {}

    function register(address _to, address[2] memory recovery) internal returns (uint256) {
        if (oid_of[_to] != 0) revert AlreadyRegistered();
        uint256 id = next_oid();
        oid_of[_to] = id;
        user_registry.create_user(id, _to, recovery, address(user_registry));
        return id;
    }

    function link_fid(uint256 _fid, uint256 _oid) internal {
        if (fid_to_oid[_fid] != 0) revert AlreadyRegistered();
        fid_to_oid[_fid] = _oid;
    }

    function link_address(uint256 _oid, address _address) external onlyUserRegistry {
        if (oid_of[_address] != 0) revert AlreadyRegistered();
        oid_of[_address] = _oid;
    }

    function unlink_address(address _address) external onlyUserRegistry {
        oid_of[_address] = 0;
    }

    function change_resolver(OIDResolver new_resolver) external onlySudo {
        resolver = new_resolver;
    }

    function _authorizeUpgrade(address new_implementation) internal virtual override onlySudo {
        (new_implementation);
    }
}
