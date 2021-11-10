// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

library Constants {
  using SafeMath for uint;
  using Address for address;
  
  address public constant SUSHIV2_ROUTER02_ADDRESS = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;

  address public constant KOVAN_TUSD = 0x016750AC630F711882812f24Dba6c95b9D35856d;
  address public constant KOVAN_WBTC = 0xA0A5aD2296b38Bd3e3Eb59AAEAF1589E8d9a29A9;
  address public constant KOVAN_WETH = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;

  uint public constant TX_DEF_EXPIRY = 1 days;
  uint public constant MIN_OUTPUT_AMT = 1;

  uint public constant ONE_TENTH_LINK_PAYMENT = 0.1 * 1 ether;
  uint public constant ONE_LINK_PAYMENT = 1 ether;

  // FIXME: replace below address with custom adapter address
  address public constant TUSD_RATIO_ORACLE_ADDR = 0xfF07C97631Ff3bAb5e5e5660Cdf47AdEd8D4d4Fd;
  address public constant SENTIMENT_ORACLE_ADDR = 0x56dd6586DB0D08c6Ce7B2f2805af28616E082455;
  address public constant BTC_USD_PRICE_FEED_ADDR = 0x6135b13325bfC4B00278B4abC5e20bbce2D6580e;
  address public constant PRICE_ORACLE_ADDR = 0xfF07C97631Ff3bAb5e5e5660Cdf47AdEd8D4d4Fd;

  // FIXME: replace below with custom adapter job id
  bytes32 public constant TUSD_RATIO_JOB_ID = "";
  bytes32 public constant SENTIMENT_JOB_ID = "e7beed14d06d477192ef30edc72557b1";
  bytes32 public constant PRICE_JOB_ID = "35e14dbd490f4e3b9fbe92b85b32d98a";
}
