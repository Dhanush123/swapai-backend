'use strict';

const fs = require('fs');

const {
  ARTIFACTS_DIR, CONTRACT_ADDRESSES_FILE,
  LINK_TOKEN_ADDRESS
} = require('./helper/constants');
const { ERC20_TOKEN_ABI } = require('./helper/abi-definitions');

const {
  readJsonFile, waitForEvent, runTask,
  balanceForToken, formatCurrency
} = require('./helper/utils');

async function viewAccountBalances() {
  const {
    TUSDToken: TUSD_TOKEN_ADDRESS,
    WBTCToken: WBTC_TOKEN_ADDRESS,
  } = readJsonFile(`${ARTIFACTS_DIR}/${CONTRACT_ADDRESSES_FILE}`);

  const [deployer] = await ethers.getSigners();
  const testerAddress = deployer.address;

  const ethBalance  = await deployer.getBalance();

  const tokenBalances = {
    'ETH': {
      balance: ethBalance,
      decimals: 18,
    },
    'LINK': await balanceForToken(LINK_TOKEN_ADDRESS, testerAddress, deployer),
    'TUSD': await balanceForToken(TUSD_TOKEN_ADDRESS, testerAddress, deployer),
    'WBTC': await balanceForToken(WBTC_TOKEN_ADDRESS, testerAddress, deployer),
  }

  for (const tokenName of Object.keys(tokenBalances)) {
    const { balance, decimals } = tokenBalances[tokenName];
    console.log(`Account ${tokenName} balance: ${(formatCurrency(balance, decimals))}`)
  }
}

module.exports = viewAccountBalances;

// Only run the task if it's not imported as a module
if (typeof require !== 'undefined' && require.main === module) {
  runTask(viewAccountBalances);
}
