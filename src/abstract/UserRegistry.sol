// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@~/library/Structs.sol";
import "@~/abstract/Storage.sol";
import {IUserRegistry} from "@~/interfaces/IUserRegistry.sol";

abstract contract UserRegistry is IUserRegistry, Storage {
  /**
   * @inheritdoc IUserRegistry
   */
  function getSudoAddress(uint256 _oid) public view returns (address) {
    return accounts[_oid].sudo;
  }

  /**
   * @inheritdoc IUserRegistry
   */
  function getRecoveryAddresses(uint256 _oid) public view returns (address[2] memory) {
    return accounts[_oid].recovery;
  }

  /**
   * @inheritdoc IUserRegistry
   */
  function getPublicKeyAtIndex(uint256 _oid, uint256 _index) public view returns (bytes memory) {
    if (!(_index < MAX_KEY_LENGTH)) revert IndexOutOfBounds();
    return accounts[_oid].publicKeys[_index].key;
  }

  /**
   * @inheritdoc IUserRegistry
   */
  function addPublicKey(uint256 _id, bytes memory _key, address _sigVerifier) public {
    _requiresIsOidOwner(_id, msg.sender);
    PublicKey[] storage publicKeys = accounts[_id].publicKeys;
    if (!(publicKeys.length < MAX_KEY_LENGTH)) revert IndexOutOfBounds();

    PublicKey memory publicKey = PublicKey(_key, _sigVerifier);
    publicKeys.push(publicKey);

    emit PublicKeyAdded(_id, _key);
  }

  /**
   * @inheritdoc IUserRegistry
   */
  function removePublicKey(uint256 _id, uint256 _keyIndex) public {
    _requiresIsOidOwner(_id, msg.sender);
    PublicKey[] storage publicKeys = accounts[_id].publicKeys;

    if (!(_keyIndex < publicKeys.length)) revert IndexOutOfBounds();
    bytes memory key = publicKeys[_keyIndex].key;

    publicKeys[_keyIndex] = publicKeys[publicKeys.length - 1];
    publicKeys.pop();

    emit PublicKeyRemoved(_id, key);
  }

  /**
   * @inheritdoc IUserRegistry
   */
  function changeRecoveryAddresses(uint256 _id, address _recovery1, address _recovery2) public {
    _requiresIsOidOwner(_id, msg.sender);
    accounts[_id].recovery = [_recovery1, _recovery2];
  }

  /**
   * @inheritdoc IUserRegistry
   */
  function setSudoAddress(uint256 _id, address _sudo) public {
    _requiresIsOidOwner(_id, msg.sender);
    accounts[_id].sudo = _sudo;
    sudoable[_id][_sudo] = true;

    emit SudoGranted(_id, _sudo);
  }

  /**
   * @inheritdoc IUserRegistry
   */
  function revokeSudo(uint256 _id, address _sudo) public {
    _requiresIsOidOwner(_id, msg.sender);
    if (accounts[_id].sudo != _sudo) revert InvalidSudoAddress();
    accounts[_id].sudo = address(0);
    sudoable[_id][_sudo] = false;

    emit SudoRevoked(_id, _sudo);
  }

  /*//////////////////////////////////////////////////////////////
                              INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

  function _createUser(
    uint256 id,
    address user,
    address[2] memory recoveryAddresses,
    address sigVerifier
  ) internal {
    PublicKey memory publicKey = PublicKey(bytes.concat(bytes20(user)), sigVerifier);

    PublicKey[] memory accountKeys = new PublicKey[](1);
    accountKeys[0] = publicKey;

    accounts[id] = OTTPUser({
      handle: bytes32(id),
      recovery: recoveryAddresses,
      publicKeys: accountKeys,
      sudo: address(0)
    });

    emit UserRegistered(id, user);
  }

  function _requiresIsOidOwner(uint256 _oid, address caller) internal view {
    uint256 oid = oidOf[caller];
    if (oid == 0) revert NotRegistered();
    if (oid != _oid) revert Unauthorized();
  }

  // fn recover -> initiates user defined oid recovery

  // fn sudoRecover -> initiates protocol based recovery if user is sudoable
}
