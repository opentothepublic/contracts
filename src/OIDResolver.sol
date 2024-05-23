// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {OIDRegistry} from "@~/registries/OIDRegistry.sol";
import {SchemaResolver} from "@eas/contracts/resolver/SchemaResolver.sol";
import {IEAS, Attestation} from "@eas/contracts/IEAS.sol";
import {Sudo} from "@~/utils/Sudo.sol";

contract OIDResolver is SchemaResolver {
    Sudo public sudo;

    constructor(IEAS eas, Sudo _sudo) SchemaResolver(eas) {
        sudo = _sudo;
    }

    function onAttest(Attestation calldata attestation, uint256 value) internal virtual override returns (bool) {
        (value);
        (uint256 id,) = abi.decode(attestation.data, (uint256, string));
        if (sudo.oid_registry().get_oid(id) == 0) {
            // sudo.oid_registry().register_with_fid(id, attestation.attester);
        }
        return true;
    }

    function onRevoke(Attestation calldata attestation, uint256 value) internal virtual override returns (bool) {
        (attestation);
        (value);
        return true;
    }
}
