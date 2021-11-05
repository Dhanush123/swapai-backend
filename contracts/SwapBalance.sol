pragma solidity ^0.8.7;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";

contract SwapBalance {
  using Address for address;

  address constant kovan_tusd = 0xc6e977741487dd8457397b185709cd89b0cf5e7e;
  address constant kovan_wbtc = 0xa0a5ad2296b38bd3e3eb59aaeaf1589e8d9a29a9;
  address constant kovan_eth = 0xdB33dFD3D61308C33C63209845DaD3e6bfb2c674;

  function getContractTUSDBalance() internal view returns (uint) {
    return IERC20(kovan_tusd).balanceOf(address(this));
  }

  function getUContractWBTCBalance() internal view returns (uint) {
    return IERC20(kovan_wbtc).balanceOf(address(this));
  }

  function getContractETHBalance() internal view returns (uint) {
    return IERC20(kovan_eth).balanceOf(address(this));
  }
}