import {ethers} from "hardhat";
import {sleep, verify, keypress} from "../utils/helpers";
import {CircuitBreakerFactory} from "../typechain-types";
import dotenv from "dotenv";

dotenv.config();

async function main() {
  // Deploy on Polygon Mainnet
  const link20 = "0x53E0bca35eC356BD5ddDFebbD1Fc0fD03FaBad39"; // LINK ERC20 token on Polygon
  const link677 = "0xb0897686c545045aFc77CF20eC7A532E3120E0F1"; // LINK ERC677 token on Polygon
  const registrar = "0xDb8e8e2ccb5C033938736aa89Fe4fa1eDfD15a1d"; // Polygon Registrar
  const registry = "0x02777053d6764996e594c3E88AF1D58D5363a2e6"; // Polygon Keeper Registry
  const pegSwap = "0xAA1DC356dc4B18f30C347798FD5379F3D77ABC5b"; // Polygon PegSwap

  const [owner] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", owner.address);
  console.log("Polygon LINK20 address:", link20);
  console.log("Polygon LINK677 address:", link677);
  console.log("Polygon Registrar address:", registrar);
  console.log("Polygon Registry address:", registry);
  console.log("Polygon PegSwap address:", pegSwap);

  await keypress();

  const CircuitBreakerFactoryF = await ethers.getContractFactory("CircuitBreakerFactory");

  const circuitBrakerFactory: CircuitBreakerFactory = await CircuitBreakerFactoryF.deploy(
    link20,
    link677,
    registrar,
    registry,
    pegSwap,
    owner.address
  ) as CircuitBreakerFactory;
  await circuitBrakerFactory.deployed();
  console.log("Circuit Breaker Factory contract deployed to:", circuitBrakerFactory.address);
  console.log("Sleeping for 60 seconds before verification...");
  await sleep(1000);
  console.log(">>>>>>>>>>>> Verification >>>>>>>>>>>>");

  await verify(circuitBrakerFactory.address, [
    link20,
    link677,
    registrar,
    registry,
    pegSwap,
    owner.address
  ]);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });