// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script} from "forge-std/Script.sol";
import {OIDRegistry} from "@~/registries/OIDRegistry.sol";
import {UserRegistry} from "@~/registries/UserRegistry.sol";
import {OrganizationRegistry} from "@~/registries/OrganizationRegistry.sol";
import {OIDResolver} from "@~/OIDResolver.sol";
import {Sudo} from "@~/utils/Sudo.sol";
import {IEAS} from "@eas/contracts/IEAS.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployScript is Script {
    bytes32 constant salt = 0x26687aadf862bd776c8fc18b8eaf8e203a20eb5710e01a8f26f8dac808c0a7c0;

    function run() external {
        vm.startBroadcast();

        // Deploy the Sudo contract
        Sudo sudo = new Sudo{salt: salt}();

        // Deploy the UserRegistry contract
        UserRegistry userRegistry = new UserRegistry{salt: salt}(sudo);

        // Deploy the OrganizationRegistry contract
        OrganizationRegistry organizationRegistry = new OrganizationRegistry{salt: salt}(userRegistry, sudo);

        // Deploy the OIDResolver contract
        IEAS eas = IEAS(0x4200000000000000000000000000000000000021);
        OIDResolver oidResolver = new OIDResolver{salt: salt}(eas, sudo);

        // Deploy the OIDRegistry implementation contract
        OIDRegistry oidRegistryImplementation = new OIDRegistry{salt: salt}();

        // Encode the initializer data
        bytes memory data = abi.encodeWithSignature(
            "initialize(address,address,address)",
            address(oidResolver),
            address(userRegistry),
            address(organizationRegistry)
        );

        // Deploy the ERC1967Proxy for OIDRegistry
        ERC1967Proxy oidRegistryProxy = new ERC1967Proxy{salt: salt}(address(oidRegistryImplementation), data);

        // Cast the proxy address to OIDRegistry to interact with it
        OIDRegistry oidRegistry = OIDRegistry(address(oidRegistryProxy));

        // Set the resolver in Sudo contract
        sudo.set_oid_registry(oidRegistry);

        // End deployment script
        vm.stopBroadcast();
    }
}
