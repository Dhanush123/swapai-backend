// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

library Constants {
  address public constant SUSHIV2_ROUTER02_ADDRESS = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;

  address public constant KOVAN_TUSD = 0x016750ac630f711882812f24dba6c95b9d35856d;
  address public constant KOVAN_WBTC = 0xA0A5aD2296b38Bd3e3Eb59AAEAF1589E8d9a29A9;
  address public constant KOVAN_WETH = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;

  uint public constant TX_DEF_EXPIRY = 1 days;
  uint public constant MIN_OUTPUT_AMT = 1;
}
