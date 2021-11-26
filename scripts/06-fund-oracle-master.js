'use strict';

const fs = require('fs');

const {
  ARTIFACTS_DIR, CONTRACT_ADDRESSES_FILE,
  LINK_FUND_AMOUNT, LINK_TOKEN_ADDRESS
} = require('./helper/constants');
const { ERC20_TOKEN_ABI } = require('./helper/abi-definitions');

const { readJsonFile, waitForEvent, runTask, formatCurrency, /*approveTokenTransfer*/ } = require('./helper/utils');

async function fundOracleMaster() {
  const { OracleMaster: ORACLE_MASTER_ADDR } = readJsonFile(`${ARTIFACTS_DIR}/${CONTRACT_ADDRESSES_FILE}`);

  const [deployer] = await ethers.getSigners();
  const testerAddress = deployer.address;

  const linkTokenERC20 = new ethers.Contract(LINK_TOKEN_ADDRESS, ERC20_TOKEN_ABI, deployer);
  const linkDecimals = await linkTokenERC20.decimals();

  const oldTesterLinkBalance = await linkTokenERC20.balanceOf(testerAddress);
  const oldContractLinkBalance = await linkTokenERC20.balanceOf(ORACLE_MASTER_ADDR);

  console.log(`Old account balance of LINK: ${(formatCurrency(oldTesterLinkBalance, linkDecimals))}`);
  console.log(`Old contract balance of LINK: ${(formatCurrency(oldContractLinkBalance, linkDecimals))}`);
  console.log();

  // Approve and transfer TUSD to contract
  // await approveTokenTransfer({
  //   targetContractAddr: POOL_LIQUIFIER_ADDR,
  //   tokenName: 'LINK',
  //   tokenContract: linkTokenERC20,
  //   tokenAmount: tusdForLiquidity,
  // });

  console.log(`Attempting to fund oracle master with ${LINK_FUND_AMOUNT} LINK...`);
  console.log();

  const realLinkFundAmount = LINK_FUND_AMOUNT * 10 ** linkDecimals;
  await linkTokenERC20.transfer(ORACLE_MASTER_ADDR, realLinkFundAmount.toString());

  const [from, to, amount] = await waitForEvent(linkTokenERC20, linkTokenERC20.filters.Transfer(from, to));
  console.log(`Oracle Master has successfully obtained ${amount} LINK from ${testerAddress}`);
  console.log();

  const newTesterLinkBalance = await linkTokenERC20.balanceOf(testerAddress);
  const newContractLinkBalance = await linkTokenERC20.balanceOf(ORACLE_MASTER_ADDR);

  console.log(`New account balance of LINK: ${(formatCurrency(newTesterLinkBalance, linkDecimals))}`);
  console.log(`New contract balance of LINK: ${(formatCurrency(newContractLinkBalance, linkDecimals))}`);
  console.log();
}

module.exports = fundOracleMaster;

// Only run the task if it's not imported as a module
if (typeof require !== 'undefined' && require.main === module) {
  runTask(fundOracleMaster);
}
