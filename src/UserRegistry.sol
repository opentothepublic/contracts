// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@~/library/Structs.sol";

contract UserRegistry {
  mapping(uint256 oid => OTTPUser) accounts;
  mapping(uint256 oid => mapping(address sudo => bool active)) public sudoable;

  event UserRegistered(uint256 indexed oid, address user);
  event PublicKeyAdded(uint256 indexed oid, uint8 format, bytes key);
  event PublicKeyRemoved(uint256 indexed oid, bytes key);
  event SudoRevoked(uint256 indexed oid, address sudo);
  event SudoGranted(uint256 indexed oid, address sudo);

  error IndexOutOfBounds();
  error InvalidSudoAddress();

  function _createUser(
    uint256 id,
    address user,
    address[2] memory recoveryAddresses,
    address sigVerifier
  ) internal {
    PublicKey memory publicKey = PublicKey(
      PublicKeyFormat.DEFAULT,
      bytes.concat(bytes20(user)),
      sigVerifier,
      0xbaca03f5
    );

    PublicKey[] memory accountKeys;
    accountKeys[0] = publicKey;

    accounts[id] = OTTPUser({
      recovery: recoveryAddresses,
      publicKeys: accountKeys,
      sudo: address(0)
    });

    emit UserRegistered(id, user);
  }

  function _removePublicKey(uint256 _id, uint256 _keyIndex) internal {
    PublicKey[] storage publicKeys = accounts[_id].publicKeys;

    if (!(_keyIndex < publicKeys.length)) revert IndexOutOfBounds();
    bytes memory key = publicKeys[_keyIndex].key;

    publicKeys[_keyIndex] = publicKeys[publicKeys.length - 1];
    publicKeys.pop();

    emit PublicKeyRemoved(_id, key);
  }

  function _addPublicKey(
    uint256 _id,
    bytes memory _key,
    address _sigVerifier,
    PublicKeyFormat _format,
    bytes4 _verifyFnSelector
  ) internal {
    PublicKey[] storage publicKeys = accounts[_id].publicKeys;
    if (!(publicKeys.length < 3)) revert IndexOutOfBounds();

    PublicKey memory publicKey = PublicKey(_format, _key, _sigVerifier, _verifyFnSelector);
    publicKeys.push(publicKey);

    emit PublicKeyAdded(_id, uint8(_format), _key);
  }

  function _setSudoAddress(uint256 _id, address _sudo) internal {
    accounts[_id].sudo = _sudo;
    sudoable[_id][_sudo] = true;

    emit SudoGranted(_id, _sudo);
  }

  function _changeRecoveryAddresses(uint256 _id, address _recovery1, address _recovery2) internal {
    accounts[_id].recovery = [_recovery1, _recovery2];
  }

  function _revokeSudo(uint256 _id, address _sudo) internal {
    if (accounts[_id].sudo != _sudo) revert InvalidSudoAddress();
    accounts[_id].sudo = address(0);
    sudoable[_id][_sudo] = false;

    emit SudoRevoked(_id, _sudo);
  }
}
