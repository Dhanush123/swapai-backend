'use strict';

const fs = require('fs');

const {
  ARTIFACTS_DIR, CONTRACT_ADDRESSES_FILE,
  LIQUIDITY_TOKEN_DECIMALS, DEFAULT_EXPIRY_TIME,
  SUSHI_FACTORY_ADDRESS
} = require('./helper/constants');

const {
  ERC20_TOKEN_ABI, POOL_LIQUIFIER_ABI, SUSHI_FACTORY_ABI
} = require('./helper/abi-definitions');

const { readJsonFile, waitForEvent, runTask, approveTokenTransfer } = require('./helper/utils');

async function removeLiquidity() {
  const {
    TUSDToken: TUSD_TOKEN_ADDR,
    WBTCToken: WBTC_TOKEN_ADDR,
    PoolLiquifier: POOL_LIQUIFIER_ADDR,
  } = readJsonFile(`${ARTIFACTS_DIR}/${CONTRACT_ADDRESSES_FILE}`);

  const [deployer] = await ethers.getSigners();
  const testerAddress = deployer.address;

  // First transfer all liquidity token funds from the deployer's account
  const sushiFactory = new ethers.Contract(SUSHI_FACTORY_ADDRESS, SUSHI_FACTORY_ABI, deployer);
  const TOKEN_PAIR_ADDR = await sushiFactory.getPair(TUSD_TOKEN_ADDR, WBTC_TOKEN_ADDR);

  const liquidityTokenERC20 = new ethers.Contract(TOKEN_PAIR_ADDR, ERC20_TOKEN_ABI, deployer);
  const liquidityDecimals = await liquidityTokenERC20.decimals();
  const totalUserLiquidity = await liquidityTokenERC20.balanceOf(testerAddress);

  console.log(`User balance of liquidity: ${(totalUserLiquidity / (10 ** liquidityDecimals)).toFixed(2)}`);

  // Approve and transfer liquidity token to contract
  await approveTokenTransfer({
    targetContractAddr: POOL_LIQUIFIER_ADDR,
    tokenName: 'Liquidity (TUSD-WBTC)',
    tokenContract: liquidityTokenERC20,
    tokenAmount: totalUserLiquidity,
  });

  // Then attempt to remove liquidity from the token pair and return those tokens to the user
  console.log('Attempting to drain liquidity pool...');
  console.log();

  const poolLiquifier = new ethers.Contract(POOL_LIQUIFIER_ADDR, POOL_LIQUIFIER_ABI, deployer);
  await poolLiquifier.drainPool(DEFAULT_EXPIRY_TIME);

  const [liquidityRemoved, tusdAmount, wbtcAmount] = await waitForEvent(poolLiquifier, poolLiquifier.filters.PoolDrained());
  console.log(`Liquidity token amount drained: ${liquidityRemoved / (10 ** LIQUIDITY_TOKEN_DECIMALS)}`);
  console.log();

  const tusdTokenERC20 = new ethers.Contract(TUSD_TOKEN_ADDR, ERC20_TOKEN_ABI, deployer);
  const wbtcTokenERC20 = new ethers.Contract(WBTC_TOKEN_ADDR, ERC20_TOKEN_ABI, deployer);

  const tusdDecimals = await tusdTokenERC20.decimals();
  const wbtcDecimals = await wbtcTokenERC20.decimals();

  console.log(`Amount of TUSD recovered: ${(tusdAmount / (10 ** tusdDecimals))}`);
  console.log(`Amount of WBTC recovered: ${(wbtcAmount / (10 ** wbtcDecimals))}`);
  console.log();

  const tusdBalance = await tusdTokenERC20.balanceOf(testerAddress);
  const wbtcBalance = await wbtcTokenERC20.balanceOf(testerAddress);

  console.log(`New Balance of TUSD: ${(tusdBalance / (10 ** tusdDecimals)).toFixed(2)}`);
  console.log(`New Balance of WBTC: ${(wbtcBalance / (10 ** wbtcDecimals)).toFixed(2)}`);
  console.log();
}

module.exports = removeLiquidity;

// Only run the task if it's not imported as a module
if (typeof require !== 'undefined' && require.main === module) {
  runTask(removeLiquidity);
}
