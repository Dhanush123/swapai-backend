// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

// 3rd-party library imports
// import { KeeperCompatibleInterface } from "@chainlink/contracts/src/v0.6/interfaces/KeeperCompatibleInterface.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

// 1st-party project imports
import { Constants } from "./Constants.sol";
import { SwapUser } from "./DataStructures.sol";
import { ISwapAI } from "./interfaces/ISwapAI.sol";
import { OracleMaster } from "./OracleMaster.sol";
import { TokenSwapper } from "./TokenSwapper.sol";

// contract SwapAI is ISwapAI, KeeperCompatibleInterface {
contract SwapAI is ISwapAI, Ownable {
  address[] private userAddresses;
  mapping(address => SwapUser) private userData;

  OracleMaster private oracleMaster;
  TokenSwapper private tokenSwapper;

  address private tusdTokenAddr;
  address private wbtcTokenAddr;

  constructor(address _tusdTokenAddr, address _wbtcTokenAddr) public {
    oracleMaster = new OracleMaster();
    tokenSwapper = new TokenSwapper(_tusdTokenAddr, _wbtcTokenAddr);
  }

  // /**
  // * Use an interval in seconds and a timestamp to slow execution of Upkeep
  // */
  // uint public immutable interval;
  // uint public lastTimeStamp;

  // constructor(uint updateInterval) public {
  //   interval = updateInterval;
  //   lastTimeStamp = block.timestamp;
  // }

  /////////////////////
  // User Management //
  /////////////////////

  function createUser() external override {
    if (userData[msg.sender].userAddress == address(0)) {
      userData[msg.sender].userAddress = msg.sender;
      userData[msg.sender].optInStatus = true;
      userAddresses.push(msg.sender);
      emit CreateUser(true);
    } else {
      emit CreateUser(false);
    }
  }

  function fetchUserBalance() external override {
    emit UserBalance(
      userData[msg.sender].tusdBalance,
      userData[msg.sender].wbtcBalance
    );
  }

  function optInToggle() external override {
    userData[msg.sender].optInStatus = !userData[msg.sender].optInStatus;
    emit OptInToggle(userData[msg.sender].optInStatus);
  }

  function isAtleastOneUserOptIn() private returns (bool) {
    bool result = false;
    for (uint i = 0; i < userAddresses.length; i++) {
      if (userData[userAddresses[i]].optInStatus) {
        result = true;
        break;
      }
    }

    emit SwapEligibleUsersExist(result);
    return result;
  }

  function getSwapEligibleUsers() public view returns (SwapUser[] memory) {
    // NOTE: To avoid having a storage array (i.e. extra gas cost), we're counting the items
    // to be filtered and then instantiating a memory-based array
    uint numEligibleUsers = 0;

    for (uint i = 0; i < userAddresses.length; i++) {
      SwapUser memory user = userData[userAddresses[i]];
      if (user.optInStatus)
        numEligibleUsers++;
    }

    SwapUser[] memory eligibleUsers = new SwapUser[](numEligibleUsers);

    uint j = 0;
    for (uint i = 0; i < userAddresses.length; i++) {
      SwapUser memory user = userData[userAddresses[i]];
      if (user.optInStatus) {
        eligibleUsers[j++] = user;
      }
    }

    return eligibleUsers;
  }

  ////////////////////
  // Swapping Logic //
  ////////////////////

  function swapSingleUsersBalance(bool toTUSD) external override {
    SwapUser memory currentUser = userData[msg.sender];
    tokenSwapper.doManualSwap(currentUser, toTUSD);

    emit ManualSwap(currentUser, toTUSD);
  }

  function swapAllUsersBalances() public override {
    oracleMaster.executeAnalysis(address(this), this._processAnalysis.selector);
  }

  function _processAnalysis(
    uint btcSentiment,
    uint btcPriceCurrent,
    uint btcPricePrediction
  ) public {
    // bool isInsufficientTUSDRatio = tusdRatio < 9999; // 10000 means 1:1 asset:reserve ratio, less means $ assets > $ reserves
    bool isNegativeBTCSentiment = btcSentiment < 2500; // 5000 means 0.5 sentiment from range [-1,1]
    bool isBTCPriceGoingDown = (btcPriceCurrent / btcPricePrediction * 10**8) > 105000000; // check if > 5% decrease
    bool isNegativeFuture = /*isInsufficientTUSDRatio ||*/ isNegativeBTCSentiment || isBTCPriceGoingDown;

    // bool isSufficientTUSDRatio = tusdRatio >= 10000;
    bool isPositiveBTCSentiment = btcSentiment > 7500;
    bool isBTCPriceGoingUp = (btcPriceCurrent / btcPricePrediction * 10**8) < 95000000; // check if > 5% increase
    bool isPositiveFuture = /*isSufficientTUSDRatio &&*/ isPositiveBTCSentiment && isBTCPriceGoingUp;

    SwapUser[] memory usersToSwap = getSwapEligibleUsers();
    for (uint i = 0; i < usersToSwap.length; i++)
      tokenSwapper.doAutoSwap(usersToSwap[i], isPositiveFuture, isNegativeFuture);

    emit AutoSwap(
      usersToSwap,
      /*tusdRatio,*/ btcSentiment,
      btcPriceCurrent, btcPricePrediction,
      isNegativeFuture, isPositiveFuture
    );
  }

  //////////////////////
  // Depositing Logic //
  //////////////////////

  function depositTUSD(uint depositAmount) public {
    require(
      IERC20(tusdTokenAddr).transferFrom(msg.sender, address(this), depositAmount),
      "Deposit of TUSD failed"
    );

    SwapUser memory user = userData[msg.sender];
    uint oldTUSDBalance = user.tusdBalance;
    user.tusdBalance = oldTUSDBalance + depositAmount;
    userData[msg.sender] = user;

    emit DepositTUSD(oldTUSDBalance, user.tusdBalance);
  }

  function depositWBTC(uint depositAmount) public { 
    require(
      IERC20(wbtcTokenAddr).transferFrom(msg.sender, address(this), depositAmount),
      "Deposit of WBTC failed"
    );

    SwapUser memory user = userData[msg.sender];
    uint oldWBTCBalance = user.wbtcBalance;
    user.wbtcBalance = oldWBTCBalance + depositAmount;
    userData[msg.sender] = user;

    emit DepositWBTC(oldWBTCBalance, user.wbtcBalance);
  }

  // function checkUpkeep(bytes calldata /* checkData */) external override returns (bool upkeepNeeded, bytes memory /* performData */) {
  //   bool hasIntervalPassed = (block.timestamp - lastTimeStamp) > interval;
  //   upkeepNeeded = hasIntervalPassed && isAtleastOneUserOptIn();
  //   return (upkeepNeeded, bytes(""));
  //   // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
  // }

  // function performUpkeep(bytes calldata /* performData */) external override {
  //   lastTimeStamp = block.timestamp;
  //   swapAllUsersBalances(false);
  //   // We don't use the performData in this example. The performData is generated by the Keeper's call to your checkUpkeep function
  // }

  // function getContractTUSDBalance() internal view returns (uint) {
  //   return IERC20(Constants.KOVAN_TUSD).balanceOf(address(this));
  // }

  // function getContractWBTCBalance() internal view returns (uint) {
  //   return IERC20(Constants.KOVAN_WBTC).balanceOf(address(this));
  // }
}
