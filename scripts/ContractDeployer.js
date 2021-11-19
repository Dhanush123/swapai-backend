const fs = require('fs');

class ContractDeployer {
  constructor(contractsDir) {
    this.contractsDir = contractsDir;
    this.contractConfigs = [];
    this.contracts = {};
  }

  addContract({ name, args = [] }) {
    this.contractConfigs.push({ name, args });
  }

  async deploy() {
    for (const config of this.contractConfigs) {
      await this.deployContract(config);
    }

    this.saveFrontendFiles();
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
  saveFrontendFiles() {
    if (!fs.existsSync(this.contractsDir)) {
      fs.mkdirSync(this.contractsDir);
    }

    // Check if 'contract-address.json' already exists
    const contractAddrs = this.contractsDir + '/contract-address.json';
    let allContracts;

    // If it does not exist, create a new one, otherwise read its data and merge with it
    if (fs.existsSync(contractAddrs))
      allContracts = JSON.parse(fs.readFileSync(contractAddrs, 'utf8'));
    else
      allContracts = {};

    allContracts = { ...allContracts, ...this.contracts };

    fs.writeFileSync(
      contractAddrs,
      JSON.stringify(allContracts, undefined, 2)
    );

    for (const contractName of Object.keys(this.contracts)) {
      const contractArtifact = artifacts.readArtifactSync(contractName);

      fs.writeFileSync(
        this.contractsDir + `/${contractName}.json`,
        JSON.stringify(contractArtifact, null, 2)
      );
    }
  }
}

module.exports = ContractDeployer;
