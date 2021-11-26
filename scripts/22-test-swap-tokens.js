'use strict';

const fs = require('fs');

const {
  ARTIFACTS_DIR, CONTRACT_ADDRESSES_FILE,
  TUSD_STARTING_AMOUNT, WBTC_STARTING_AMOUNT, SWAP_FRACTION,
  DEFAULT_EXPIRY_TIME, SUSHI_ROUTER_ADDRESS
} = require('./helper/constants');

const {
  ERC20_TOKEN_ABI, SUSHI_ROUTER_ABI
} = require('./helper/abi-definitions');

const {
  readJsonFile, waitForEvent, runTask,
  approveTokenTransfer, swapTokens
} = require('./helper/utils');


async function testSwapTokens() {
  const endToken = process.env.END_TOKEN;
  const swappingToTUSD = endToken === 'TUSD';
  const swappingToWBTC = endToken === 'WBTC';

  const {
    TUSDToken: TUSD_TOKEN_ADDR,
    WBTCToken: WBTC_TOKEN_ADDR,
  } = readJsonFile(`${ARTIFACTS_DIR}/${CONTRACT_ADDRESSES_FILE}`);

  const [deployer] = await ethers.getSigners();
  const testerAddress = deployer.address;

  const tusdTokenERC20 = new ethers.Contract(TUSD_TOKEN_ADDR, ERC20_TOKEN_ABI, deployer);
  const wbtcTokenERC20 = new ethers.Contract(WBTC_TOKEN_ADDR, ERC20_TOKEN_ABI, deployer);

  const tusdDecimals = await tusdTokenERC20.decimals();
  const wbtcDecimals = await wbtcTokenERC20.decimals();

  const oldTusdBalance = await tusdTokenERC20.balanceOf(testerAddress);
  const oldWbtcBalance = await wbtcTokenERC20.balanceOf(testerAddress);

  console.log(`Old Balance of TUSD: ${(oldTusdBalance / (10 ** tusdDecimals)).toFixed(2)}`);
  console.log(`Old Balance of WBTC: ${(oldWbtcBalance / (10 ** wbtcDecimals)).toFixed(2)}`);
  console.log();

  let tokenAmount, tokenName, tokenContract, swapPath;

  if (swappingToTUSD) {
    tokenName = 'WBTC';
    tokenContract = wbtcTokenERC20;
    tokenAmount = BigInt(WBTC_STARTING_AMOUNT * SWAP_FRACTION) * BigInt(10 ** wbtcDecimals);

    swapPath = [WBTC_TOKEN_ADDR, TUSD_TOKEN_ADDR];
  } else if (swappingToWBTC) {
    tokenName = 'TUSD';
    tokenContract = tusdTokenERC20;
    tokenAmount = BigInt(TUSD_STARTING_AMOUNT * SWAP_FRACTION) * BigInt(10 ** tusdDecimals);

    swapPath = [TUSD_TOKEN_ADDR, WBTC_TOKEN_ADDR];
  } else
    throw new Error('Invalid ending token specified for swapping');

  await approveTokenTransfer({
    targetContractAddr: SUSHI_ROUTER_ADDRESS,
    tokenName,
    tokenContract,
    tokenAmount,
  });

  const sushiRouter = new ethers.Contract(SUSHI_ROUTER_ADDRESS, SUSHI_ROUTER_ABI, deployer);
  const expiryDeadline = Math.floor(Date.now() / 1000) + DEFAULT_EXPIRY_TIME;

  await swapTokens({
    swapRouterContract: sushiRouter,
    inputAmount: tokenAmount,
    tokenPath: swapPath,
    destAddr: testerAddress,
    deadline: expiryDeadline
  });

  const newTusdBalance = await tusdTokenERC20.balanceOf(testerAddress);
  const newWbtcBalance = await wbtcTokenERC20.balanceOf(testerAddress);

  console.log(`New Balance of TUSD: ${(newTusdBalance / (10 ** tusdDecimals)).toFixed(2)}`);
  console.log(`New Balance of WBTC: ${(newWbtcBalance / (10 ** wbtcDecimals)).toFixed(2)}`);
  console.log();
}

module.exports = testSwapTokens;

// Only run the task if it's not imported as a module
if (typeof require !== 'undefined' && require.main === module) {
  runTask(testSwapTokens);
}
