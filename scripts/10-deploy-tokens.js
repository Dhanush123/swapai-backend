'use strict';

const { printTitle, runTask } = require('./helper/utils');

const mintTokens          = require('./01-mint-tokens');
const deployPoolLiquifier = require('./02-deploy-pool-liquifier');
const addLiquidity        = require('./03-add-liquidity');

async function deployTokens() {
  printTitle('Minting Tokens');
  await mintTokens();

  printTitle('Deploying Pool Liquifier');
  await deployPoolLiquifier();

  printTitle('Adding Liquidity');
  await addLiquidity();
}

module.exports = deployTokens;

// Only run the task if it's not imported as a module
if (typeof require !== 'undefined' && require.main === module) {
  runTask(deployTokens);
}
