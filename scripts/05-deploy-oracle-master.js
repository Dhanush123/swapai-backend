'use strict';

const { ARTIFACTS_DIR, CONTRACT_ADDRESSES_FILE } = require('./helper/constants');
const { readJsonFile, runTask } = require('./helper/utils');

const ContractDeployer = require('./helper/ContractDeployer');

async function deployOracleMaster() {
  const contractDeployer = new ContractDeployer()
    .addContract({ name: 'OracleMaster', verify: true })
    .addExportDir({ dir: ARTIFACTS_DIR, file: CONTRACT_ADDRESSES_FILE });

  await contractDeployer.deploy();
}

module.exports = deployOracleMaster;

// Only run the task if it's not imported as a module
if (typeof require !== 'undefined' && require.main === module) {
  runTask(deployOracleMaster);
}
