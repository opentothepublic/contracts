// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IOidRegistry {
  error NotResolver();

  /**
   *  returns the oid associated with the farcaster id
   * @param _fid        Farcaster id
   */
  function getOid(uint256 _fid) external view returns (uint256);

  /**
   *  returns the oid associated with the address
   * @param _address    user address
   */
  function getOid(address _address) external view returns (uint256);

  /**
   * assigns an oid to the caller and additionally creates an ottp acount
   */
  function register() external;

  /**
   * assigns an oid to the caller and additionally creates an ottp acount with the provided
   * recovery addresses
   * @param _recovery1        One of 2 recovery addresses
   * @param _recovery2        One of 2 recovery addresses
   */
  function registerWithRecoveryAddresses(address _recovery1, address _recovery2) external;

  /**
   * assigns an oid to the attesters, links the fid to it and creates an ottp account
   * @param _fid            The users farcaster id
   * @param _attester       The users farcaster client address
   */
  function registerWithFid(uint256 _fid, address _attester) external;

  /**
   * registers  multiple ottp users.
   * @param _fids         An array of farcaster id's
   * @param _attesters    An array of farcaster client addresses
   */
  function registerMultipleWithFid(
    uint256[] calldata _fids,
    address[] calldata _attesters
  ) external;
}
