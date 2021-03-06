'use strict';

const FRONTEND_CONTRACTS_DIR = __dirname + '/../../../swapai-frontend/src/contracts';
const ARTIFACTS_DIR = __dirname + '/../artifacts';
const CONTRACT_ADDRESSES_FILE = 'contract-addresses.json';

const TUSD_STARTING_AMOUNT = 1_000_000_000;
const WBTC_STARTING_AMOUNT = 1_000_000;

const ADD_LIQUIDITY_FRACTION = 0.01;
const SWAP_FRACTION = 0.001;
const LINK_FUND_AMOUNT = 100;

const LIQUIDITY_TOKEN_DECIMALS = 18;
const DEFAULT_EXPIRY_TIME = 60 * 20; // 20 minutes

const LINK_TOKEN_ADDRESS = '0xa36085F69e2889c224210F603D836748e7dC0088';

const SUSHI_FACTORY_ADDRESS = '0xc35DADB65012eC5796536bD9864eD8773aBc74C4';
const SUSHI_ROUTER_ADDRESS = '0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506';

module.exports = {
  FRONTEND_CONTRACTS_DIR, ARTIFACTS_DIR, CONTRACT_ADDRESSES_FILE,
  TUSD_STARTING_AMOUNT, WBTC_STARTING_AMOUNT,
  ADD_LIQUIDITY_FRACTION, SWAP_FRACTION, LINK_FUND_AMOUNT,
  LIQUIDITY_TOKEN_DECIMALS, DEFAULT_EXPIRY_TIME,
  LINK_TOKEN_ADDRESS, SUSHI_FACTORY_ADDRESS, SUSHI_ROUTER_ADDRESS,
};
