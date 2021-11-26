'use strict';

const {
  FRONTEND_CONTRACTS_DIR, ARTIFACTS_DIR, CONTRACT_ADDRESSES_FILE,
  TUSD_STARTING_AMOUNT, WBTC_STARTING_AMOUNT,
} = require('./helper/constants');

const { runTask } = require('./helper/utils');

const ContractDeployer = require('./helper/ContractDeployer');

async function mintTokens() {
  const testerAddress1 = ethers.utils.getAddress(process.env.TESTER_ADDR_1);
  const testerAddress2 = ethers.utils.getAddress(process.env.TESTER_ADDR_2);

  // Deploy our new tokens, with both testers holding *all* of the supply of tokens
  const contractDeployer = new ContractDeployer()
    .addContract({
      name: 'TUSDToken',
      args: [
        testerAddress1, TUSD_STARTING_AMOUNT,
        testerAddress2, TUSD_STARTING_AMOUNT,
      ]
    })
    .addContract({
      name: 'WBTCToken',
      args: [
        testerAddress1, WBTC_STARTING_AMOUNT,
        testerAddress2, WBTC_STARTING_AMOUNT,
      ]
    })
    .addExportDir({ dir: FRONTEND_CONTRACTS_DIR, file: CONTRACT_ADDRESSES_FILE })
    .addExportDir({ dir: ARTIFACTS_DIR, file: CONTRACT_ADDRESSES_FILE });

  await contractDeployer.deploy();
}

module.exports = mintTokens;

// Only run the task if it's not imported as a module
if (typeof require !== 'undefined' && require.main === module) {
  runTask(mintTokens);
}
