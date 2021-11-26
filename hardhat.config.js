require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");

require('dotenv').config();

const KOVAN_RPC_URL = process.env.KOVAN_RPC_URL || "https://eth-kovan.alchemyapi.io/v2/your-api-key";
const PRIVATE_KEY = process.env.PRIVATE_KEY || "your private key";
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || "etherscan API key";

module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {},
    localhost: {},
    kovan: {
      url: KOVAN_RPC_URL,
      accounts: [PRIVATE_KEY],
      saveDeployments: true,
    },
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY
  },
  solidity: {
    version: "0.6.12",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
      debug: {
        revertStrings: "debug"
      }
    }
  }
};
