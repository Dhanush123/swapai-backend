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

```bash
# Force compile all contracts
npm run compile

# Clean compiled artifacts
npm run clean

# Deploy a new set of fake TUSD and WBTC tokens on Kovan
npm run deploy-tokens

# Deploy a new version of PoolLiquifier on Kovan. Used for adding/removing liquidity to token pair
npm run deploy-pool-liquifier

# Use the pool liquifier contract on Kovan to *add* liquidity to the token pair
npm run add-liquidity

# Use the pool liquifier contract on Kovan to *remove* liquidity to the token pair
npm run remove-liquidity

# Deploy a new version of SwapAI on Kovan. This is the main contract on the backend side
npm run deploy-swapper

# Swap some TUSD to WBTC
npm run swap-to-wbtc

# Swap some WBTC to TUSD
npm run swap-to-tusd
```
