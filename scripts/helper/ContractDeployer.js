'use strict';

const fs = require('fs');

class ContractDeployer {
  constructor() {
    this.contracts = {};
    this.contractConfigs = [];
    this.exportConfigs = [];
  }

  addContract({ name, args = [] }) {
    this.contractConfigs.push({ name, args });
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
    for (const config of this.contractConfigs)
      await this.deployContract(config);

    for (const config of this.exportConfigs)
      this.saveContractFiles(config);
  }

  async deployContract(config) {
    // ethers is avaialble in the global scope
    const [deployer] = await ethers.getSigners();

    console.log(`Deploying contract ${config.name} with account:`, (await deployer.getAddress()));
    console.log('Account balance:', (await deployer.getBalance()).toString());

    const contract = await ethers.getContractFactory(config.name);

    // const intervalSeconds = 86400; // 1 day
    // const contractDeploy = await contract.deploy(intervalSeconds);
    const contractDeployment = await contract.deploy(...config.args);
    await contractDeployment.deployed();
    console.log(`${config.name} address:`, contractDeployment.address);
    console.log();

    this.contracts[config.name] = contractDeployment.address;
    return contractDeployment;
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
