// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {OIDRegistry} from "@~/registries/OIDRegistry.sol";
import {SchemaResolver} from "@eas/contracts/resolver/SchemaResolver.sol";
import {IEAS, Attestation} from "@eas/contracts/IEAS.sol";
import {Sudo} from "@~/utils/Sudo.sol";
import {Label} from "@~/library/Structs.sol";

contract OIDResolver is SchemaResolver {
    /*//////////////////////////////////////////////////////////////
                              VARIABLES
    //////////////////////////////////////////////////////////////*/

    Sudo public sudo;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @param eas The address of the EAS contract on the chain.
     * @param _sudo The address of the Sudo contract.
     */
    constructor(IEAS eas, Sudo _sudo) SchemaResolver(eas) {
        sudo = _sudo;
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Handles the attestation logic.
     * @param attestation The attestation data.
     * @param value The value associated with the attestation.
     * @return True if the attestation is handled successfully.
     */
    function onAttest(Attestation calldata attestation, uint256 value) internal virtual override returns (bool) {
        // Unused variable, present to match function signature
        (value);

        // Decode the attestation data
        (uint256 fid, uint256 action, string memory data, uint8 label,) =
            abi.decode(attestation.data, (uint256, uint256, string, uint8, bytes));

        // Get the OIDRegistry instance from the sudo contract
        OIDRegistry oid_registry = sudo.oid_registry();

        // Try to register the user using the FID, attestation UID, and attester address
        oid_registry.try_register(fid, attestation.uid, attestation.attester);

        // Perform actions based on the action type
        if (action == 1) {
            // Register a new organization
            oid_registry.register_organization(attestation.uid, data, 0, attestation.attester);
        }

        if (action == 2) {
            // Register a second-level organization with a parent
            uint256 parent = oid_registry.get_org_id(attestation.refUID);
            oid_registry.register_organization(attestation.uid, data, parent, attestation.attester);
        }

        if (action == 3) {
            // Create a new object
            oid_registry.create_object(fid, attestation.uid, attestation.refUID, Label(label), data);
        }

        if (action == 4) {
            // Create a new block and add it to an existing object
            oid_registry.create_block(fid, attestation.refUID, data);
        }

        return true;
    }

    /**
     * @dev Handles the revocation logic we just return true to make this resolver support revocation.
     */
    function onRevoke(Attestation calldata attestation, uint256 value) internal virtual override returns (bool) {
        (attestation);
        (value);
        return true;
    }
}
