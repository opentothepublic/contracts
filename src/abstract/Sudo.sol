// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {OIDRegistry} from "@~/OIDRegistry.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";

/// initiates protocol based recovery if user is sudoable
/// https://github.com/farcasterxyz/contracts/blob/main/src/RecoveryProxy.sol
abstract contract Sudo is Ownable2Step {
  event SetOidRegistry(OIDRegistry oldIdRegistry, OIDRegistry newIdRegistry);

  OIDRegistry public oidRegistry;

  function setOidRegistry(OIDRegistry _oidRegistry) external onlyOwner {
    oidRegistry = _oidRegistry;
    emit SetOidRegistry(oidRegistry, _oidRegistry);
  }

  function upgradeRegistry(address newImplementation, bytes calldata data) external onlyOwner {
    oidRegistry.upgradeToAndCall(newImplementation, data);
  }
}
