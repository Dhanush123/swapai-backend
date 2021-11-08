// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

library Constants {
  address public constant SUSHIV2_ROUTER02_ADDRESS = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;

  address public constant KOVAN_TUSD = 0xC6e977741487dd8457397b185709CD89B0CF5E7e;
  address public constant KOVAN_WBTC = 0xA0A5aD2296b38Bd3e3Eb59AAEAF1589E8d9a29A9;
  address public constant KOVAN_WETH = 0xdB33dFD3D61308C33C63209845DaD3e6bfb2c674;

  uint public constant TX_DEF_EXPIRY = 1 days;
  uint public constant MIN_OUTPUT_AMT = 1;
}
