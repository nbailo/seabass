import {ethers} from "hardhat";
import {sleep, verify, keypress} from "../utils/helpers";
import {CircuitBreaker} from "../typechain-types";
import dotenv from "dotenv";

dotenv.config();

async function main() {
  const [owner] = await ethers.getSigners();
  const BASE = ethers.utils.parseEther("1");
  const percentages = ethers.BigNumber.from("10");
  const oracleDeviationLimit = percentages.mul(BASE).div(8640000); // 10% per day
  const externalContractAddress = process.env.EXTERNAL_CONTRACT_ADDRESS!;
  const externalContractFunction = process.env.EXTERNAL_CONTRACT_FUNCTION!;
  const priceFeedAddress = process.env.PRICE_FEED_ADDRESS!;

  console.log("Deploying contracts with the account:", owner.address);
  console.log("Oracle deviation limit percentages:", percentages.toString());
  console.log("Oracle deviation limit:", oracleDeviationLimit.toString());
  console.log("External contract address:", externalContractAddress);
  console.log("External contract function:", externalContractFunction);
  console.log("Price feed address:", priceFeedAddress);

  await keypress();

  const CircuitBreakerF = await ethers.getContractFactory("CircuitBreaker");
  const circuitBraker: CircuitBreaker = await CircuitBreakerF.deploy(
    priceFeedAddress,
    oracleDeviationLimit,
    externalContractAddress,
    externalContractFunction
  ) as CircuitBreaker;
  await circuitBraker.deployed();
  console.log("Circuit Braker contract deployed to:", circuitBraker.address);
  console.log("Sleeping for 60 seconds before verification...");
  await sleep(1000);
  console.log(">>>>>>>>>>>> Verification >>>>>>>>>>>>");

  await verify(circuitBraker.address, [
    priceFeedAddress,
    oracleDeviationLimit,
    externalContractAddress,
    externalContractFunction
  ]);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });