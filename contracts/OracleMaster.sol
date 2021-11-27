// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

// 3rd-party library imports
import { Chainlink, ChainlinkClient } from "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

// 1st-party project imports
import { Constants } from "./Constants.sol";

// Chainlink oracle code goes here
contract OracleMaster is ChainlinkClient {
  // uint private tusdRatio;
  int private btcSentiment;
  int private btcPriceCurrent;
  int private btcPricePrediction;

  address private cbAddress;
  bytes4 private cbFunction;

  constructor() public {
    setChainlinkToken(Constants.KOVAN_LINK_TOKEN);
  }

  function executeAnalysis(address _callbackAddress, bytes4 _callbackFunctionId) external {
    cbAddress = _callbackAddress;
    cbFunction = _callbackFunctionId;

    _startPredictionAnalysis();
  }

  function sendResults() internal {
    bytes memory data = abi.encodeWithSelector(
      cbFunction,
      btcSentiment, btcPriceCurrent, btcPricePrediction
    );

    (bool success,) = cbAddress.delegatecall(data);
    require(success, "Unable to create request");
  }

  function _startPredictionAnalysis() private {
    // requestTUSDRatio();
    requestBTCSentiment();
    // requestBTCPriceCurrent();
  }

  /////////////////////
  // Currency Ratios //
  /////////////////////
  
  // function requestTUSDRatio() internal {
  //   Chainlink.Request memory req = buildChainlinkRequest(Constants.TUSD_RATIO_JOB_ID, address(this), this.getTUSDRatio.selector);
  //   sendChainlinkRequestTo(Constants.TUSD_RATIO_ORACLE_ADDR, req, Constants.ONE_TENTH_LINK_PAYMENT);
  // }

  // function getTUSDRatio(bytes32 _requestID, uint _ratio) public recordChainlinkFulfillment(_requestID) {
  //   tusdRatio = _ratio;
  //   requestBTCSentiment();
  // }

  ///////////////////////////
  // BTC Sentiment Analyis //
  ///////////////////////////

  function requestBTCSentiment() internal {
    Chainlink.Request memory req = buildChainlinkRequest(Constants.SENTIMENT_JOB_ID, address(this), this.getBTCSentiment.selector);
    req.add("endpoint", "crypto-sentiment");
    req.add("token", "BTC");
    req.add("period", "24");
    sendChainlinkRequestTo(Constants.SENTIMENT_ORACLE_ADDR, req, Constants.ONE_TENTH_LINK_PAYMENT);
  }

  function getBTCSentiment(bytes32 _requestID, int _btcSentiment) public recordChainlinkFulfillment(_requestID) {
    btcSentiment = _btcSentiment;
    requestBTCPriceCurrent();
  }

  ///////////////////////////
  // BTC Price Predictions //
  ///////////////////////////
  
  function requestBTCPriceCurrent() internal {
    AggregatorV3Interface priceFeed = AggregatorV3Interface(Constants.BTC_USD_PRICE_FEED_ADDR);

    (,btcPriceCurrent,,,) = priceFeed.latestRoundData();
    
    requestBTCPricePrediction();
  }

  function requestBTCPricePrediction() internal {
    Chainlink.Request memory req = buildChainlinkRequest(Constants.PRICE_JOB_ID, address(this), this.getBTCPricePrediction.selector);
    req.add("endpoint", "price");
    req.add("days", "1");
    sendChainlinkRequestTo(Constants.PRICE_ORACLE_ADDR, req, Constants.ONE_LINK_PAYMENT);
  }

  function getBTCPricePrediction(bytes32 _requestID, uint _btcPricePrediction) public recordChainlinkFulfillment(_requestID) {
    btcPricePrediction = int(_btcPricePrediction);
    sendResults();
  }
}
