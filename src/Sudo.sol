// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IOidRegistry} from "@~/interfaces/IOidRegistry.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";

/// initiates protocol based recovery if user is sudoable
/// https://github.com/farcasterxyz/contracts/blob/main/src/RecoveryProxy.sol
abstract contract Sudo is Ownable2Step {
  event SetOidRegistry(IOidRegistry oldIdRegistry, IOidRegistry newIdRegistry);

  IOidRegistry public oidRegistry;

  function recover(address from, address to, bytes calldata sig) external onlyOwner {
    // oidRegistry.recover(from, to, sig);
  }

  function setOidRegistry(IOidRegistry _oidRegistry) external onlyOwner {
    emit SetOidRegistry(oidRegistry, _oidRegistry);
    oidRegistry = _oidRegistry;
  }
}
