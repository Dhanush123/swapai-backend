// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

// 3rd-party library imports
// import { KeeperCompatibleInterface } from "@chainlink/contracts/src/v0.6/interfaces/KeeperCompatibleInterface.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// 1st-party project imports
import { Constants } from "./Constants.sol";
import { SwapUser, PredictionResponse } from "./DataStructures.sol";

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
    // First transfer the token amount to the SwapAI contract
    require(
      IERC20(tusdTokenAddr).transferFrom(msg.sender, address(this), depositAmount),
      "DEPOSIT_TUSD_TO_SWAPAI_FAIL"
    );

    // Then transfer the token amount to the token swapper contract
    require(
      IERC20(tusdTokenAddr).approve(address(this), depositAmount),
      "APPROVE_TUSD_TOKENSWAP_FAIL"
    );

    require(
      IERC20(tusdTokenAddr).transferFrom(address(this), tokenSwapperAddr, depositAmount),
      "TRANSFER_TUSD_TOKENSWAP_FAIL"
    );

    SwapUser storage user = userData[msg.sender];
    uint oldTUSDBalance = user.tusdBalance;
    user.tusdBalance = oldTUSDBalance + depositAmount;

    emit DepositTUSD(oldTUSDBalance, user.tusdBalance);
  }

  function depositWBTC(uint depositAmount) external override {
    // First transfer the token amount to the SwapAI contract
    require(
      IERC20(wbtcTokenAddr).transferFrom(msg.sender, address(this), depositAmount),
      "DEPOSIT_WBTC_TO_SWAPAI_FAIL"
    );

    // Then transfer the token amount to the token swapper contract
    require(
      IERC20(wbtcTokenAddr).approve(address(this), depositAmount),
      "APPROVE_WBTC_TOKENSWAP_FAIL"
    );

    require(
      IERC20(wbtcTokenAddr).transferFrom(address(this), tokenSwapperAddr, depositAmount),
      "TRANSFER_WBTC_TOKENSWAP_FAIL"
    );

    SwapUser storage user = userData[msg.sender];
    uint oldWBTCBalance = user.wbtcBalance;
    user.wbtcBalance = oldWBTCBalance + depositAmount;

    emit DepositWBTC(oldWBTCBalance, user.wbtcBalance);
  }

  /////////////////////////////
  // Manual balance swapping //
  /////////////////////////////

  function _attemptSwapToWBTC(SwapUser storage user) internal {
    SwapUser memory _tmpUser = TokenSwapper(tokenSwapperAddr).swapToWBTC(user);
    user.wbtcBalance = _tmpUser.wbtcBalance;
    user.tusdBalance = _tmpUser.tusdBalance;
  }

  function manualSwapUserToWBTC() external override {
    SwapUser storage currentUser = userData[msg.sender];

    uint oldWbtcBalance = currentUser.wbtcBalance;
    uint oldTusdBalance = currentUser.tusdBalance;

    _attemptSwapToWBTC(currentUser);

    uint newWbtcBalance = currentUser.wbtcBalance;
    uint newTusdBalance = currentUser.tusdBalance;

    emit ManualSwap(
      oldWbtcBalance, newWbtcBalance,
      oldTusdBalance, newTusdBalance
    );
  }

  function _attemptSwapToTUSD(SwapUser storage user) internal {
    SwapUser memory _tmpUser = TokenSwapper(tokenSwapperAddr).swapToTUSD(user);
    user.wbtcBalance = _tmpUser.wbtcBalance;
    user.tusdBalance = _tmpUser.tusdBalance;
  }

  function manualSwapUserToTUSD() external override {
    SwapUser storage currentUser = userData[msg.sender];

    uint oldWbtcBalance = currentUser.wbtcBalance;
    uint oldTusdBalance = currentUser.tusdBalance;

    _attemptSwapToTUSD(currentUser);

    uint newWbtcBalance = currentUser.wbtcBalance;
    uint newTusdBalance = currentUser.tusdBalance;

    emit ManualSwap(
      oldWbtcBalance, newWbtcBalance,
      oldTusdBalance, newTusdBalance
    );
  }

  ////////////////////////////
  // Prediction forecasting //
  ////////////////////////////

  function fetchPredictionForecast() external override {
    OracleMaster(oracleMasterAddr).executeAnalysis(address(this), this._processPredictionResults.selector);
  }

  function _processPredictionResults(PredictionResponse memory res) public {
    bool isNegativeFuture;
    bool isPositiveFuture;

    (isNegativeFuture, isPositiveFuture) = _analyzeResults(res);

    emit PredictionResults(
      res.btcPriceCurrent,
      res.btcPricePrediction,
      res.tusdAssetsAmt,
      res.tusdReservesAmt,
      res.btcSentiment,

      isNegativeFuture,
      isPositiveFuture
    );
  }

  function _analyzeResults(PredictionResponse memory res) public pure returns (bool, bool) {
    uint btcPriceOffset = (res.btcPricePrediction - res.btcPriceCurrent);

    // We want to check within +/- 5%, hence we"ll multiply current price by 1 / 20
    uint percentModifier = 20;
    uint btcPriceTolerance = res.btcPriceCurrent / percentModifier;

    // 10000 means 1:1 asset:reserve ratio, less means $ assets > $ reserves
    // TODO:
    // bool isInsufficientTUSDRatio = tusdRatio < 9999;
    bool isNegativeBTCSentiment = res.btcSentiment < -5000; // -5000 means -0.5 sentiment from range [-1,1]
    bool isBTCPriceGoingDown = btcPriceOffset < -btcPriceTolerance; // check for > 5% decrease
    bool isNegativeFuture = /*isInsufficientTUSDRatio ||*/ isNegativeBTCSentiment || isBTCPriceGoingDown;

    // bool isSufficientTUSDRatio = tusdRatio >= 10000;
    bool isPositiveBTCSentiment = res.btcSentiment > 5000; // 5000 means 0.5 sentiment from range [-1,1]
    bool isBTCPriceGoingUp = btcPriceOffset > btcPriceTolerance; // check for > 5% increase
    bool isPositiveFuture = /*isSufficientTUSDRatio &&*/ isPositiveBTCSentiment && isBTCPriceGoingUp;

    return (isNegativeFuture, isPositiveFuture);
  }

  ////////////////////////////////
  // Automatic balance swapping //
  ////////////////////////////////

  // NOTE: This should only be called by the Keeper
  function smartSwapAllBalances() external override {
    OracleMaster(oracleMasterAddr).executeAnalysis(address(this), this._processAnalysisAuto.selector);
  }

  // SECURITY RISK!!!
  // TODO: This poses a security risk where anyone can call this function and trigger an auto-swap
  // at will. This needs to be patched ASAP
  function _processAnalysisAuto(PredictionResponse memory res) public {
    bool isNegativeFuture;
    bool isPositiveFuture;

    (isNegativeFuture, isPositiveFuture) = _analyzeResults(res);

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

    emit PredictionResults(
      res.btcPriceCurrent,
      res.btcPricePrediction,
      res.tusdAssetsAmt,
      res.tusdReservesAmt,
      res.btcSentiment,

      isNegativeFuture,
      isPositiveFuture
    );
  }

  ////////////////////////////
  // Chainlink Keeper Logic //
  ////////////////////////////

  // function checkUpkeep(bytes calldata /* checkData */) external override returns (bool upkeepNeeded, bytes memory /* performData */) {
  //   bool hasIntervalPassed = (block.timestamp - lastTimeStamp) > interval;
  //   upkeepNeeded = hasIntervalPassed && _isAtleastOneUserOptIn();
  //   return (upkeepNeeded, bytes(""));
  //   // We don"t use the checkData in this example. The checkData is defined when the Upkeep was registered.
  // }

  // function performUpkeep(bytes calldata /* performData */) external override {
  //   lastTimeStamp = block.timestamp;
  //   swapAllUsersBalances(false);
  //   // We don"t use the performData in this example. The performData is generated by the Keeper"s call to your checkUpkeep function
  // }
}
