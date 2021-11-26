// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

// 3rd-party library imports
// import { KeeperCompatibleInterface } from "@chainlink/contracts/src/v0.6/interfaces/KeeperCompatibleInterface.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// 1st-party project imports
import { Constants } from "./Constants.sol";
import { SwapUser } from "./DataStructures.sol";
import { ISwapAI } from "./interfaces/ISwapAI.sol";
import { OracleMaster } from "./OracleMaster.sol";
import { TokenSwapper } from "./TokenSwapper.sol";

// contract SwapAI is ISwapAI, KeeperCompatibleInterface {
contract SwapAI is ISwapAI {
  address[] private userAddresses;
  mapping(address => SwapUser) private userData;

  address private oracleMasterAddr;
  address private tokenSwapperAddr;

  address private tusdTokenAddr;
  address private wbtcTokenAddr;

  constructor(
    address _tusdTokenAddr, address _wbtcTokenAddr,
    address _oracleMasterAddr, address _tokenSwapperAddr
  ) public {
    tusdTokenAddr = _tusdTokenAddr;
    wbtcTokenAddr = _wbtcTokenAddr;

    oracleMasterAddr = _oracleMasterAddr;
    tokenSwapperAddr = _tokenSwapperAddr;
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

  ///////////////////////////
  // User register / login //
  ///////////////////////////

  function userExists() external override {
    bool exists = userData[msg.sender].exists;
    emit UserExists(exists);
  }

  function registerUser() external override {
    SwapUser storage user = userData[msg.sender];
    bool isNewUser;

    if (!user.exists) {
      user.exists = true;
      user.wbtcBalance = 0;
      user.tusdBalance = 0;
      user.optInStatus = false;

      userAddresses.push(msg.sender);
      isNewUser = true;
    } else {
      isNewUser = false;
    }

    emit RegisterUser(true, isNewUser);
  }

  /////////////////////
  // User Attributes //
  /////////////////////

  function fetchUserBalance() external override {
    emit UserBalance(
      userData[msg.sender].tusdBalance,
      userData[msg.sender].wbtcBalance
    );
  }

  function fetchOptInStatus() external override {
    emit OptInStatus(userData[msg.sender].optInStatus);
  }

  /////////////////////
  // User management //
  /////////////////////

  function setOptInStatus(bool newOptInStatus) external override {
    userData[msg.sender].optInStatus = newOptInStatus;
    emit OptInStatus(userData[msg.sender].optInStatus);
  }

  ////////////////////////
  // Internal functions //
  ////////////////////////

  function _isAtleastOneUserOptIn() private view returns (bool) {
    for (uint i = 0; i < userAddresses.length; i++)
      if (userData[userAddresses[i]].optInStatus)
        return true;

    return false;
  }

  ////////////////////////
  // Balance depositing //
  ////////////////////////

  function depositTUSD(uint depositAmount) external override {
    require(
      IERC20(tusdTokenAddr).transferFrom(msg.sender, address(this), depositAmount),
      "Deposit of TUSD failed"
    );

    SwapUser storage user = userData[msg.sender];
    uint oldTUSDBalance = user.tusdBalance;
    user.tusdBalance = oldTUSDBalance + depositAmount;

    emit DepositTUSD(oldTUSDBalance, user.tusdBalance);
  }

  function depositWBTC(uint depositAmount) external override {
    require(
      IERC20(wbtcTokenAddr).transferFrom(msg.sender, address(this), depositAmount),
      "Deposit of WBTC failed"
    );

    SwapUser storage user = userData[msg.sender];
    uint oldWBTCBalance = user.wbtcBalance;
    user.wbtcBalance = oldWBTCBalance + depositAmount;

    emit DepositWBTC(oldWBTCBalance, user.wbtcBalance);
  }

  //////////////////////
  // Balance swapping //
  //////////////////////

  function manualSwapUserBalance(bool toTUSD) external override {
    if (toTUSD) {
      // OracleMaster(oracleMasterAddr).executeAnalysis(address(this), this._processAnalysisManualToTUSD.selector);
      _processAnalysisManualToTUSD(6000, 105 * 10 ** 7, 95 * 10 ** 7);
    } else {
      // OracleMaster(oracleMasterAddr).executeAnalysis(address(this), this._processAnalysisManualToWBTC.selector);
      _processAnalysisManualToWBTC(4000, 95 * 10 ** 7, 105 * 10 ** 7);
    }
  }

  function smartSwapAllBalances() external override {
    OracleMaster(oracleMasterAddr).executeAnalysis(address(this), this._processAnalysisAuto.selector);
  }

  // SECURITY RISK!!!
  // TODO: This poses a securiy risk where anyone can call this function and trigger an auto-swap
  // at will. This needs to be patched ASAP
  function _processAnalysisManualToWBTC(
    uint btcSentiment,
    uint btcPriceCurrent,
    uint btcPricePrediction
  ) public {
    bool isNegativeFuture;
    bool isPositiveFuture;

    (isNegativeFuture, isPositiveFuture) = _analyzeResults(
      btcSentiment, btcPriceCurrent, btcPricePrediction
    );

    SwapUser storage currentUser = userData[msg.sender];
    _attemptSwapToWBTC(currentUser);

    emit ManualSwap(
      true, false,
      /*tusdRatio,*/ btcSentiment,
      btcPriceCurrent, btcPricePrediction,
      isNegativeFuture, isPositiveFuture
    );
  }

  // SECURITY RISK!!!
  // TODO: This poses a securiy risk where anyone can call this function and trigger an auto-swap
  // at will. This needs to be patched ASAP
  function _processAnalysisManualToTUSD(
    uint btcSentiment,
    uint btcPriceCurrent,
    uint btcPricePrediction
  ) public {
    bool isNegativeFuture;
    bool isPositiveFuture;

    (isNegativeFuture, isPositiveFuture) = _analyzeResults(
      btcSentiment, btcPriceCurrent, btcPricePrediction
    );

    SwapUser storage currentUser = userData[msg.sender];
    _attemptSwapToTUSD(currentUser);

    emit ManualSwap(
      true, true,
      /*tusdRatio,*/ btcSentiment,
      btcPriceCurrent, btcPricePrediction,
      isNegativeFuture, isPositiveFuture
    );
  }

  // SECURITY RISK!!!
  // TODO: This poses a securiy risk where anyone can call this function and trigger an auto-swap
  // at will. This needs to be patched ASAP
  function _processAnalysisAuto(
    uint btcSentiment,
    uint btcPriceCurrent,
    uint btcPricePrediction
  ) public {
    bool isNegativeFuture;
    bool isPositiveFuture;

    (isNegativeFuture, isPositiveFuture) = _analyzeResults(
      btcSentiment, btcPriceCurrent, btcPricePrediction
    );

    for (uint i = 0; i < userAddresses.length; i++) {
      address userAddr = userAddresses[i];
      SwapUser storage user = userData[userAddr];

      if (user.optInStatus) {
        if (isPositiveFuture) {
          // Swap from TUSD in favor of WBTC to capitalize on gains
          _attemptSwapToWBTC(user);
        } else if (isNegativeFuture) {
          // Swap from WBTC in favor of TUSD to minimize losses
          _attemptSwapToTUSD(user);
        }
        // Otherwise do nothing
      }
    }

    emit AutoSwap(
      /*tusdRatio,*/ btcSentiment,
      btcPriceCurrent, btcPricePrediction,
      isNegativeFuture, isPositiveFuture
    );
  }

  function _analyzeResults(
    uint btcSentiment,
    uint btcPriceCurrent,
    uint btcPricePrediction
  ) public pure returns (bool, bool) {
    // bool isInsufficientTUSDRatio = tusdRatio < 9999; // 10000 means 1:1 asset:reserve ratio, less means $ assets > $ reserves
    bool isNegativeBTCSentiment = btcSentiment < 2500; // 5000 means 0.5 sentiment from range [-1,1]
    bool isBTCPriceGoingDown = (btcPriceCurrent / btcPricePrediction * 10**8) > 105000000; // check if > 5% decrease
    bool isNegativeFuture = /*isInsufficientTUSDRatio ||*/ isNegativeBTCSentiment || isBTCPriceGoingDown;

    // bool isSufficientTUSDRatio = tusdRatio >= 10000;
    bool isPositiveBTCSentiment = btcSentiment > 7500;
    bool isBTCPriceGoingUp = (btcPriceCurrent / btcPricePrediction * 10**8) < 95000000; // check if > 5% increase
    bool isPositiveFuture = /*isSufficientTUSDRatio &&*/ isPositiveBTCSentiment && isBTCPriceGoingUp;

    return (isNegativeFuture, isPositiveFuture);
  }

  function _attemptSwapToWBTC(SwapUser memory user) internal returns (SwapUser memory) {
    uint balance = user.tusdBalance;

    // First transfer the token amount (in TUSD) to the token swapper contract
    require(
      IERC20(tusdTokenAddr).approve(address(this), balance),
      'Approval of TUSD to TokenSwapper contract failed.'
    );

    require(
      IERC20(tusdTokenAddr).transferFrom(address(this), tokenSwapperAddr, balance),
      'Transfer of TUSD to TokenSwapper contract failed.'
    );

    // Then do the swap to WBTC
    user = TokenSwapper(tokenSwapperAddr).swapToWBTC(user);
    return user;
  }

  function _attemptSwapToTUSD(SwapUser memory user) internal returns (SwapUser memory) {
    uint balance = user.wbtcBalance;

    // First transfer the token amount to the token swapper contract
    require(
      IERC20(wbtcTokenAddr).approve(address(this), balance),
      'Approval of WBTC to TokenSwapper contract failed.'
    );

    require(
      IERC20(wbtcTokenAddr).transferFrom(address(this), tokenSwapperAddr, balance),
      'Transfer of WBTC to TokenSwapper contract failed.'
    );

    // Then do the swap to WBTC
    user = TokenSwapper(tokenSwapperAddr).swapToTUSD(user);
    return user;
  }

  ////////////////////////////
  // Chainlink Keeper Logic //
  ////////////////////////////

  // function checkUpkeep(bytes calldata /* checkData */) external override returns (bool upkeepNeeded, bytes memory /* performData */) {
  //   bool hasIntervalPassed = (block.timestamp - lastTimeStamp) > interval;
  //   upkeepNeeded = hasIntervalPassed && _isAtleastOneUserOptIn();
  //   return (upkeepNeeded, bytes(""));
  //   // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
  // }

  // function performUpkeep(bytes calldata /* performData */) external override {
  //   lastTimeStamp = block.timestamp;
  //   swapAllUsersBalances(false);
  //   // We don't use the performData in this example. The performData is generated by the Keeper's call to your checkUpkeep function
  // }
}
