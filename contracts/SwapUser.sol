pragma solidity ^0.8.7;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";

contract SwapUser {
  using Address for address;
  address userAddress;
  bool userHasOptedInForSwapping;

  address private constant kovan_tusd = 0xc6e977741487dd8457397b185709cd89b0cf5e7e;
  address private constant kovan_wbtc = 0xa0a5ad2296b38bd3e3eb59aaeaf1589e8d9a29a9;
  address private constant kovan_eth = 0xdB33dFD3D61308C33C63209845DaD3e6bfb2c674;

  constructor() {
  }

  function getUserSwapOptInStatus() internal view returns (bool) {
    return userHasOptedInForSwapping;
  }

  function getUserTUSDBalance() internal view returns (uint) {
    return IERC20(token).balanceOf(userAddress);
  }

  function getUserWBTCBalance() internal view returns (uint) {
    return IERC20(token).balanceOf(userAddress);
  }

  function getUserETHBalance() internal view returns (uint) {
    return IERC20(token).balanceOf(userAddress);
  }
}
