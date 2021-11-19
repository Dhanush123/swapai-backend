const ContractDeployer = require('./ContractDeployer');

async function main() {
  console.log('!!!!', __dirname);
  const contractsDir = __dirname + '/../../swapai-frontend/src/contracts';
  const contractDeployer = new ContractDeployer(contractsDir);

  contractDeployer.addContract({ name: 'SwapAI' });
  await contractDeployer.deploy();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
