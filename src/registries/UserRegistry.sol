// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Identity, PublicKey, MAX_PUBLIC_KEYS_LENGTH, MAGICVALUE} from "@~/library/Structs.sol";
import {Sudo} from "../utils/Sudo.sol";
import {ERC1271} from "../utils/ERC1271.sol";
import {Nonce} from "../utils/Nonce.sol";
import "../library/Errors.sol";

contract UserRegistry is Nonce, ERC1271 {
    event UserRegistered(uint256 indexed oid, address user);
    event PublicKeyAdded(uint256 indexed oid, address key);
    event PublicKeyRemoved(uint256 indexed oid, address key);

    Sudo internal immutable sudo;

    mapping(uint256 oid => Identity) users;

    constructor(Sudo _sudo) {
        sudo = _sudo;
    }

    function get_user_identity(uint256 oid) public view returns (Identity memory) {
        return users[oid];
    }

    function get_recovery_addresses(uint256 _oid) public view returns (address[2] memory) {
        return users[_oid].recovery_addresses;
    }

    function get_public_key_at_index(uint256 _oid, uint256 _index) public view returns (address) {
        if (!(_index < MAX_PUBLIC_KEYS_LENGTH)) revert IndexOutOfBounds();
        return users[_oid].public_keys[_index].key;
    }

    function add_public_key(uint256 _oid, address _key, address _sigVerifier) public {
        requires_is_oid_owner(_oid, msg.sender);
        PublicKey[] storage public_keys = users[_oid].public_keys;
        if (!(public_keys.length < MAX_PUBLIC_KEYS_LENGTH)) revert IndexOutOfBounds();

        PublicKey memory public_key = PublicKey(_key, _sigVerifier);
        public_keys.push(public_key);

        sudo.oid_registry().link_address(_oid, _key);

        emit PublicKeyAdded(_oid, _key);
    }

    function remove_public_key(uint256 _oid, uint256 _keyIndex) public {
        requires_is_oid_owner(_oid, msg.sender);
        PublicKey[] storage public_keys = users[_oid].public_keys;

        if (!(_keyIndex < public_keys.length)) revert IndexOutOfBounds();
        address key = public_keys[_keyIndex].key;

        public_keys[_keyIndex] = public_keys[public_keys.length - 1];
        public_keys.pop();

        sudo.oid_registry().unlink_address(key);

        emit PublicKeyRemoved(_oid, key);
    }

    function change_recovery_addresses(uint256 _oid, address _recovery1, address _recovery2) public {
        requires_is_oid_owner(_oid, msg.sender);
        users[_oid].recovery_addresses = [_recovery1, _recovery2];
    }

    function requires_is_oid_owner(uint256 _oid, address caller) internal view {
        uint256 oid = sudo.oid_registry().get_oid(caller);
        if (oid == 0) revert NotRegistered();
        if (oid != _oid) revert UnAuthorized();
    }

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

    function recover_oid(uint256 oid, uint64 deadline, PublicKey memory new_key, bytes calldata signature) external {
        address[2] memory recovery_addresses = users[oid].recovery_addresses;

        require(msg.sender == recovery_addresses[0] || msg.sender == recovery_addresses[1]);
        require(
            is_valid_recovery_signature(oid, get_nonce(oid), deadline, recovery_addresses, signature) == MAGICVALUE,
            SignatureInvalid()
        );

        users[oid].public_keys = [new_key];
    }
}
