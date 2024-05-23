// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {OIDRegistry} from "@~/registries/OIDRegistry.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Sudo is Ownable {
    event OidRegistryChanged(OIDRegistry old_registry, OIDRegistry new_registry);

    OIDRegistry public oid_registry;

    bool final_registry = false;

    constructor() Ownable(msg.sender) {}

    function set_oid_registry(OIDRegistry _oid_registry) external onlyOwner {
        require(!final_registry, "registry is final");
        oid_registry = _oid_registry;
        emit OidRegistryChanged(oid_registry, _oid_registry);
    }

    function make_registry_final() external onlyOwner {
        final_registry = true;
    }

    function upgrade_registry(address new_implementation, bytes calldata data) external onlyOwner {
        oid_registry.upgradeToAndCall(new_implementation, data);
    }
}
