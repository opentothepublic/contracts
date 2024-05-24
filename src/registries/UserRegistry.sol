// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Identity, PublicKey, MAX_PUBLIC_KEYS_LENGTH, MAGICVALUE} from "@~/library/Structs.sol";
import {Sudo} from "../utils/Sudo.sol";
import {ERC1271} from "../utils/ERC1271.sol";
import {Nonce} from "../utils/Nonce.sol";
import "../library/Errors.sol";

contract UserRegistry is Nonce, ERC1271 {
    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Emitted when a new user is registered.
     * @param oid The unique identifier of the user.
     * @param user The address of the registered user.
     */
    event UserRegistered(uint256 indexed oid, address user);

    /**
     * @dev Emitted when a public key is added.
     * @param oid The unique identifier of the user.
     * @param key The address of the added public key.
     */
    event PublicKeyAdded(uint256 indexed oid, address key);

    /**
     * @dev Emitted when a public key is removed.
     * @param oid The unique identifier of the user.
     * @param key The address of the removed public key.
     */
    event PublicKeyRemoved(uint256 indexed oid, address key);

    /**
     * @dev Emitted when recovery addresses are changed.
     * @param oid The unique identifier of the user.
     * @param recovery1 The first recovery address.
     * @param recovery2 The second recovery address.
     */
    event RecoveryAddressesChanged(uint256 indexed oid, address recovery1, address recovery2);

    /**
     * @dev Emitted when a oid is transfered to a new owner.
     * @param oid The unique identifier of the user.
     * @param new_key The new public key.
     */
    event UserRecovered(uint256 indexed oid, PublicKey new_key);

    /*//////////////////////////////////////////////////////////////
                              VARIABLES
    //////////////////////////////////////////////////////////////*/

    Sudo internal immutable sudo;

    /*//////////////////////////////////////////////////////////////
                              MAPPINGS
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => Identity) users;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(Sudo _sudo) {
        sudo = _sudo;
    }

    /*//////////////////////////////////////////////////////////////
                          EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Creates a new user.
     * @param id The unique identifier of the user.
     * @param user The address of the user.
     * @param recovery_addresses The recovery addresses for the user.
     * @param signature_verifier The address of the signature verifier.
     */
    function create_user(uint256 id, address user, address[2] memory recovery_addresses, address signature_verifier)
        external
    {
        require(msg.sender == address(sudo.oid_registry()), NotRegistry());
        PublicKey memory public_key = PublicKey(user, signature_verifier);

        PublicKey[] memory account_keys = new PublicKey[](1);
        account_keys[0] = public_key;

        users[id] = Identity({handle: bytes32(id), recovery_addresses: recovery_addresses, public_keys: account_keys});

        emit UserRegistered(id, user);
    }

    /**
     * @dev Recovers the OID of a user.
     * @param oid The unique identifier of the user.
     * @param deadline The deadline for the recovery.
     * @param new_key The new public key.
     * @param signature The recovery signature.
     */
    function recover_oid(uint256 oid, uint64 deadline, PublicKey memory new_key, bytes calldata signature) external {
        address[2] memory recovery_addresses = users[oid].recovery_addresses;

        require(msg.sender == recovery_addresses[0] || msg.sender == recovery_addresses[1], UnAuthorized());
        require(
            is_valid_recovery_signature(oid, get_nonce(oid), deadline, recovery_addresses, signature) == MAGICVALUE,
            SignatureInvalid()
        );

        users[oid].public_keys = [new_key];
        emit UserRecovered(oid, new_key);
    }

    /*//////////////////////////////////////////////////////////////
                           PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Returns the identity of a user.
     * @param oid The unique identifier of the user.
     * @return The identity of the user.
     */
    function get_user_identity(uint256 oid) public view returns (Identity memory) {
        return users[oid];
    }

    /**
     * @dev Returns the recovery addresses of a user.
     * @param _oid The unique identifier of the user.
     * @return The recovery addresses of the user.
     */
    function get_recovery_addresses(uint256 _oid) public view returns (address[2] memory) {
        return users[_oid].recovery_addresses;
    }

    /**
     * @dev Returns the public key at a specific index.
     * @param _oid The unique identifier of the user.
     * @param _index The index of the public key.
     * @return The address of the public key.
     */
    function get_public_key_at_index(uint256 _oid, uint256 _index) public view returns (address) {
        require(_index < MAX_PUBLIC_KEYS_LENGTH, IndexOutOfBounds());
        return users[_oid].public_keys[_index].key;
    }

    /**
     * @dev Adds a public key for a user.
     * @param _oid The unique identifier of the user.
     * @param _key The address of the public key.
     * @param _sigVerifier The address of the signature verifier.
     */
    function add_public_key(uint256 _oid, address _key, address _sigVerifier) public {
        requires_is_oid_owner(_oid, msg.sender);
        PublicKey[] storage public_keys = users[_oid].public_keys;
        require(public_keys.length < MAX_PUBLIC_KEYS_LENGTH, IndexOutOfBounds());

        PublicKey memory public_key = PublicKey(_key, _sigVerifier);
        public_keys.push(public_key);

        sudo.oid_registry().link_address(_oid, _key);

        emit PublicKeyAdded(_oid, _key);
    }

    /**
     * @dev Removes a public key for a user.
     * @param _oid The unique identifier of the user.
     * @param _keyIndex The index of the public key to be removed.
     */
    function remove_public_key(uint256 _oid, uint256 _keyIndex) public {
        requires_is_oid_owner(_oid, msg.sender);
        PublicKey[] storage public_keys = users[_oid].public_keys;

        require(_keyIndex < public_keys.length, IndexOutOfBounds());
        address key = public_keys[_keyIndex].key;

        public_keys[_keyIndex] = public_keys[public_keys.length - 1];
        public_keys.pop();

        sudo.oid_registry().unlink_address(key);

        emit PublicKeyRemoved(_oid, key);
    }

    /**
     * @dev Changes the recovery addresses for a user.
     * @param _oid The unique identifier of the user.
     * @param _recovery1 The first recovery address.
     * @param _recovery2 The second recovery address.
     */
    function change_recovery_addresses(uint256 _oid, address _recovery1, address _recovery2) public {
        requires_is_oid_owner(_oid, msg.sender);
        users[_oid].recovery_addresses = [_recovery1, _recovery2];

        emit RecoveryAddressesChanged(_oid, _recovery1, _recovery2);
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Checks if the caller is the owner of the OID.
     * @param _oid The unique identifier of the user.
     * @param caller The address of the caller.
     */
    function requires_is_oid_owner(uint256 _oid, address caller) internal view {
        uint256 oid = sudo.oid_registry().get_oid(caller);
        require(oid != 0, NotRegistered());
        require(oid == _oid, UnAuthorized());
    }
}
