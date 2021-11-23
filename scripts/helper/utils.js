'use strict';

const fs = require('fs');

function readJsonFile(filePath) {
  if (!fs.existsSync(filePath))
    throw new Error(`Cannot find deployed contract addressses file at ${filePath}`);

  return JSON.parse(fs.readFileSync(filePath, 'utf8'));
}

async function waitForEvent(contract, filter) {
  return new Promise((resolve, reject) => {
    contract.once(filter, function(...args) {
      resolve(args);
    });
  });
}

function runTask(task) {
  task()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
}

async function approveTokenTransfer({ targetContractAddr, tokenName, tokenContract, tokenAmount }) {
  const decimals = await tokenContract.decimals();

  // First approve the transfer for the contract on behalf of the owner
  console.log(`Attempting to approve the target contract at ${targetContractAddr} to transfer ${tokenName}...`);
  await tokenContract.approve(targetContractAddr, tokenAmount.toString());

  const [owner, spender, approvedAmt] = await waitForEvent(tokenContract, tokenContract.filters.Approval());
  const canonicalAmtForLiquidity = (approvedAmt / (10 ** decimals)).toFixed(2);
  console.log(`Target contract has been approved to transfer ${canonicalAmtForLiquidity} ${tokenName}`);
  console.log();
}

async function swapTokens({ swapRouterContract, inputAmount, tokenPath, destAddr, deadline }) {
  const tx = await swapRouterContract.swapExactTokensForTokens(
    inputAmount,
    1,
    tokenPath,
    destAddr,
    deadline
  );

  await tx.wait();
}

module.exports = { readJsonFile, waitForEvent, runTask, approveTokenTransfer, swapTokens };
