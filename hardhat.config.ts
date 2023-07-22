import dotenv from "dotenv";
import "@nomiclabs/hardhat-web3";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-etherscan";
import "hardhat-contract-sizer";
import "@typechain/hardhat";
import "@nomicfoundation/hardhat-toolbox";
import "./tasks/full_clean";
import "hardhat-gas-reporter";
import yn from "yn";

dotenv.config();

const ethers = require("ethers");

const developmentMnemonic =
  "test test test test test test test test test test test junk";

const providerUrl = process.env.MAINNET_PROVIDER_URL;
const accounts = process.env.DEPLOYER_PRIVATE_KEY
  ? [process.env.DEPLOYER_PRIVATE_KEY]
  : [];

function getPrivateKeysFromMnemonic(
  mnemonic: string,
  numberOfPrivateKeys = 20
) {
  const result: any = [];
  for (let i = 0; i < numberOfPrivateKeys; i++) {
    try {
      result.push(
        ethers.Wallet.fromMnemonic(mnemonic, `m/44'/60'/0'/0/${i}`).privateKey
      );
    } catch (Exception) {}
  }
}

module.exports = {
  solidity: {
    version: "0.8.13",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    hardhat: {
      gasPrice: 0,
      initialBaseFeePerGas: 0,
      loggingEnabled: false,
      accounts: {
        mnemonic: developmentMnemonic,
        count: 30,
        accountsBalance: "1000000000000000000000000",
      },
      allowUnlimitedContractSize: true,
      chainId: 1, // metamask -> accounts -> settings -> networks -> localhost 8545 -> set chainId to 1
    },
    localhost: {
      url: "http://localhost:8545",
      accounts: getPrivateKeysFromMnemonic(developmentMnemonic),
      gas: 2100000,
      gasPrice: 8000000000,
      allowUnlimitedContractSize: true,
    },
    polygon: {
      url: providerUrl || process.env.MAINNET_POLYGON_PROVIDER_URL || "",
      chainId: 137,
      gasPrice: Number(process.env.GAS_PRICE_POLYGON),
      accounts,
      addressesSet: "polygon",
    }
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_APIKEY,
  },
  mocha: {
    timeout: 700000,
  },
  contractSizer: {
    alphaSort: true,
    runOnCompile: yn(process.env.REPORT_CONTRACT_SIZE),
    disambiguatePaths: false,
  },
  typechain: {
    outDir: "typechain-types",
    target: "ethers-v5",
  },
  gasReporter: {
    enabled: yn(process.env.REPORT_GAS),
  },
};
