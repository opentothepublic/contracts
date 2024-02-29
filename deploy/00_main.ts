import { DeployFunction } from "hardhat-deploy/types";
import { Ship } from "../utils";
import { InitFacet__factory, SampleFacet__factory } from "../types";

const func: DeployFunction = async (hre) => {
  const { deployDiamond } = await Ship.init(hre);

  await deployDiamond("Sample", [InitFacet__factory, SampleFacet__factory], InitFacet__factory, "init", [0n]);
};

export default func;
func.tags = ["init"];
