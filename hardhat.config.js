require("@nomiclabs/hardhat-waffle")
require("@nomiclabs/hardhat-ethers")
// require("hardhat-deploy")
// require("@appliedblockchain/chainlink-plugins-fund-link")

require('dotenv').config()

const KOVAN_RPC_URL = process.env.KOVAN_RPC_URL || "https://eth-kovan.alchemyapi.io/v2/your-api-key"
const PRIVATE_KEY = process.env.PRIVATE_KEY || "your private key"

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
  solidity: {
    compilers: [
      {
        version: "0.6.12",
        optimizer: {
          enabled: true,
          runs: 200,
        },
      }
    ]
  },
};
