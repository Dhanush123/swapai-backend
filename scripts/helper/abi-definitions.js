'use strict';

const ERC20_TOKEN_ABI = [
  'function decimals() public view returns (uint8)',
  'function balanceOf(address account) public view returns (uint256)',

  'function approve(address spender, uint256 amount) external returns (bool)',

  'event Transfer(address indexed from, address indexed to, uint256 value)',
  'event Approval(address indexed owner, address indexed spender, uint256 value)',
];

const POOL_LIQUIFIER_ABI = [
  'function fillPool(uint _amountA, uint _amountB, uint expiresIn) external',
  'function drainPool(uint expiresIn) external',

  'event PoolFilled(uint amountA, uint amountB, uint liquidityAdded, uint totalLiquidity)',
  'event PoolDrained(uint liquidityRemoved, uint amountA, uint amountB)',
];


const SUSHI_FACTORY_ABI = [
  'function getPair(address tokenA, address tokenB) external view returns (address pair)',
];

const SUSHI_ROUTER_ABI = [
  'function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts)'
];

module.exports = { ERC20_TOKEN_ABI, POOL_LIQUIFIER_ABI, SUSHI_FACTORY_ABI, SUSHI_ROUTER_ABI };
