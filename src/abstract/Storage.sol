// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {OTTPUser} from "@~/library/Structs.sol";

abstract contract Storage {
  uint256 public oidCounter;

  mapping(address owner => uint256 oid) oidOf;

  mapping(uint256 fid => uint256 oid) fidToOid;

  mapping(uint256 oid => OTTPUser) accounts;

  mapping(uint256 oid => mapping(address sudo => bool active)) public sudoable;
}
