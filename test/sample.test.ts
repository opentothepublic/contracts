import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import chai from "chai";
import { Contract, ZeroAddress } from "ethers";
import { deployments } from "hardhat";
import { SampleFacet, SampleFacet__factory } from "../types";
import { Ship, advanceTimeAndBlock } from "../utils";

const { expect } = chai;

let ship: Ship;
let sample: SampleFacet;

let deployer: SignerWithAddress;
let signer: SignerWithAddress;

const setup = deployments.createFixture(async (hre) => {
  ship = await Ship.init(hre);
  const { accounts, users } = ship;
  await deployments.fixture(["init"]);

  return {
    ship,
    accounts,
    users,
  };
});

describe("Sample Diamond test", function () {
  before(async () => {
    const scaffold = await setup();

    deployer = scaffold.accounts.deployer;
    signer = scaffold.accounts.signer;

    const diamond = await ship.connect("Sample");
    sample = SampleFacet__factory.connect((diamond as Contract).target as string, deployer);
  });

  it("increments counter", async () => {
    await sample.increment();
    expect(await sample.getCounter()).to.equal(1n);
  });

  it("decrements counter", async () => {
    await advanceTimeAndBlock(60); // increment block.timestamp
    await sample.connect(signer).decrement();
    expect(await sample.getCounter()).to.equal(0n);
  });
});
