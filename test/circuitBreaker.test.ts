import {ethers} from "hardhat";
import {loadFixture, time} from "@nomicfoundation/hardhat-network-helpers";
import {expect} from "chai";
import {ERC20Test} from "../typechain-types";

describe("CircuitBreaker", async () => {
  async function deployFixture() {
    let paymentToken: ERC20Test;

    const [owner, wallet, user1, user2] = await ethers.getSigners();

    const paymentTokenF = await ethers.getContractFactory("ERC20Test", owner);
    paymentToken = await paymentTokenF.deploy("Payment Token", "LINK");
    await paymentToken.deployed();

    paymentToken.transfer(user1.address, ethers.utils.parseEther("1000"));

    return {
      paymentToken,
      owner,
      wallet,
      user1,
      user2,
    };
  }

  it("should deploy", async () => {
    const {paymentToken} = await loadFixture(deployFixture);
    expect(paymentToken.address).to.be.properAddress;
  });
});
