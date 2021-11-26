# swapai-backend
 Chainlink Fall Hackathon 2021 project backend

Frontend repo: https://github.com/Dhanush123/swapai-frontend

Link to the deployed frontend https://dhanush123.github.io/swapai-frontend/

## Dev Quick Start

The first things you need to do are cloning this repo and installing its
dependencies:

```sh
git clone https://github.com/Dhanush123/swapai-backend.git
cd swapai-backend
npm install
```

Then to deploy the contracts to Kovan run the following (it is assumed you've put your credentials in a .env in the backend repo's root folder):
```sh
npm run deploy-tokens
npm run deploy-pool-liquifier
npm run add-liquidity
npm run deploy-swapper
```

To locally tinker with and run the frontend, in another terminal, run the following commands:

```sh
git clone https://github.com/Dhanush123/swapai-frontend.git
cd swapai-frontend
npm install
npm start
```

## Commands

### Compilation commands

```bash
# Force compile all contracts
npm run compile

# Clean compiled artifacts
npm run clean
```

### Level 0 (L0) deploy commands
```bash
# Mint a new set of fake TUSD and WBTC tokens.
npm run mint-tokens

# Deploy a new version of PoolLiquifier. Used for adding/removing liquidity to the token pair.
npm run deploy-pool-liquifier

# Use the pool liquifier contract to *add* liquidity to the token pair.
npm run add-liquidity

# Use the pool liquifier contract to *remove* liquidity to the token pair.
npm run remove-liquidity

# Deploy a new version of OracleMaster. Used by SwapAI for fetching data from oracle endpoints for smart swapping.
npm run deploy-oracle-master

# Fund the OracleMaster with LINK tokens to call the oracles.
npm run fund-oracle-master

# Deploy a new version of TokenSwapper. Used by SwapAI for swapping each user's currency between TUSD and WBTC.
npm run deploy-token-swapper

# Deploy a new version of SwapAI. This is the main contract.
npm run deploy-swapai
```

### Level 1 (L1) deploy commands
```bash
# Mint and setup a new set of tokens
npm run deploy-tokens

# Deploy a new set of contracts
npm run deploy-contracts
```

### Debug commands

```bash
# View the contract deployer's balances in various relevent tokens.
npm run view-account-balances

# Swap a small portion of the user's TUSD to WBTC
npm run test-swap-to-wbtc

# Swap a small portion of the user's WBTC to TUSD
npm run test-swap-to-tusd
```
