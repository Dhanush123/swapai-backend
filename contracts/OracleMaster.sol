// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

// 3rd-party library imports
import { Chainlink, ChainlinkClient } from "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

// 1st-party project imports
import { Constants } from "./Constants.sol";
import { SwapUser } from "./DataStructures.sol";
import { TokenSwapper } from "./TokenSwapper.sol";

// Chainlink oracle code goes here
contract OracleMaster is ChainlinkClient {
  using SafeMath for uint;
  using Address for address;
  
  uint private tusdRatio;
  uint private btcSentiment;
  uint private btcPriceCurrent;
  uint private btcPricePrediction;

  bool private force;
  TokenSwapper private swapper;
  SwapUser[] private currentUsersToSwap;

  event SwapUsersBalances(
    uint tusdRatio,
    uint btcSentiment,
    uint btcPriceCurrent,
    uint btcPricePrediction,
    bool isNegativeFuture,
    bool isPositiveFuture,
    SwapUser[] users
  );

  constructor() public {
    swapper = new TokenSwapper();
  }

  // Should only be called by keeper
  function trySwapAuto(SwapUser[] memory _currentUsersToSwap, bool _force) external {
    for (uint i = 0; i < _currentUsersToSwap.length; i++) {
      currentUsersToSwap[i] = _currentUsersToSwap[i];
    }

    force = _force;

    startPredictionAnalysis();
  }

  function trySwapManual(SwapUser[] memory _currentUsersToSwap, bool swapToTUSD) external {
    for (uint i = 0; i < _currentUsersToSwap.length; i++) {
      currentUsersToSwap[i] = _currentUsersToSwap[i];
    }

    for (uint i = 0; i < currentUsersToSwap.length; i++) {
      swapper.doManualSwap(currentUsersToSwap[i], swapToTUSD);
    }
  }

  function shouldSwap() private {
    // bool isInsufficientTUSDRatio = tusdRatio < 9999; // 10000 means 1:1 asset:reserve ratio, less means $ assets > $ reserves
    bool isNegativeBTCSentiment = btcSentiment < 2500; // 5000 means 0.5 sentiment from range [-1,1]
    bool isBTCPriceGoingDown = (btcPriceCurrent / btcPricePrediction * 10**8) > 105000000; // check if > 5% decrease
    // bool isNegativeFuture = isInsufficientTUSDRatio || isNegativeBTCSentiment || isBTCPriceGoingDown;
    bool isNegativeFuture = isNegativeBTCSentiment || isBTCPriceGoingDown;
    
    // bool isSufficientTUSDRatio = tusdRatio >= 10000; 
    bool isPositiveBTCSentiment = btcSentiment > 7500; 
    bool isBTCPriceGoingUp = (btcPriceCurrent / btcPricePrediction * 10**8) < 95000000; // check if > 5% increase
    // bool isPositiveFuture = isSufficientTUSDRatio && isPositiveBTCSentiment && isBTCPriceGoingUp;
    bool isPositiveFuture = isPositiveBTCSentiment && isBTCPriceGoingUp;
    
    for (uint i = 0; i < currentUsersToSwap.length; i++) {
      swapper.doAutoSwap(currentUsersToSwap[i], isPositiveFuture, isNegativeFuture);
    }

    emit SwapUsersBalances(tusdRatio, btcSentiment, btcPriceCurrent, btcPricePrediction, isNegativeFuture, isPositiveFuture, currentUsersToSwap);
  }

  function startPredictionAnalysis() private {
    // requestTUSDRatio();
    requestBTCSentiment();
  }

  /////////////////////
  // Currency Ratios //
  /////////////////////
  
  function requestTUSDRatio() internal {
    Chainlink.Request memory req = buildChainlinkRequest(Constants.TUSD_RATIO_JOB_ID, address(this), this.getTUSDRatio.selector);
    sendChainlinkRequestTo(Constants.TUSD_RATIO_ORACLE_ADDR, req, Constants.ONE_TENTH_LINK_PAYMENT);
  }

  function getTUSDRatio(bytes32 _requestID, uint _ratio) public recordChainlinkFulfillment(_requestID) {
    tusdRatio = _ratio;
    requestBTCSentiment();
  }

  ///////////////////////////
  // BTC Sentiment Analyis //
  ///////////////////////////

  function requestBTCSentiment() internal {
    Chainlink.Request memory req = buildChainlinkRequest(Constants.SENTIMENT_JOB_ID, address(this), this.getBTCSentiment.selector);
    req.add("token", "BTC");
    req.add("period", "24");
    sendChainlinkRequestTo(Constants.SENTIMENT_ORACLE_ADDR, req, Constants.ONE_TENTH_LINK_PAYMENT);
  }

  function getBTCSentiment(bytes32 _requestID, uint _btcSentiment) public recordChainlinkFulfillment(_requestID) {
    btcSentiment = _btcSentiment;
    requestBTCPriceCurrent();
  }

  ///////////////////////////
  // BTC Price Predictions //
  ///////////////////////////
  
  function requestBTCPriceCurrent() internal {
    AggregatorV3Interface priceFeed = AggregatorV3Interface(Constants.BTC_USD_PRICE_FEED_ADDR);

    (,int price,,,) = priceFeed.latestRoundData();

    // We're assuming that price will *never* be negative
    btcPriceCurrent = uint(price);
    
    requestBTCPricePrediction();
  }

  function requestBTCPricePrediction() internal {
    Chainlink.Request memory req = buildChainlinkRequest(Constants.PRICE_JOB_ID, address(this), this.getBTCPricePrediction.selector);
    req.add("days", "1");
    sendChainlinkRequestTo(Constants.PRICE_ORACLE_ADDR, req, Constants.ONE_LINK_PAYMENT);
  }

  function getBTCPricePrediction(bytes32 _requestID, uint _btcPricePrediction) public recordChainlinkFulfillment(_requestID) {
    btcPricePrediction = _btcPricePrediction;
    shouldSwap();
  }
}
