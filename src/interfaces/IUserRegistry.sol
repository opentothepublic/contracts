// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IUserRegistry {
  event UserRegistered(uint256 indexed oid, address user);
  event PublicKeyAdded(uint256 indexed oid, bytes key);
  event PublicKeyRemoved(uint256 indexed oid, bytes key);
  event SudoRevoked(uint256 indexed oid, address sudo);
  event SudoGranted(uint256 indexed oid, address sudo);

  error IndexOutOfBounds();
  error Unauthorized();
  error NotRegistered();
  error AlreadyRegistered();
  error InvalidSudoAddress();

  /**
   * returns the protocol based recovery delegate for an oid
   * @param _oid      user ottp id
   */
  function getSudoAddress(uint256 _oid) external view returns (address);

  /**
   * returns the recovery addresses associated the user ottp account
   * @param _oid      user ottp id
   */
  function getRecoveryAddresses(uint256 _oid) external view returns (address[2] memory);

  /**
   * returns the public key of the user login accounts at specified index
   * @dev reverts if the index is higher than max.
   * @param _oid      user ottp id
   * @param _index    index of public key to retrieve
   */
  function getPublicKeyAtIndex(uint256 _oid, uint256 _index) external view returns (bytes memory);

  /**
   * adds a new login wallet to the users ottp account
   * @dev uses bytes to allow several types of public key including privacy preserving keys.
   * the method upon which the key signature is verified depends on the key sigVerifier
   * @param _id               user ottp id
   * @param _key              the bytes representation of the public key
   * @param _sigVerifier      a contract that defines how the signature is verified
   */
  function addPublicKey(uint256 _id, bytes memory _key, address _sigVerifier) external;

  /**
   * removes a login wallet from the user account at the specified index
   * @param _id             user ottp id
   * @param _keyIndex       location of key in account key array
   */
  function removePublicKey(uint256 _id, uint256 _keyIndex) external;

  /**
   * changes the recovery addresses associated with the ottp account
   * @param _id           user ottp id
   * @param _recovery1    address of the main recovery address
   * @param _recovery2    address of an optional recovery address or address(0)
   */
  function changeRecoveryAddresses(uint256 _id, address _recovery1, address _recovery2) external;

  /**
   * changes the protocol recovery address or the account sudo
   * @dev automatically makes account sudoable by that specific sudo
   * @param _id           user ottp id
   * @param _sudo         sudoer
   */
  function setSudoAddress(uint256 _id, address _sudo) external;

  /**
   * removes the sudo priviledge for specific address for lifetime.
   * @param _id         user ottp id
   * @param _sudo       sudoer
   */
  function revokeSudo(uint256 _id, address _sudo) external;
}
