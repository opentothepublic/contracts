// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {OIDRegistry} from "@~/registries/OIDRegistry.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title RegistryManager
 * @dev This contract allows the owner to manage an OIDRegistry instance.
 */
contract RegistryManager is Ownable {
  /**
   * @dev Emitted when the OID registry is changed.
   * @param old_registry The address of the old OID registry.
   * @param new_registry The address of the new OID registry.
   */
  event OidRegistryChanged(OIDRegistry old_registry, OIDRegistry new_registry);

  // The OID registry instance managed by this contract.
  OIDRegistry public oid_registry;

  // Indicates whether the registry cannot be changed.
  bool final_registry = false;

  constructor(address owner) Ownable(owner) {}

  /**
   * @dev Sets the OID registry instance. Can only be called by the owner.
   * @param _oid_registry The address of the new OID registry.
   */
  function set_oid_registry(OIDRegistry _oid_registry) external onlyOwner {
    require(!final_registry, "registry is final");
    oid_registry = _oid_registry;
    emit OidRegistryChanged(oid_registry, _oid_registry);
  }

  /**
   * @dev Makes the OID registry final. Can only be called by the owner.
   */
  function make_registry_final() external onlyOwner {
    final_registry = true;
  }

  /**
   * @dev Upgrades the OID registry to a new implementation. Can only be called by the owner.
   * @param new_implementation The address of the new implementation.
   * @param data The data to be sent to the new implementation.
   */
  function upgrade_registry(address new_implementation, bytes calldata data) external onlyOwner {
    oid_registry.upgradeToAndCall(new_implementation, data);
  }
}
