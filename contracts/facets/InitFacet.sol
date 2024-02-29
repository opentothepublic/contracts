// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UsingDiamondOwner, LibDiamond} from "hardhat-deploy/solc_0.8/diamond/UsingDiamondOwner.sol";
import {IERC165} from "hardhat-deploy/solc_0.8/diamond/interfaces/IERC165.sol";
import {IDiamondCut} from "hardhat-deploy/solc_0.8/diamond/interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "hardhat-deploy/solc_0.8/diamond/interfaces/IDiamondLoupe.sol";
import {IERC173} from "hardhat-deploy/solc_0.8/diamond/interfaces/IERC173.sol";
import {SampleLib} from "../lib/SampleLib.sol";

contract InitFacet is UsingDiamondOwner, Initializable {
  function ds() internal pure returns (LibDiamond.DiamondStorage storage) {
    return LibDiamond.diamondStorage();
  }

  function ss() internal pure returns (SampleLib.SampleStorage storage) {
    return SampleLib._getSampleStorage();
  }

  function init(uint256 _start) external onlyOwner initializer {
    ss()._counter = _start;

    ds().supportedInterfaces[type(IERC165).interfaceId] = true;
    ds().supportedInterfaces[type(IDiamondCut).interfaceId] = true;
    ds().supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
    ds().supportedInterfaces[type(IERC173).interfaceId] = true;
  }
}
