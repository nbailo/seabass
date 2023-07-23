import {ethers} from "hardhat";
import {loadFixture} from "@nomicfoundation/hardhat-network-helpers";
import {expect} from "chai";
import {
  ERC20Test,
  CircuitBreaker,
  AggregatorMock,
  External,
} from "../typechain-types";

describe("CircuitBreaker", async () => {
  async function deployFixture() {
    let paymentToken: ERC20Test,
      priceFeed: AggregatorMock,
      externalContract: External,
      circuitBreaker: CircuitBreaker;

    const [owner, wallet, user1, user2] = await ethers.getSigners();

    const paymentTokenF = await ethers.getContractFactory("ERC20Test", owner);
    paymentToken = await paymentTokenF.deploy("Payment Token", "LINK");
    await paymentToken.deployed();

    const priceFeedF = await ethers.getContractFactory("AggregatorMock", owner);
    priceFeed = await priceFeedF.deploy();
    await priceFeed.deployed();

    const externalContractF = await ethers.getContractFactory(
      "External",
      owner
    );
    externalContract = await externalContractF.deploy();
    await externalContract.deployed();

    const BASE = ethers.utils.parseEther("1");
    const percentages = ethers.BigNumber.from("10");
    const oracleDeviationLimit = percentages.mul(BASE).div(8640000); // 10% per day

    const circuitBreakerF = await ethers.getContractFactory(
      "CircuitBreaker",
      owner
    );
    circuitBreaker = await circuitBreakerF.deploy(
      owner.address,
      priceFeed.address,
      oracleDeviationLimit,
      externalContract.address,
      "update()"
    );

    paymentToken.transfer(user1.address, ethers.utils.parseEther("1000"));

    return {
      paymentToken,
      priceFeed,
      externalContract,
      circuitBreaker,
      owner,
      wallet,
      user1,
      user2,
    };
  }

  it("should deploy", async () => {
    const {paymentToken, priceFeed, externalContract, circuitBreaker} =
      await loadFixture(deployFixture);
    expect(paymentToken.address).to.be.properAddress;
    expect(priceFeed.address).to.be.properAddress;
    expect(externalContract.address).to.be.properAddress;
    expect(circuitBreaker.address).to.be.properAddress;
  });

  it("should set upkeep is needed when price has fluctuation", async () => {
    const {priceFeed, circuitBreaker} = await loadFixture(deployFixture);

    const latestRoundData = await priceFeed.latestRoundData();
    const latestAnswer = latestRoundData.answer;
    // new latest answer is 2% less than the current latest answer
    const newLatestAnswer = latestAnswer.sub(latestAnswer.mul(2).div(100));
    expect((await circuitBreaker.checkUpkeep("0x")).upkeepNeeded).to.be.false;
    await priceFeed.updateRate(8, newLatestAnswer);
    expect((await circuitBreaker.checkUpkeep("0x")).upkeepNeeded).to.be.true;
  });

  it("should perform upkeep", async () => {
    const {circuitBreaker, externalContract} = await loadFixture(deployFixture);

    expect(await externalContract.getStatus()).to.be.true;
    await circuitBreaker.performUpkeep("0x");
    expect(await externalContract.getStatus()).to.be.false;
  });
});
