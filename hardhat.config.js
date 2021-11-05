require("@nomiclabs/hardhat-waffle")
require("@nomiclabs/hardhat-ethers")
// require("hardhat-deploy")
// require("@appliedblockchain/chainlink-plugins-fund-link")

require('dotenv').config()

//const MAINNET_RPC_URL = process.env.MAINNET_RPC_URL || process.env.ALCHEMY_MAINNET_RPC_URL || "https://eth-mainnet.alchemyapi.io/v2/your-api-key"
const KOVAN_RPC_URL = process.env.KOVAN_RPC_URL || "https://eth-kovan.alchemyapi.io/v2/your-api-key"
// const MNEMONIC = process.env.MNEMONIC || "your mnemonic"
const PRIVATE_KEY = process.env.PRIVATE_KEY || "your private key"

module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {},
    localhost: {},
    kovan: {
      url: KOVAN_RPC_URL,
      accounts: [PRIVATE_KEY],
      // accounts: {
      //   mnemonic: MNEMONIC,
      // },
      saveDeployments: true,
    },
    // mainnet: {
    //   url: MAINNET_RPC_URL,
    //   // accounts: [PRIVATE_KEY],
    //   accounts: {
    //     mnemonic: MNEMONIC,
    //   },
    //   saveDeployments: true,
    // },
  },
  solidity: {
    compilers: [
      {
        "version": "0.6.12"
      }
    ]
  },
};
