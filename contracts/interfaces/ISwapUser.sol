// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface ISwapUser {
  function getUserAddress() external view returns (address);
  function getUserOptInStatus() external view returns (bool);
  function toggleUserOptInStatus() external;

  function getWBTCBalance() external view returns (uint);
  function setWBTCBalance(uint _newBalance) external;

  function getTUSDBalance() external view returns (uint);
  function setTUSDBalance(uint _newBalance) external;
}
