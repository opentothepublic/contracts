// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {OIDRegistry, IOidRegistry} from "@~/OIDRegistry.sol";
import {OIDResolver, IEAS} from "@~/OIDResolver.sol";
import {ERC1271} from "@~/utils/ERC1271.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract OIDRegistryScript is Script {
  bytes32 constant salt = 0x66687aadf862bd776c8fc18b8e9f8e203a20ebe7b0e01a8f26f8dac808c7a7c0;

  function setUp() public {}

  function run() public {
    vm.startBroadcast();
    OIDRegistry impl = new OIDRegistry();

    ERC1271 verifier = new ERC1271();
    OIDResolver resolver = new OIDResolver(
      IEAS(0x4200000000000000000000000000000000000021),
      IOidRegistry(address(0)),
      msg.sender
    );

    OIDRegistry registry = OIDRegistry(
      payable(
        new ERC1967Proxy{salt: salt}(
          address(impl),
          abi.encodeCall(impl.initialize, (address(resolver), address(verifier)))
        )
      )
    );

    resolver.setOidRegistry(registry);
    vm.stopBroadcast();
  }
}
