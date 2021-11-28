// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

library Constants {
  address public constant SUSHIV2_FACTORY_ADDRESS = 0xc35DADB65012eC5796536bD9864eD8773aBc74C4;
  address public constant SUSHIV2_ROUTER02_ADDRESS = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;

  address public constant KOVAN_LINK_TOKEN = 0xa36085F69e2889c224210F603D836748e7dC0088;

  uint public constant ONE_TENTH_LINK_PAYMENT = 0.1 * 1 ether;
  uint public constant ONE_LINK_PAYMENT = 1 ether;
  uint public constant TUSD_MULT_AMT = 10**7;

  // FIXME: replace below address with custom adapter address
  // address public constant TUSD_RATIO_ORACLE_ADDR = 0xfF07C97631Ff3bAb5e5e5660Cdf47AdEd8D4d4Fd;
  address public constant SENTIMENT_ORACLE_ADDR = 0x56dd6586DB0D08c6Ce7B2f2805af28616E082455;
  address public constant BTC_USD_PRICE_FEED_ADDR = 0x6135b13325bfC4B00278B4abC5e20bbce2D6580e;
  address public constant PRICE_ORACLE_ADDR = 0xfF07C97631Ff3bAb5e5e5660Cdf47AdEd8D4d4Fd;
  address public constant GET_ORACLE_ADDR = 0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8;

  // FIXME: replace below with custom adapter job id
  // bytes32 public constant TUSD_RATIO_JOB_ID = "";
  bytes32 public constant SENTIMENT_JOB_ID = "e7beed14d06d477192ef30edc72557b1";
  bytes32 public constant PRICE_JOB_ID = "35e14dbd490f4e3b9fbe92b85b32d98a";
  bytes32 public constant GET_JOB_ID = "d5270d1c311941d0b08bead21fea7747";
  bytes32 public constant TUSD_URL = "https://core-api.real-time-attest.trustexplorer.io/trusttoken/TrueUSD";
}
