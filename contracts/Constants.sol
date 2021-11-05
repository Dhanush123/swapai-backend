pragma solidity ^0.8.7;

library Constants {
  address public constant SUSHIV2_ROUTER02 = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;

  address public constant KOVAN_TUSD = 0xc6e977741487dd8457397b185709cd89b0cf5e7e;
  address public constant KOVAN_WBTC = 0xa0a5ad2296b38bd3e3eb59aaeaf1589e8d9a29a9;
  address public constant KOVAN_ETH = 0xdB33dFD3D61308C33C63209845DaD3e6bfb2c674;

  uint public constant TX_DEF_EXPIRY = 1 days;
  uint public constant MIN_OUTPUT_AMT = 1;
}
