// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

contract SwapUser {
  address userAddress;
  bool optInStatus;
  uint wbtcBalance;
  uint tusdBalance;

  constructor(address _userAddress, bool _optInStatus) public {
    userAddress = _userAddress;
    optInStatus = _optInStatus;
  }

  function getUserOptInStatus() internal view returns (bool) {
    return optInStatus;
  }

  function getWBTCBalance() internal view returns (uint) {
    return wbtcBalance;
  }

  function setWBTCBalance(uint _newBalance) internal {
    wbtcBalance = _newBalance;
  }

  function getTUSDBalance() external view returns (uint) {
    return tusdBalance;
  }

  function setTUSDBalance(uint _newBalance) internal {
    tusdBalance = _newBalance;
  }
}
