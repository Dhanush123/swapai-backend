'use strict';

const fs = require('fs');
const hre = require('hardhat');

const { sleep, formatCurrency } = require('./utils');

class ContractDeployer {
  constructor() {
    this.contracts = {};
    this.contractConfigs = [];
    this.exportConfigs = [];
  }

  addContract({ name, args = [], verify = false }) {
    this.contractConfigs.push({ name, args, verify });
    return this;
  }

  addExportDir({ dir, file }) {
    this.exportConfigs.push({ dir, file });
    return this;
  }

  deployedContracts() {
    return this.contracts;
  }

  async deploy() {
    for (const config of this.contractConfigs) {
      // First deploy the contract
      await this.deployContract(config);

      if (config.verify) {
        // Wait for 30 seconds for etherscan to recognize it
        console.log("Waiting for 30 seconds for etherscan to recognize it...");
        await sleep(30 * 1000);

        // Then verify the contract by uploading them to etherscan (if the key is provided)
        await this.verifyContract(config);
      }
    }

    // Lastly, save the ABI specs to the given export directories
    for (const config of this.exportConfigs)
      this.saveContractFiles(config);
  }

  async deployContract(config) {
    // ethers is avaialble in the global scope
    const [deployer] = await ethers.getSigners();

    const deployerAddr = await deployer.getAddress();
    console.log(`Deploying contract ${config.name} with account: ${deployerAddr}`);

    const accountEthBalanceBefore = await deployer.getBalance();
    console.log(`Account balance (ETH) before deployment: ${formatCurrency(accountEthBalanceBefore, 18)}`);

    const contract = await ethers.getContractFactory(config.name);
    const contractDeployment = await contract.deploy(...config.args);
    await contractDeployment.deployed();

    const accountEthBalanceAfter = await deployer.getBalance();
    console.log(`Account balance (ETH) after deployment: ${formatCurrency(accountEthBalanceAfter, 18)}`);
    console.log(`${config.name} address:`, contractDeployment.address);
    console.log();

    this.contracts[config.name] = contractDeployment.address;
    return contractDeployment;
  }

  async verifyContract(config) {
    const contractAddr = this.contracts[config.name];

    try {
      await hre.run('verify:verify', {
        address: contractAddr,
        constructorArguments: config.args,
      });
    } catch (error) {
      // If the contract was verified via similar code uploaded prior, we don't need to re-verify persay
      const isAlreadyVerified = error.message.toLowerCase().includes('already verified');
      if (isAlreadyVerified)
        console.log('Skipping verification since contract appears to be already verified')
      else
        throw error;
    }
  }

  // We also save the contract's artifacts and address in the frontend directory
  saveContractFiles(config) {
    if (!fs.existsSync(config.dir))
      fs.mkdirSync(config.dir);

    const contractAddrFile = `${config.dir}/${config.file}`;

    // Save new contract addresses to JSON file
    this._saveContractAddresses(contractAddrFile, this.contracts);

    // Save new contract artifacts to export directory
    this._saveContractFiles(config.dir, this.contracts);
  }

  _saveContractAddresses(filePath, newContracts) {
    let allContracts;

    // If it does not exist, create a new one, otherwise read its data and merge with it
    if (fs.existsSync(filePath))
      allContracts = JSON.parse(fs.readFileSync(filePath, 'utf8'));
    else
      allContracts = {};

    allContracts = { ...allContracts, ...newContracts };

    fs.writeFileSync(
      filePath,
      JSON.stringify(allContracts, null, 2)
    );
  }

  _saveContractFiles(contractDir, newContracts) {
    for (const contractName of Object.keys(newContracts)) {
      const contractArtifact = artifacts.readArtifactSync(contractName);

      fs.writeFileSync(
        contractDir + `/${contractName}.json`,
        JSON.stringify(contractArtifact, null, 2)
      );
    }
  }
}

module.exports = ContractDeployer;
