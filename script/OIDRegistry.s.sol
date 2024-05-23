// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {OIDRegistry} from "@~/registries/OIDRegistry.sol";
import {OIDResolver, Sudo, IEAS} from "@~/OIDResolver.sol";
import {ERC1271} from "@~/utils/ERC1271.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract OIDRegistryScript is Script {
  bytes32 constant salt = 0x26687aadf862bd776c8fc18b8eaf8e203a20eb5710e01a8f26f8dac808c0a7c0;

  function setUp() public {}

  function run() public {
    vm.startBroadcast();
    OIDRegistry impl = new OIDRegistry();

    // OIDResolver resolver =
    //     new OIDResolver(IEAS(0x4200000000000000000000000000000000000021), OIDRegistry(address(0)), msg.sender);

    // OIDRegistry registry = OIDRegistry(
    //     payable(
    //         new ERC1967Proxy{salt: salt}(
    //             address(impl), abi.encodeCall(impl.initialize, (address(resolver), address(verifier)))
    //         )
    //     )
    // );

    // resolver.setOidRegistry(registry);
    vm.stopBroadcast();
  }
}
