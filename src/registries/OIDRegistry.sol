// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {Identity, Object, Block, Label} from "@~/library/Structs.sol";
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

    mapping(address user => uint256 oid) internal oid_of;

    mapping(uint256 fid => uint256 oid) internal fid_to_oid;

    mapping(bytes32 eas_uid => uint256 orgId) internal eas_uid_to_orgId;

    mapping(bytes32 eas_uid => Object) internal objects;

    mapping(bytes32 eas_uid => bool object_exists) private object_exists;

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

    function get_org_id(bytes32 _attestation_uid) public view returns (uint256) {
        return eas_uid_to_orgId[_attestation_uid];
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

    function register_with_fid(uint256 _fid, address _attester) public onlyResolver returns (uint256 oid) {
        oid = register(_attester, [address(0), address(0)]);
        link_fid(_fid, oid);
    }

    function register_organization(
        bytes32 eas_uid,
        string calldata offchain_uri,
        uint256 association,
        address _attester
    ) public onlyResolver {
        uint256 owner = oid_of[_attester];
        require(owner != 0, NotRegistered());
        uint256 org_id = next_org_id();

        if (association == 0) {
            organization_registry.create_first_level_organization(org_id, offchain_uri, owner);
        } else {
            organization_registry.create_second_level_organization(org_id, offchain_uri, owner, association);
        }

        eas_uid_to_orgId[eas_uid] = org_id;
    }

    function try_register(uint256 _fid, address _attester) external onlyResolver returns (uint256 oid) {
        oid = get_oid(_fid);
        if (oid == 0) {
            oid = register_with_fid(_fid, _attester);
        }
        return oid;
    }

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

    function create_object(
        uint256 _fid,
        bytes32 eas_uid,
        bytes32 ref_eas_uid,
        Label label,
        string calldata offchain_uri
    ) external onlyResolver {
        require(eas_uid_to_orgId[ref_eas_uid] != 0, InvalidReference());

        uint256 oid = fid_to_oid[_fid];
        require(oid != 0, NotRegistered());
        Identity memory owner = user_registry.get_user_identity(oid);
        Object memory obj = Object(offchain_uri, label, owner, new Block[](0));
        objects[eas_uid] = obj;
        object_exists[eas_uid] = true;
    }

    function create_block(uint256 _fid, bytes32 ref_eas_uid, string calldata data) external onlyResolver {
        require(object_exists[ref_eas_uid], InvalidReference());
        uint256 oid = fid_to_oid[_fid];
        require(oid != 0, NotRegistered());
        Identity memory owner = user_registry.get_user_identity(oid);
        Block memory blk = Block(owner, uint64(block.timestamp), data);

        add_block_to_object(ref_eas_uid, blk);
    }

    function add_block_to_object(bytes32 ref_eas_uid, Block memory _block) internal {
        objects[ref_eas_uid].blocks.push(_block);
    }

    function _authorizeUpgrade(address new_implementation) internal virtual override onlySudo {
        (new_implementation);
    }
}
