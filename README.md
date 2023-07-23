![Alt text](telegram-cloud-document-2-5323350060581270721.jpg)


This is a subscription-based circuit breaker system leveraging the power of Chainlink. The system monitors specific Chainlink price feeds for fluctuations beyond a user-defined threshold. Upon reaching this threshold, it performs a pre-set action, all in a decentralized and automated manner.

The Factory design pattern is used to create user-specific Circuit Breaker contracts, and Chainlink Upkeeps ensure the system operates continuously. Moreover, the system includes a unique method for swapping LINK tokens from ERC-20 to ERC-677 standards to fund upkeep operations.

## Prerequisites
- Node.js (version 14 or higher)
- npm (version 6 or higher)
- Hardhat

## Project Setup
Clone the repository and install the dependencies:

    git clone https://github.com/nbailo/seabass.git
    cd seabass
    yarn

## Environment Variables
Create a .env file in the root directory of your project and add the following variables:


    DEPLOYER_PRIVATE_KEY=<your-private-key>
    MAINNET_POLYGON_PROVIDER_URL=<polygon-rpc-url>
    GAS_PRICE_POLYGON=<polygon-gas-price>
    ETHERSCAN_APIKEY=<your-etherscan-api-key>

- DEPLOYER_PRIVATE_KEY: Your Ethereum private key, which you will use to deploy contracts.
- MAINNET_POLYGON_PROVIDER_URL: The RPC URL of the Polygon network you are connecting to.
- GAS_PRICE_POLYGON: The gas price for transactions on the Polygon network.
- ETHERSCAN_APIKEY: Your Etherscan API key for verifying contracts on Polygon scan.

Ensure to replace <your-private-key>, <polygon-rpc-url>, <polygon-gas-price>, and <your-etherscan-api-key> with your actual details.

## Compilation
Compile the Solidity smart contracts:

    yarn compile

## Deployment
Deploy the smart contracts on the Polygon network:

    npx hardhat run --network polygon scripts/deploy_circuitBreakerFactory.ts


## License
This project is licensed under the MIT License.

For more detailed information about the system, refer to the contract comments within the codebase.