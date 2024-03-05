// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IOidRegistry} from "@~/interfaces/IOidRegistry.sol";

import {Sudo, Ownable} from "@~/Sudo.sol";

import {SchemaResolver} from "@eas/contracts/resolver/SchemaResolver.sol";

import {IEAS, Attestation} from "@eas/contracts/IEAS.sol";

contract OIDResolver is SchemaResolver, Sudo {
  constructor(IEAS eas, IOidRegistry registry, address sudoer) Ownable(sudoer) SchemaResolver(eas) {
    oidRegistry = registry;
  }

  function onAttest(
    Attestation calldata attestation,
    uint256 value
  ) internal virtual override returns (bool) {
    // todo
  }

  function onRevoke(
    Attestation calldata attestation,
    uint256 value
  ) internal virtual override returns (bool) {
    // todo
  }

  function farcasterLink(
    address account,
    bytes32 oid,
    bytes32 fid
  ) external onlyOwner returns (bool) {
    // todo
  }
}
