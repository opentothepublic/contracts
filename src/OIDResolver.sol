// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {OIDRegistry} from "@~/OIDRegistry.sol";
import {Sudo, Ownable} from "@~/abstract/Sudo.sol";
import {SchemaResolver} from "@eas/contracts/resolver/SchemaResolver.sol";
import {IEAS, Attestation} from "@eas/contracts/IEAS.sol";

contract OIDResolver is SchemaResolver, Sudo {
  constructor(IEAS eas, OIDRegistry registry, address sudoer) Ownable(sudoer) SchemaResolver(eas) {
    oidRegistry = registry;
  }

  function onAttest(
    Attestation calldata attestation,
    uint256 value
  ) internal virtual override returns (bool) {
    (value);
    (uint256 id, ) = abi.decode(attestation.data, (uint256, string));
    if (oidRegistry.getOid(id) == 0) {
      oidRegistry.registerWithFid(id, attestation.attester);
    }
    return true;
  }

  function onRevoke(
    Attestation calldata attestation,
    uint256 value
  ) internal virtual override returns (bool) {
    (attestation);
    (value);
    return true;
  }
}
