// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library SampleLib {
  struct SampleStorage {
    uint256 _counter;
  }

  // keccak256(abi.encode(uint256(keccak256("diamon.storage.sample")) - 1)) & ~bytes32(uint256(0xff));
  bytes32 private constant SampleStorageLocation =
    0x8356a23936d9181410b4eb87f7ea6c98d92f0b339d590a092fe7e438640c3900;

  function _getSampleStorage() internal pure returns (SampleStorage storage $) {
    assembly {
      $.slot := SampleStorageLocation
    }
  }
}
