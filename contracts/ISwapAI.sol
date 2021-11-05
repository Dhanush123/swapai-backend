// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./SwapUser.sol";

interface ISwapAI {
  function createUser() external;

  function optInToggle() external;

  function swapSingleUserBalance() external;

  function swapAllUsersBalances(bool force) external;

  event CreateUser(
      bool createUserStatus
  );

  event OptInToggle(
      bool optInStatus
  );

  event SwapEligibleUsersExist(
    bool swapEligibleStatus
  );
}
