'use strict';

const { printTitle, runTask } = require('./helper/utils');

const deployOracleMaster = require('./05-deploy-oracle-master');
const fundOracleMaster   = require('./06-fund-oracle-master');
const deployTokenSwapper = require('./07-deploy-token-swapper');
const deploySwapAI       = require('./08-deploy-swapai');

async function deployContracts() {
  printTitle('Deploying Oracle Master');
  await deployOracleMaster();

  printTitle('Funding Oracle Master');
  await fundOracleMaster();

  printTitle('Deploying Token Swapper');
  await deployTokenSwapper();

  printTitle('Deploying SwapAI');
  await deploySwapAI();
}

module.exports = deployContracts;

// Only run the task if it's not imported as a module
if (typeof require !== 'undefined' && require.main === module) {
  runTask(deployContracts);
}
