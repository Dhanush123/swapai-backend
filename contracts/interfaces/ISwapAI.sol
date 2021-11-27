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

  event UserBalance(uint tusdBalance, uint wbtcBalance);
  event OptInStatus(bool optInStatus);

  // User management
  function setOptInStatus(bool newOptInStatus) external;

  // Balance depositing
  function depositTUSD(uint depositAmount) external;
  function depositWBTC(uint depositAmount) external;

  event DepositTUSD(uint oldAmount, uint newAmount);
  event DepositWBTC(uint oldAmount, uint newAmount);

  // Manual balance swapping
  function manualSwapUserToWBTC() external;
  function manualSwapUserToTUSD() external;

  event ManualSwap(
    uint oldWbtcBalance, uint newWbtcBalance,
    uint oldTusdBalance, uint newTusdBalance
  );

  // Prediction forecasting
  function fetchPredictionForecast() external;

  event PredictionResults(
    // uint tusdRatio,
    int btcSentiment,
    int btcPriceCurrent,
    int btcPricePrediction,
    bool isNegativeFuture,
    bool isPositiveFuture
  );

  // Automatic balance swapping
  function smartSwapAllBalances() external;

  event AutoSwap(
    // uint tusdRatio,
    int btcSentiment,
    int btcPriceCurrent,
    int btcPricePrediction,
    bool isNegativeFuture,
    bool isPositiveFuture
  );
}
