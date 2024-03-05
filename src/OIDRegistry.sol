// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@~/library/Structs.sol";
import "@~/UserRegistry.sol";

error NotRegistered();
error AlreadyRegistered();
error NotSudoable();
error NotRegistrar();
error NotResolver();

// we can use create 2 to determine the address of this contract. enabling us to deploy the resolver before this
contract OIDRegistry is UserRegistry {
  uint256 public oidCounter;

  mapping(address owner => uint256 oid) oidOf;

  mapping(uint256 fid => uint256 oid) fidToOid;

  address public immutable resolver;

  address public immutable registrar;

  address public immutable eip1271;

  modifier onlyRegistrar() {
    if (msg.sender != registrar) revert NotRegistrar();
    _;
  }

  modifier onlyResolver() {
    if (msg.sender != resolver) revert NotResolver();
    _;
  }

  constructor(address _resolver, address _registrar, address _eip1271) {
    oidCounter = 1;
    resolver = _resolver;
    registrar = _registrar;
    eip1271 = _eip1271;
  }

  function register() public {
    uint256 id = _createOid(msg.sender);
    _createUser(id, msg.sender, [address(0), address(0)], eip1271);
  }

  function registerWithRecoveryAddresses(address _recovery1, address _recovery2) public {
    uint256 id = _createOid(msg.sender);
    _createUser(id, msg.sender, [_recovery1, _recovery2], eip1271);
  }

  function _createOid(address user) internal returns (uint256 id) {
    if (oidOf[user] != 0) revert AlreadyRegistered();
    id = ++oidCounter;
    oidOf[user] = id;
  }

  function registerWithFid(uint256 _fid) public onlyRegistrar {
    _setFid(_fid, ++oidCounter);
  }

  function registerMultipleWithFid(uint256[] calldata _fids) public onlyRegistrar {
    for (uint256 i = 0; i < _fids.length; i++) {
      _setFid(_fids[i], ++oidCounter);
    }
  }

  function getOid(uint256 _fid) public view returns (uint256) {
    return fidToOid[_fid];
  }

  function getOid(address _address) public view returns (uint256) {
    return oidOf[_address];
  }

  function getSudoAddress(uint256 _oid) public view returns (address) {
    return accounts[_oid].sudo;
  }

  function getRecoveryAddresses(uint256 _oid) public view returns (address[2] memory) {
    return accounts[_oid].recovery;
  }

  function getPublicKeyAtIndex(uint256 _oid, uint256 _index) public view returns (bytes memory) {
    if (!(_index < 3)) revert IndexOutOfBounds();
    return accounts[_oid].publicKeys[_index].key;
  }

  function farcasterLink(uint256 _id, address _to) external onlyResolver {
    if (oidOf[_to] != 0) {
      fidToOid[_id] = oidOf[_to];
    } else {
      oidOf[_to] = fidToOid[_id];
      _createUser(fidToOid[_id], msg.sender, [address(0), address(0)], eip1271);
    }
  }

  function _setFid(uint256 _fid, uint256 _oid) internal {
    if (fidToOid[_fid] != 0) revert AlreadyRegistered();
    fidToOid[_fid] = _oid;
  }

  // fn recover -> initiates user defined oid recovery

  // fn sudoRecover -> initiates protocol based recovery if user is sudoable
}
