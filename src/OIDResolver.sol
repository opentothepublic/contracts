// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {SchemaResolver} from "@eas/contracts/resolver/SchemaResolver.sol";

import {IEAS, Attestation} from "@eas/contracts/IEAS.sol";

contract OIDResolver is SchemaResolver {
  constructor(IEAS eas) SchemaResolver(eas) {}

  function onAttest(
    Attestation calldata attestation,
    uint256 value
  ) internal virtual override returns (bool) {}

  function onRevoke(
    Attestation calldata attestation,
    uint256 value
  ) internal virtual override returns (bool) {}

  function link(address account, bytes32 oid, bytes32 fid) external returns (bool) {
    // todo
  }
}
