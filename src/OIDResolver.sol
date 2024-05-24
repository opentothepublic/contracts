// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {OIDRegistry} from "@~/registries/OIDRegistry.sol";
import {SchemaResolver} from "@eas/contracts/resolver/SchemaResolver.sol";
import {IEAS, Attestation} from "@eas/contracts/IEAS.sol";
import {Sudo} from "@~/utils/Sudo.sol";
import {Label} from "@~/library/Structs.sol";

contract OIDResolver is SchemaResolver {
    Sudo public sudo;

    constructor(IEAS eas, Sudo _sudo) SchemaResolver(eas) {
        sudo = _sudo;
    }

    function onAttest(Attestation calldata attestation, uint256 value) internal virtual override returns (bool) {
        (value);
        (uint256 fid, uint256 action, string memory data, uint8 label,) =
            abi.decode(attestation.data, (uint256, uint256, string, uint8, bytes));

        OIDRegistry oid_registry = sudo.oid_registry();
        oid_registry.try_register(fid, attestation.attester);

        if (action == 1) {
            oid_registry.register_organization(attestation.uid, data, 0, attestation.attester);
        }

        if (action == 2) {
            uint256 parent = oid_registry.get_org_id(attestation.refUID);
            oid_registry.register_organization(attestation.uid, data, parent, attestation.attester);
        }

        if (action == 3) {
            oid_registry.create_object(fid, attestation.uid, attestation.refUID, Label(label), data);
        }

        if (action == 4) {
            oid_registry.create_block(fid, attestation.refUID, data);
        }

        return true;
    }

    function onRevoke(Attestation calldata attestation, uint256 value) internal virtual override returns (bool) {
        (attestation);
        (value);
        return true;
    }
}
