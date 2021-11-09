const PROJECT_NAME = 'SwapAI';

async function main() {
  console.log('!!!!',__dirname);

  // ethers is avaialble in the global scope
  const [deployer] = await ethers.getSigners();
  console.log(
    'Deploying the contracts with the account:',
    await deployer.getAddress()
  );

  console.log('Account balance:', (await deployer.getBalance()).toString());

  const SwapAI = await ethers.getContractFactory(PROJECT_NAME);
  const intervalSeconds = 86400; //1 day
  // const swapAIDeploy = await SwapAI.deploy(intervalSeconds);
  const swapAIDeploy = await SwapAI.deploy();
  await swapAIDeploy.deployed();

  console.log(`${PROJECT_NAME} address:`, swapAIDeploy.address);

  // We also save the contract's artifacts and address in the frontend directory
  saveFrontendFiles(swapAIDeploy);
}

function saveFrontendFiles(swapAIDeploy) {
  const fs = require('fs');
  const contractsDir = __dirname + '/../../swapai-frontend/src/contracts';

  if (!fs.existsSync(contractsDir)) {
    fs.mkdirSync(contractsDir);
  }

  let content = {};
  content[PROJECT_NAME] = swapAIDeploy.address;

  fs.writeFileSync(
    contractsDir + '/contract-address.json',
    JSON.stringify(content, undefined, 2)
  );

  const SwapAIArtifact = artifacts.readArtifactSync(PROJECT_NAME);

  fs.writeFileSync(
    contractsDir + `/${PROJECT_NAME}.json`,
    JSON.stringify(SwapAIArtifact, null, 2)
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });