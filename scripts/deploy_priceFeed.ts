import {ethers} from "hardhat";
import {sleep, verify} from "../utils/helpers";
import {AggregatorMock} from "../typechain-types";

async function main() {
  const PriceFeedF = await ethers.getContractFactory("AggregatorMock");
  const priceFeed: AggregatorMock = await PriceFeedF.deploy() as AggregatorMock;
  await priceFeed.deployed();
  console.log("Price Feed contract deployed to:", priceFeed.address);
  console.log("Sleeping for 60 seconds before verification...");
  await sleep(1000);
  console.log(">>>>>>>>>>>> Verification >>>>>>>>>>>>");

  await verify(priceFeed.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });