pragma solidity ^0.8.7;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import "./SwapUser.sol";

contract SwapUser {
  using Address for address;
  address userAddress;
  bool optInStatus;
  uint wbtcBalance;
  uint tusdBalance;

  constructor(address _userAddress, bool _optInStatus) {
    userAddress = _userAddress;
    optInStatus = _optInStatus;
  }

  function getUserOptInStatus() internal view returns (bool) {
    return optInStatus;
  }

  function getUserWBTCBalance() internal view returns (uint) {
    return wbtcBalance;
  }

  function getUserTUSDBalance() internal view returns (uint) {
    return tusdBalance;
  }
}
