'use strict';

const fs = require('fs');

const { ERC20_TOKEN_ABI } = require('./abi-definitions');

async function sleep(ms) {
  return new Promise(resolve => {
    setTimeout(resolve, ms);
  });
}

function printTitle(title, char = '/', offset = 2) {
  const numBars = title.length + 2;
  const sideOffset = char.repeat(offset);

  const barLine   = sideOffset + char.repeat(numBars) + sideOffset;
  const titleLine = `${sideOffset} ${title} ${sideOffset}`;

  console.log();
  console.log(barLine);
  console.log(titleLine);
  console.log(barLine);
  console.log();
}

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

async function balanceForToken(tokenAddress, targetAddress, deployer) {
  const tokenContract = new ethers.Contract(tokenAddress, ERC20_TOKEN_ABI, deployer);

  const decimals = await tokenContract.decimals();
  const balance = await tokenContract.balanceOf(targetAddress);

  return { balance, decimals };
}

function formatCurrency(rawValue, decimals) {
  const formattedValue = ethers.utils.formatUnits(rawValue, decimals);
  const prettyValue = ethers.utils.commify(formattedValue);
  return prettyValue;
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

module.exports = {
  sleep, printTitle, readJsonFile, waitForEvent, runTask,
  balanceForToken, formatCurrency, approveTokenTransfer, swapTokens
};
