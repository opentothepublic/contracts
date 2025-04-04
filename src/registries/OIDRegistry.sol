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
  /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

  /**
   * @dev Emitted for the attestation that creates an OID.
   * @param eas_uid - The unique identifier of the attestation.
   * @param oid - The unique identifier of the OID.
   */
  event OIDAttested(bytes32 indexed eas_uid, uint256 indexed oid);

  /**
   * @dev Emitted for the attestation that creates an organization.
   * @param eas_uid The unique identifier of the attestation.
   * @param parent_orgId The parent organization ID.
   * @param orgId The organization ID.
   */
  event OrganizationIdAttested(
    bytes32 indexed eas_uid,
    uint256 indexed parent_orgId,
    uint256 indexed orgId
  );

  /**
   * @dev Emitted when a new object is created.
   * @param eas_uid The unique identifier of the object.
   * @param ref_eas_uid The reference unique identifier of the object.
   * @param label The label of the object.
   * @param owner The owner of the object.
   */
  event ObjectCreated(
    bytes32 indexed eas_uid,
    bytes32 indexed ref_eas_uid,
    Label label,
    Identity owner
  );

  /**
   * @dev Emitted when a new block is added to an object.
   * @param ref_eas_uid The reference unique identifier of the object.
   * @param owner The owner of the block.
   * @param timestamp The timestamp of the block creation.
   */
  event BlockAdded(bytes32 indexed ref_eas_uid, Identity owner, uint64 timestamp);

  /**
   * @dev Emitted when the resolver is changed.
   * @param oldResolver The address of the old resolver.
   * @param newResolver The address of the new resolver.
   */
  event ResolverChanged(OIDResolver indexed oldResolver, OIDResolver indexed newResolver);

  /*//////////////////////////////////////////////////////////////
                              VARIABLES
    //////////////////////////////////////////////////////////////*/

  OIDResolver public resolver;
  UserRegistry internal user_registry;
  OrganizationRegistry internal organization_registry;
  uint256 public oid_counter;
  uint256 public org_id_counter;

  /*//////////////////////////////////////////////////////////////
                              MAPPINGS
    //////////////////////////////////////////////////////////////*/

  mapping(address => uint256) internal oid_of;
  mapping(bytes32 => uint256) internal eas_uid_to_oid;
  mapping(bytes32 => uint256) internal eas_uid_to_orgId;
  mapping(bytes32 => Object) internal objects;
  mapping(bytes32 => bool) private object_exists;

  /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

  modifier onlyResolver() {
    require(msg.sender == address(resolver), NotResolver());
    _;
  }

  modifier onlyRegistryManager() {
    require(msg.sender == address(resolver.rm()), NotManager());
    _;
  }

  modifier onlyUserRegistry() {
    require(msg.sender == address(user_registry), UnAuthorized());
    _;
  }

  /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

  constructor() {
    _disableInitializers();
  }

  /*//////////////////////////////////////////////////////////////
                          EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

  /**
   * @dev Initializes the contract.
   * @param _resolver The address of the resolver.
   * @param _user_registry The address of the user registry.
   * @param _organization_registry The address of the organization registry.
   */
  function initialize(
    OIDResolver _resolver,
    UserRegistry _user_registry,
    OrganizationRegistry _organization_registry
  ) external initializer {
    resolver = _resolver;
    user_registry = _user_registry;
    organization_registry = _organization_registry;
  }

  /**
   * @dev Registers a new organization.
   * @param eas_uid The unique identifier of the attestation.
   * @param offchain_uri The offchain URI of the organization.
   * @param association The association of the organization.
   * @param _attester The address of the attester.
   */
  function register_organization(
    bytes32 eas_uid,
    string calldata offchain_uri,
    uint256 association,
    address _attester
  ) external onlyResolver {
    uint256 owner_oid = oid_of[_attester];
    require(owner_oid != 0, NotRegistered());
    uint256 org_id = next_org_id();
    eas_uid_to_orgId[eas_uid] = org_id;

    if (association == 0) {
      organization_registry.create_first_level_organization(org_id, offchain_uri, owner_oid);
    } else {
      organization_registry.create_second_level_organization(
        org_id,
        offchain_uri,
        association,
        owner_oid
      );
    }
    emit OrganizationIdAttested(eas_uid, association, org_id);
  }

  /**
   * @dev registers or attempts to register a new user by attestation.
   * @param eas_uid The unique identifier of the attestation.
   * @param _attester The address of the attester.
   * @return oid The unique identifier of the OID.
   */
  function try_register(
    bytes32 eas_uid,
    address _attester
  ) external onlyResolver returns (uint256 oid) {
    oid = get_oid(_attester);
    if (oid == 0) {
      oid = handle_registration(eas_uid, _attester);
    }
    return oid;
  }

  /**
   * @dev Changes the resolver. only changeable by proxy upgrade.
   * @param new_resolver The address of the new resolver.
   */
  function change_resolver(OIDResolver new_resolver) external onlyRegistryManager {
    emit ResolverChanged(resolver, new_resolver);
    resolver = new_resolver;
  }

  /**
   * @dev Creates a new object refrencing the attestaion that created an org/user.
   * @param _attester The address of the type-3 ottp attestation.
   * @param eas_uid The unique identifier of the attestation.
   * @param ref_eas_uid The reference unique identifier of the attestation.
   * @param label The label of the object.
   * @param offchain_uri The offchain URI of the object.
   */
  function create_object(
    address _attester,
    bytes32 eas_uid,
    bytes32 ref_eas_uid,
    Label label,
    string calldata offchain_uri
  ) external onlyResolver {
    require(
      eas_uid_to_orgId[ref_eas_uid] != 0 || eas_uid_to_oid[ref_eas_uid] != 0,
      InvalidReference()
    );

    uint256 oid = oid_of[_attester];
    require(oid != 0, NotRegistered());
    Identity memory owner = user_registry.get_user_identity(oid);
    Object memory obj = Object(offchain_uri, label, owner, new Block[](0));
    objects[eas_uid] = obj;
    object_exists[eas_uid] = true;

    emit ObjectCreated(eas_uid, ref_eas_uid, label, owner);
  }

  /**
   * @dev Creates a new block referencing the attestation that created an object.
   * multi-attest can be used to create an object containing blocks
   * @param _attester The address of the type-4 ottp attestation.
   * @param ref_eas_uid The reference unique identifier of the attestation.
   * @param data The data of the block.
   */
  function create_block(
    address _attester,
    bytes32 ref_eas_uid,
    string calldata data
  ) external onlyResolver {
    require(object_exists[ref_eas_uid], InvalidReference());

    uint256 oid = oid_of[_attester];
    require(oid != 0, NotRegistered());
    Identity memory owner = user_registry.get_user_identity(oid);
    Block memory blk = Block(owner, uint64(block.timestamp), data);
    add_block_to_object(ref_eas_uid, blk);

    emit BlockAdded(ref_eas_uid, owner, uint64(block.timestamp));
  }

  /*//////////////////////////////////////////////////////////////
                           PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

  /**
   * @dev Returns the OID for a given address.
   * @param _address The address of the user.
   * @return The OID of the user.
   */
  function get_oid(address _address) public view returns (uint256) {
    return oid_of[_address];
  }

  /**
   * @dev Returns the organization ID for a given attestation UID.
   * @param _attestation_uid The unique identifier of the attestation.
   * @return The organization ID.
   */
  function get_org_id(bytes32 _attestation_uid) public view returns (uint256) {
    return eas_uid_to_orgId[_attestation_uid];
  }

  /**
   * @dev Registers a new user with an FID.
   * @param eas_uid The unique identifier of the attestation.
   * @param _attester The address of the attester.
   * @return oid The unique identifier of the OID.
   */
  function handle_registration(
    bytes32 eas_uid,
    address _attester
  ) public onlyResolver returns (uint256 oid) {
    oid = register(_attester, [address(0), address(0)]);
    eas_uid_to_oid[eas_uid] = oid;
    emit OIDAttested(eas_uid, oid);
  }

  /*//////////////////////////////////////////////////////////////
                      INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

  /**
   * @dev Generates the next OID.
   * @return The next OID.
   */
  function next_oid() internal returns (uint256) {
    return ++oid_counter;
  }

  /**
   * @dev Generates the next organization ID.
   * @return The next organization ID.
   */
  function next_org_id() internal returns (uint256) {
    return ++org_id_counter;
  }

  /**
   * @dev Registers a new user.
   * @param _to The address of the user.
   * @param recovery The recovery addresses of the user.
   * @return id The unique identifier of the OID.
   */
  function register(address _to, address[2] memory recovery) internal returns (uint256 id) {
    require(oid_of[_to] == 0, AlreadyRegistered());
    id = next_oid();
    oid_of[_to] = id;
    user_registry.create_user(id, _to, recovery, address(user_registry));
  }

  /**
   * @dev Links an address to an OID.
   * @param _oid The OID of the user.
   * @param _address The address of the user.
   */
  function link_address(uint256 _oid, address _address) external onlyUserRegistry {
    require(oid_of[_address] == 0, AlreadyRegistered());
    oid_of[_address] = _oid;
  }

  /**
   * @dev Unlinks an address from an OID.
   * @param _address The address of the user.
   */
  function unlink_address(address _address) external onlyUserRegistry {
    oid_of[_address] = 0;
  }

  /**
   * @dev Adds a block to an object.
   * @param ref_eas_uid The reference unique identifier of the attestation.
   * @param _block The block to be added.
   */
  function add_block_to_object(bytes32 ref_eas_uid, Block memory _block) internal {
    objects[ref_eas_uid].blocks.push(_block);
  }

  /**
   * @dev Authorizes an upgrade to a new implementation.
   * @param new_implementation The address of the new implementation.
   */
  function _authorizeUpgrade(
    address new_implementation
  ) internal virtual override onlyRegistryManager {
    (new_implementation);
  }
}
