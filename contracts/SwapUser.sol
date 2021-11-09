// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import { ISwapUser } from "./interfaces/ISwapUser.sol";

contract SwapUser is ISwapUser {
  address private userAddress;
  bool private optInStatus;
  uint private wbtcBalance;
  uint private tusdBalance;

  constructor(address _userAddress, bool _optInStatus) public {
    userAddress = _userAddress;
    optInStatus = _optInStatus;
  }

  ///////////////
  // USER INFO //
  ///////////////

  function getUserAddress() external override view returns (address) {
    return userAddress;
  }

  function getUserOptInStatus() external override view returns (bool) {
    return optInStatus;
  }

  function toggleUserOptInStatus() external override {
    optInStatus = !optInStatus;
  }

  ///////////////////
  // USER BALANCES //
  ///////////////////

  function getWBTCBalance() external override view returns (uint) {
    return wbtcBalance;
  }

  function setWBTCBalance(uint _newBalance) external override {
    wbtcBalance = _newBalance;
  }

  function getTUSDBalance() external override view returns (uint) {
    return tusdBalance;
  }

  function setTUSDBalance(uint _newBalance) external override {
    tusdBalance = _newBalance;
  }
}
