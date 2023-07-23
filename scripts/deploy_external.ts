import {ethers} from "hardhat";
import {sleep, verify} from "../utils/helpers";
import {External} from "../typechain-types";

async function main() {
  const ExternalF = await ethers.getContractFactory("External");
  const external: External = await ExternalF.deploy() as External;
  await external.deployed();
  console.log("External contract deployed to:", external.address);
  console.log("Sleeping for 60 seconds before verification...");
  await sleep(1000);
  console.log(">>>>>>>>>>>> Verification >>>>>>>>>>>>");

  await verify(external.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });