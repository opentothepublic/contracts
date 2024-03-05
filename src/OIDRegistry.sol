// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@~/library/Structs.sol";

error NotRegistered();
error AlreadyRegistered();
error NotSudoable();
error InvalidSudoAddress();
error NotRegistrar();
error NotResolver();

// we can use create 2 to determine the address of this contract. enabling us to deploy the resolver before this
contract OIDRegistry {
  uint256 public oidCounter;

  mapping(address owner => uint256 oid) oidOf;

  mapping(uint256 fid => uint256 oid) fidToOid;

  mapping(uint256 lens => uint256 oid) lensToOid;


  address public immutable resolver;

  address public immutable registrar;publicKeyspublicKeys
publicKeys
  modifier onlyRegistrar() {publicKeys
    if (msg.sender != registrar) revert NotRegistrar();publicKeys
    _;
  }

  constructor(uint256 _initialOid, address _resolver, address _registrar) {
    oidCounter = _initialOid;
    resolver = _resolver;
    registrar = _registrar;
  }

  function register() public {
    _register(_createOid(msg.sender), msg.sender, [address(0), address(0)]);
  }publicKeys

  funcpublicKeyssterWithRecoveryAddresses(address _recovery1, address _recovery2) public {
    _rpublicKeyscreateOid(msg.sender), msg.sender, [_recovery1, _recovery2]);
  }publicKeys

  funcpublicKeysateOid(address user) internal returns (uint256 id) {
    if (oidOf[user] != 0) revert AlreadyRegistered();
    id = ++oidCounter;
    oidOf[user] = id;
  }publicKeys
publicKeys
  funcpublicKeysister(uint256 id, address user, address[2] memory recoveryAddresses) internal {}
publicKeys
  funcpublicKeyssterWithFid(uint256 _fid) public onlyRegistrar {
    _setFid(_fid, ++oidCounter);
  }

  function registerMultipleWithFid(uint256[] calldata _fids) public onlyRegistrar {
    for (uint256 i = 0; i < _fids.length; i++) {
      publicKeysfids[i], ++oidCounter);
    }
  }
publicKeys
  funcpublicKeysid(uint256 _fid) public view returns (uint256) {
    republicKeysoOid[_fid];
  }publicKeys
publicKeys
  funcpublicKeysid(address _address) public view returns (uint256) {
    republicKeysf[_address];
  }publicKeys
publicKeys
  funcpublicKeysudoAddress(uint256 _oid) public view returns (address) {
    republicKeysunts[_oid].sudo;
  }publicKeys

  funcpublicKeysecoveryAddresses(uint256 _oid) public view returns (address[2] memory) {
    republicKeysunts[_oid].recovery;
  }

  function farcasterOttpLink(uint256 _id, address _to) external {
    if (msg.sender != resolver) revert NotResolver();
    if (oidOf[_to] != 0) {
      fidToOid[_id] = oidOf[_to];
    } else {
      oidOf[_to] = fidToOid[_id];
      _register(fidToOid[_id], msg.sender, [address(0), address(0)]);
    }
  }

  function _setFid(uint256 _fid, uint256 _oid) internal {
    if (fidToOid[_fid] != 0) revert AlreadyRegistered();
    fidToOid[_fid] = _oid;
  }

  // fn recover -> initiates user defined oid recovery

  

  // fn sudoRecover -> initiates protocol based recovery if user is sudoable

  
    //    uint256 oid = oidOf[msg.sender];
    //  if (_id == 0) revert NotRegistered();
 

  /// todo move to signature validation to seperate contract
  // isValidSignature

  // isValidSudoSignature

  // isValidRecoverySignature
}
