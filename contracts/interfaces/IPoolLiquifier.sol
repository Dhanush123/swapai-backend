// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IPoolLiquifier {
  function fillPool(uint _amountA, uint _amountB, uint expiresIn) external;
  function drainPool(uint expiresIn) external;

  event PoolFilled(uint amountA, uint amountB, uint liquidityAdded, uint totalLiquidity);
  event PoolDrained(uint liquidityRemoved, uint amountA, uint amountB);
}
