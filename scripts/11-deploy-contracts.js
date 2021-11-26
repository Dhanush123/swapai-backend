'use strict';

const { runTask } = require('./helper/utils');

const deployOracleMaster = require('./05-deploy-oracle-master');
const fundOracleMaster   = require('./06-fund-oracle-master');
const deployTokenSwapper = require('./07-deploy-token-swapper');
const deploySwapAI       = require('./08-deploy-swapai');

async function deployContracts() {
  await deployOracleMaster();
  await fundOracleMaster();
  await deployTokenSwapper();
  await deploySwapAI();
}

module.exports = deployContracts;

// Only run the task if it's not imported as a module
if (typeof require !== 'undefined' && require.main === module) {
  runTask(deployContracts);
}
