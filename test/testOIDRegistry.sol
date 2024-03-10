// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";

import "@~/OIDRegistry.sol";
import "@~/OIDResolver.sol";
import "@~/utils/ERC1271.sol";
import "@~/interfaces/IUserRegistry.sol";
import "@~/interfaces/IOidRegistry.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract RegistryHarness is OIDRegistry {
  constructor() OIDRegistry() {}

  function exposed_createOid(address user) public returns (uint256) {
    return _createOid(user);
  }

  function exposed_createUser(
    uint256 id,
    address user,
    address[2] memory recoveryAddresses,
    address sigVerifier
  ) public {
    _createUser(id, user, recoveryAddresses, sigVerifier);
  }

  function exposed_setFid(uint256 _fid, uint256 _oid) public {
    _setFid(_fid, _oid);
  }

  function exposed_register(address _to, address[2] memory recovery) public {
    _register(_to, recovery);
  }
}

contract testOIDRegistry is Test {
  RegistryHarness registry;
  RegistryHarness proxy;

  uint256 obiPrivKey = 0xB22ce;
  address obi = vm.addr(obiPrivKey);
  uint256 adaPrivKey = 0xA11ce;
  address ada = vm.addr(adaPrivKey);

  address resolver = address(0x123456789);

  function setUp() public {
    registry = new RegistryHarness();

    proxy = RegistryHarness(
      payable(
        new ERC1967Proxy{salt: bytes32(0)}(
          address(registry),
          abi.encodeCall(OIDRegistry.initialize, (resolver, address(0)))
        )
      )
    );
  }

  function testCreateOid() public {
    assertEq(proxy.getOid(obi), 0);
    proxy.exposed_createOid(obi);
    assertEq(proxy.getOid(obi), 1);
    vm.expectRevert(IUserRegistry.AlreadyRegistered.selector);
    proxy.exposed_createOid(obi);

    assertEq(proxy.getOid(ada), 0);
    proxy.exposed_createOid(ada);
    assertEq(proxy.getOid(ada), 2);
    vm.expectRevert(IUserRegistry.AlreadyRegistered.selector);
    proxy.exposed_createOid(ada);
  }

  function testCreateUser() public {
    assertEq(proxy.getOid(obi), 0);
    uint256 id = proxy.exposed_createOid(obi);

    proxy.exposed_createUser(id, obi, [address(0), address(0)], address(0));

    vm.startPrank(obi);
    bytes memory key = proxy.getPublicKeyAtIndex(id, 0);
    address _obi = address(bytes20(key));
    assertEq(_obi, obi);
    vm.stopPrank();
  }

  function testSetFid() public {
    uint256 oid = proxy.exposed_createOid(obi);
    uint256 fid = 2345222;
    proxy.exposed_setFid(fid, oid);

    assertEq(proxy.getOid(fid), oid);

    vm.expectRevert(IUserRegistry.AlreadyRegistered.selector);
    proxy.exposed_setFid(fid, oid);
  }

  function testRegister() public {
    vm.startPrank(obi);
    proxy.register();
    vm.expectRevert(IUserRegistry.AlreadyRegistered.selector);
    proxy.register();
    bytes memory key = proxy.getPublicKeyAtIndex(proxy.getOid(obi), 0);
    address _obi = address(bytes20(key));
    assertEq(_obi, obi);
    vm.stopPrank();

    vm.startPrank(ada);
    proxy.register();
    vm.expectRevert(IUserRegistry.AlreadyRegistered.selector);
    proxy.register();
    key = proxy.getPublicKeyAtIndex(proxy.getOid(ada), 0);
    address _ada = address(bytes20(key));
    assertEq(_ada, ada);
    vm.stopPrank();

    assertEq(proxy.getOid(obi), 1);
    assertEq(proxy.getOid(ada), 2);
  }

  function testRegisterWithRecoveryAddresses() public {
    vm.startPrank(obi);
    proxy.registerWithRecoveryAddresses(ada, address(0));
    vm.expectRevert(IUserRegistry.AlreadyRegistered.selector);
    proxy.register();
    bytes memory key = proxy.getPublicKeyAtIndex(proxy.getOid(obi), 0);
    address _obi = address(bytes20(key));
    assertEq(_obi, obi);

    address[2] memory recovery = proxy.getRecoveryAddresses(proxy.getOid(obi));
    assertEq(recovery[0], ada);
    assertEq(recovery[1], address(0));
    vm.stopPrank();
  }

  function testRegisterWithFid() public {
    uint256 fid = 2345222;
    vm.expectRevert(IOidRegistry.NotResolver.selector);
    proxy.registerWithFid(fid, obi);
    vm.startPrank(resolver);
    proxy.registerWithFid(fid, obi);
    assertEq(proxy.getOid(fid), proxy.getOid(obi));
  }
}
