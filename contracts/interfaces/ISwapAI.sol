// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface ISwapAI {
  function createUser() external;

  function optInToggle() external;

  function swapSingleUserBalance() external;

  function swapAllUsersBalances(bool force) external;

  function fetchUserBalance() external;

  event CreateUser(
      bool createUserStatus
  );

  event OptInToggle(
      bool optInStatus
  );

  event DepositTUSD(
    uint oldUserAmount,
    uint newUserAmount
  );

  event DepositWBTC(
    uint oldUserAmount,
    uint newUserAmount
  );

  event SwapEligibleUsersExist(
    bool swapEligibleStatus
  );

  event UserBalance(
    uint WBTCBalance,
    uint TUSDBalance
  );
}
