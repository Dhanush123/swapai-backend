// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import { SwapUser } from "../DataStructures.sol";

interface ISwapAI {
  // User register / login
  function userExists() external;
  function registerUser() external;

  event UserExists(bool userExists);
  event RegisterUser(bool success, bool isNewUser);

  // User attributes
  function fetchUserBalance() external;
  function fetchOptInStatus() external;

  event UserBalance(uint wbtcBalance, uint tusdBalance);
  event OptInStatus(bool optInStatus);

  // User management
  function setOptInStatus(bool newOptInStatus) external;

  event ToggleOptInStatus(bool newOptInStatus);

  // Balance depositing
  function depositTUSD(uint depositAmount) external;
  function depositWBTC(uint depositAmount) external;

  event DepositTUSD(uint oldAmount, uint newAmount);
  event DepositWBTC(uint oldAmount, uint newAmount);

  // Balance swapping
  function manualSwapUserBalance(bool toTUSD) external;
  function smartSwapAllBalances() external;

  event ManualSwap(bool success, bool toTUSD);
  event AutoSwap(
    // uint tusdRatio,
    uint btcSentiment,
    uint btcPriceCurrent,
    uint btcPricePrediction,
    bool isNegativeFuture,
    bool isPositiveFuture
  );
}
