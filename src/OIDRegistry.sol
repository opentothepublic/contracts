// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@~/library/Structs.sol";
import "@~/abstract/UserRegistry.sol";
import {IOidRegistry} from "@~/interfaces/IOidRegistry.sol";

contract OIDRegistry is IOidRegistry, UserRegistry, Initializable, UUPSUpgradeable {
  address public resolver;

  address public eip1271;

  modifier onlyResolver() {
    if (msg.sender != resolver) revert NotResolver();
    _;
  }

  constructor() {
    _disableInitializers();
  }

  function initialize(address _resolver, address _eip1271) public initializer {
    resolver = _resolver;
    eip1271 = _eip1271;
  }

  /**
   * @inheritdoc IOidRegistry
   */
  function getOid(uint256 _fid) public view returns (uint256) {
    return fidToOid[_fid];
  }

  /**
   * @inheritdoc IOidRegistry
   */
  function getOid(address _address) public view returns (uint256) {
    return oidOf[_address];
  }

  /**
   * @inheritdoc IOidRegistry
   */
  function register() public {
    _register(msg.sender, [address(0), address(0)]);
  }

  /**
   * @inheritdoc IOidRegistry
   */
  function registerWithRecoveryAddresses(address _recovery1, address _recovery2) public {
    _register(msg.sender, [_recovery1, _recovery2]);
  }

  /**
   * @inheritdoc IOidRegistry
   */
  function registerWithFid(uint256 _fid, address _attester) public onlyResolver {
    _setFid(_fid, _register(_attester, [address(0), address(0)]));
  }

  /**
   * @inheritdoc IOidRegistry
   */
  function registerMultipleWithFid(
    uint256[] calldata _fids,
    address[] calldata _attesters
  ) public onlyResolver {
    if (_fids.length != _attesters.length) revert IndexOutOfBounds();
    for (uint256 i = 0; i < _fids.length; i++) {
      _setFid(_fids[i], _register(_attesters[i], [address(0), address(0)]));
    }
  }

  /*//////////////////////////////////////////////////////////////
                              INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

  function _createOid(address user) internal returns (uint256 id) {
    if (oidOf[user] != 0) revert AlreadyRegistered();
    id = ++oidCounter;
    oidOf[user] = id;
  }

  function _register(address _to, address[2] memory recovery) internal returns (uint256 id) {
    id = _createOid(_to);
    _createUser(id, _to, recovery, eip1271);
  }

  function _setFid(uint256 _fid, uint256 _oid) internal {
    if (fidToOid[_fid] != 0) revert AlreadyRegistered();
    fidToOid[_fid] = _oid;
  }

  function _authorizeUpgrade(address newImplementation) internal view override onlyResolver {
    (newImplementation);
  }
}
