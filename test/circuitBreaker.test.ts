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

    const oracleDeviationLimit = ethers.BigNumber.from("115740740740740"); // 10% per day

    const circuitBreakerF = await ethers.getContractFactory(
      "CircuitBreaker",
      owner
    );
    circuitBreaker = await circuitBreakerF.deploy(
      priceFeed.address,
      oracleDeviationLimit,
      externalContract.address,
      paymentToken.address
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
});
