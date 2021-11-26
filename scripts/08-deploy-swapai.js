'use strict';

const { FRONTEND_CONTRACTS_DIR, ARTIFACTS_DIR, CONTRACT_ADDRESSES_FILE } = require('./helper/constants');
const { readJsonFile, runTask } = require('./helper/utils');

const ContractDeployer = require('./helper/ContractDeployer');

async function deploySwapAI() {
  const {
    TUSDToken: TUSD_TOKEN_ADDR,
    WBTCToken: WBTC_TOKEN_ADDR,
    OracleMaster: ORACLE_MASTER_ADDR,
    TokenSwapper: TOKEN_SWAPPER_ADDR,
  } = readJsonFile(`${ARTIFACTS_DIR}/${CONTRACT_ADDRESSES_FILE}`);

  const contractDeployer = new ContractDeployer()
    .addContract({
      name: 'SwapAI',
      args: [
        TUSD_TOKEN_ADDR, WBTC_TOKEN_ADDR,
        ORACLE_MASTER_ADDR, TOKEN_SWAPPER_ADDR
      ],
      verify: true
    })
    .addExportDir({ dir: FRONTEND_CONTRACTS_DIR, file: CONTRACT_ADDRESSES_FILE })
    .addExportDir({ dir: ARTIFACTS_DIR, file: CONTRACT_ADDRESSES_FILE });

  await contractDeployer.deploy();
}

module.exports = deploySwapAI;

// Only run the task if it's not imported as a module
if (typeof require !== 'undefined' && require.main === module) {
  runTask(deploySwapAI);
}
