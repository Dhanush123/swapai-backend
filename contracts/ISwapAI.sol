pragma solidity ^0.8.7;

import "./SwapUser.sol";

interface ISwapAI {
  function createUser() external;

  function optInToggle() external;

  function swapSingleUserBalance(bool force) external;

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
