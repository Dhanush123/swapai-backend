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
  // tusdTokenAmt and tusdTrustAmt real values are multiplied by Constants.TUSD_MULT_AMT
  // TODO: to calculate ratio, ((tusdTokenAmt/tusdTrustAmt) *  10**12) and check > or <= 990000000000
  // example : ((1286617884.5602689 * 10**7) / (1299420882.5 * 10**7)) * 10**12 = 990147150848
  int tusdTokenAmt;
  int tusdTrustAmt;
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
    requestTUSDToken();
    requestTUSDTrust();
    requestBTCSentiment();
    // requestBTCPriceCurrent();
  }

  /////////////////////
  // Currency Ratios //
  /////////////////////
  
  function requestTUSDToken() internal {
    Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.getTUSDToken.selector);
    request.add("get", Constants.TUSD_URL);
    request.add("path", "responseData.totalToken");
    request.addInt("times", Constants.TUSD_MULT_AMT);
    return sendChainlinkRequestTo(oracle, request, fee);
  }

  function getTUSDToken(bytes32 _requestID, uint _tusdTokenAmt) public recordChainlinkFulfillment(_requestID) {
    tusdTokenAmt = _tusdTokenAmt; // example value 1286617884.5602689 * 10**7
  }

  function requestTUSDTrust() internal {
    Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.getTUSDTrust.selector);
    request.add("get", Constants.TUSD_URL);
    request.add("path", "responseData.totalTrust");
    request.addInt("times", Constants.TUSD_MULT_AMT);
    return sendChainlinkRequestTo(oracle, request, fee);
  }

  function getTUSDTrust(bytes32 _requestID, uint _tusdTrustAmt) public recordChainlinkFulfillment(_requestID) {
    tusdTrustAmt = _tusdTrustAmt; // example value 1299420882.5 * 10**7
  }

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
