// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SampleLib} from "../lib/SampleLib.sol";
import {UsingDiamondOwner} from "hardhat-deploy/solc_0.8/diamond/UsingDiamondOwner.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

contract SampleFacet is ReentrancyGuardUpgradeable, UsingDiamondOwner {
  function increment() external onlyOwner {
    SampleLib.SampleStorage storage ss = SampleLib._getSampleStorage();

    ss._counter += 1;
  }

  function decrement() external nonReentrant {
    SampleLib.SampleStorage storage ss = SampleLib._getSampleStorage();

    ss._counter -= 1;
  }

  function getCounter() external view returns (uint256) {
    SampleLib.SampleStorage memory ss = SampleLib._getSampleStorage();

    return ss._counter;
  }
}
