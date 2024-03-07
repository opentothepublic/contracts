// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IOidRegistry {
  error NotRegistered();
  error AlreadyRegistered();
  error NotSudoable();
  error NotRegistrar();
  error NotResolver();

  function register() external;

  function registerWithRecoveryAddresses(address _recovery1, address _recovery2) external;

  function registerWithFid(uint256 _fid) external;

  function registerMultipleWithFid(uint256[] calldata _fids) external;

  function getOid(uint256 _fid) external view returns (uint256);

  function getOid(address _address) external view returns (uint256);

  function getSudoAddress(uint256 _oid) external view returns (address);

  function getRecoveryAddresses(uint256 _oid) external view returns (address[2] memory);

  function getPublicKeyAtIndex(uint256 _oid, uint256 _index) external view returns (bytes memory);

  function farcasterLink(uint256 _id, address _to) external;
}
