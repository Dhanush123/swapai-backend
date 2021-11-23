'use strict';

const fs = require('fs');

const {
  ARTIFACTS_DIR, CONTRACT_ADDRESSES_FILE,
  TUSD_STARTING_AMOUNT, WBTC_STARTING_AMOUNT,
  ADD_LIQUIDITY_FRACTION, LIQUIDITY_TOKEN_DECIMALS,
  DEFAULT_EXPIRY_TIME
} = require('./helper/constants');

const {
  ERC20_TOKEN_ABI, POOL_LIQUIFIER_ABI
} = require('./helper/abi-definitions');

const { readJsonFile, waitForEvent, runTask, approveTokenTransfer } = require('./helper/utils');

async function main() {
  const {
    TUSDToken: TUSD_TOKEN_ADDR,
    WBTCToken: WBTC_TOKEN_ADDR,
    PoolLiquifier: POOL_LIQUIFIER_ADDR,
  } = readJsonFile(`${ARTIFACTS_DIR}/${CONTRACT_ADDRESSES_FILE}`);

  const [deployer] = await ethers.getSigners();
  const testerAddress = deployer.address;

  // First transfer some funds of both tokens types from the deployer's account
  const tusdTokenERC20 = new ethers.Contract(TUSD_TOKEN_ADDR, ERC20_TOKEN_ABI, deployer);
  const wbtcTokenERC20 = new ethers.Contract(WBTC_TOKEN_ADDR, ERC20_TOKEN_ABI, deployer);

  const tusdDecimals = await tusdTokenERC20.decimals();
  const wbtcDecimals = await wbtcTokenERC20.decimals();

  const tusdBalance = await tusdTokenERC20.balanceOf(testerAddress);
  const wbtcBalance = await wbtcTokenERC20.balanceOf(testerAddress);

  const tusdForLiquidity = BigInt(TUSD_STARTING_AMOUNT * ADD_LIQUIDITY_FRACTION) * BigInt(10 ** tusdDecimals);
  const wbtcForLiquidity = BigInt(WBTC_STARTING_AMOUNT * ADD_LIQUIDITY_FRACTION) * BigInt(10 ** wbtcDecimals);

  console.log(`Balance of TUSD: ${(tusdBalance / (10 ** tusdDecimals)).toFixed(2)}`);
  console.log(`Balance of WBTC: ${(wbtcBalance / (10 ** wbtcDecimals)).toFixed(2)}`);
  console.log();

  // Approve and transfer TUSD to contract
  await approveTokenTransfer({
    targetContractAddr: POOL_LIQUIFIER_ADDR,
    tokenName: 'TUSD',
    tokenContract: tusdTokenERC20,
    tokenAmount: tusdForLiquidity,
  });

  // Approve and transfer WBTC to contract
  await approveTokenTransfer({
    targetContractAddr: POOL_LIQUIFIER_ADDR,
    tokenName: 'WBTC',
    tokenContract: wbtcTokenERC20,
    tokenAmount: wbtcForLiquidity,
  });

  // Then attempt to add liquidity to the token pair from the user's balances
  console.log('Attempting to fill liquidity pool...');
  console.log();

  const poolLiquifier = new ethers.Contract(POOL_LIQUIFIER_ADDR, POOL_LIQUIFIER_ABI, deployer);
  await poolLiquifier.fillPool(tusdForLiquidity, wbtcForLiquidity, DEFAULT_EXPIRY_TIME);
  const [tusdAmount, wbtcAmount, liquidityAdded, totalLiquidity] = await waitForEvent(poolLiquifier, poolLiquifier.filters.PoolFilled());

  console.log(`Actual amount of TUSD liquified: ${(tusdAmount / (10 ** tusdDecimals))}`);
  console.log(`Actual amount of WBTC liquified: ${(wbtcAmount / (10 ** wbtcDecimals))}`);
  console.log();

  console.log(`Liquidity token amount filled: ${liquidityAdded / (10 ** LIQUIDITY_TOKEN_DECIMALS)}`);
  console.log(`Total liquidity token amount: ${totalLiquidity / (10 ** LIQUIDITY_TOKEN_DECIMALS)}`);
  console.log();
}

runTask(main);
