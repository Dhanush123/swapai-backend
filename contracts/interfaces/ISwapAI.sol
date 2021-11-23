// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import { SwapUser } from "../DataStructures.sol";

interface ISwapAI {
  function createUser() external;
  function fetchUserBalance() external;
  function optInToggle() external;

  function swapSingleUsersBalance(bool toTUSD) external;
  function swapAllUsersBalances() external;

  event CreateUser(bool createUserStatus);
  event UserBalance(uint WBTCBalance, uint TUSDBalance);
  event OptInToggle(bool optInStatus);
  event SwapEligibleUsersExist(bool swapEligibleStatus);

  event DepositTUSD(uint oldAmount, uint newAmount);
  event DepositWBTC(uint oldAmount, uint newAmount);

  event ManualSwap(
    SwapUser user,
    bool toTUSD
  );

  event AutoSwap(
    // uint tusdRatio,
    SwapUser[] users,
    uint btcSentiment,
    uint btcPriceCurrent,
    uint btcPricePrediction,
    bool isNegativeFuture,
    bool isPositiveFuture
  );
}
