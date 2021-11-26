'use strict';

const { ARTIFACTS_DIR, CONTRACT_ADDRESSES_FILE } = require('./helper/constants');
const { readJsonFile, runTask } = require('./helper/utils');

const ContractDeployer = require('./helper/ContractDeployer');

async function deployTokenSwapper() {
  const {
    TUSDToken: TUSD_TOKEN_ADDR,
    WBTCToken: WBTC_TOKEN_ADDR,
  } = readJsonFile(`${ARTIFACTS_DIR}/${CONTRACT_ADDRESSES_FILE}`);

  const contractDeployer = new ContractDeployer()
    .addContract({ name: 'TokenSwapper', args: [TUSD_TOKEN_ADDR, WBTC_TOKEN_ADDR], verify: true })
    .addExportDir({ dir: ARTIFACTS_DIR, file: CONTRACT_ADDRESSES_FILE });

  await contractDeployer.deploy();
}

module.exports = deployTokenSwapper;

// Only run the task if it's not imported as a module
if (typeof require !== 'undefined' && require.main === module) {
  runTask(deployTokenSwapper);
}
