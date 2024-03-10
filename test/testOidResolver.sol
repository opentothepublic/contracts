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

contract ResolverHarness is OIDResolver {
  constructor(IEAS eas, IOidRegistry registry, address sudoer) OIDResolver(eas, registry, sudoer) {}

  function exposed_onAttest(Attestation calldata attestation, uint256 value) public returns (bool) {
    return onAttest(attestation, value);
  }

  function exposed_onRevoke(Attestation calldata attestation, uint256 value) public returns (bool) {
    return onRevoke(attestation, value);
  }
}

contract testOidResolver is Test {
  ResolverHarness resolver;
  OIDRegistry proxy;

  uint256 obiPrivKey = 0xB22ce;
  address obi = vm.addr(obiPrivKey);
  uint256 adaPrivKey = 0xA11ce;
  address ada = vm.addr(adaPrivKey);

  function setUp() public {
    OIDRegistry registry = new OIDRegistry();
    resolver = new ResolverHarness(IEAS(address(41)), registry, obi);
    proxy = OIDRegistry(
      payable(
        new ERC1967Proxy{salt: bytes32(0)}(
          address(registry),
          abi.encodeCall(OIDRegistry.initialize, (address(resolver), address(0)))
        )
      )
    );
    vm.prank(obi);
    resolver.setOidRegistry(proxy);
  }

  function getAttestation(
    address attester,
    uint256 fid
  ) internal view returns (Attestation memory) {
    return
      Attestation({
        uid: bytes32(0), // A unique identifier of the attestation.
        schema: 0x0e1dbd206812a0606bbf7b7ba593fe3b8d42ca2d5e009f8e529cd8f4b7ce8b1f, // The unique identifier of the schema.
        time: uint64(block.timestamp), // The time when the attestation was created (Unix timestamp).
        expirationTime: uint64(block.timestamp + 1 hours), // The time when the attestation expires (Unix timestamp).
        revocationTime: uint64(0), // The time when the attestation was revoked (Unix timestamp).
        refUID: bytes32(0), // The UID of the related attestation.
        recipient: address(0), // The recipient of the attestation.
        attester: attester, // The attester/sender of the attestation.
        revocable: false, // Whether the attestation is revocable.
        data: abi.encode(fid, "data") // Custom attestation data.
      });
  }

  function testAttest() public {
    uint256 fid = 2345222;
    resolver.exposed_onAttest(getAttestation(ada, fid), 0);
    assertEq(proxy.getOid(fid), proxy.getOid(ada));
  }

  function testRevoke() public {
    uint256 fid = 2345222;
    bool res = resolver.exposed_onRevoke(getAttestation(ada, fid), 0);
    assertTrue(res);
  }
}
