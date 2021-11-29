// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

// 3rd-party library imports
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import { ChainlinkClient, Chainlink } from "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";

// 1st-party project imports
import { Constants } from "./Constants.sol";
import { PredictionResponse } from "./DataStructures.sol";

import { OracleAggregator } from "./utility/OracleAggregator.sol";
import { OracleJob } from "./utility/OracleJob.sol";
import { JobBuilder } from "./utility/JobBuilder.sol";

// import { PseudoRandom } from "./utility/PseudoRandom.sol";

// Chainlink oracle code goes here
contract OracleMaster is ChainlinkClient {
  using JobBuilder for OracleJob;

  PredictionResponse private res;
  address private cbAddress;
  bytes4 private cbFunction;

  constructor() public {
    setChainlinkToken(Constants.KOVAN_LINK_TOKEN);
  }

  function generateRandom(uint max) public view returns(uint256) {
    uint256 seed = uint256(keccak256(abi.encodePacked(
      block.timestamp + block.difficulty +
      ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)) +
      block.gaslimit +
      ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)) +
      block.number
    )));

    return (seed - ((seed / max) * max));
  }

  function executeAnalysis(address callbackAddress, bytes4 callbackFunc) external {
    cbAddress = callbackAddress;
    cbFunction = callbackFunc;

    _startPredictionAnalysis();
  }

  function _isResponseReady(PredictionResponse memory _res) private pure returns (bool) {
    return /*_res.btcPriceCurrent != 0 &&*/
      _res.tusdAssetsAmt != 0 &&
      _res.tusdReservesAmt != 0 /*&&
      _res.btcSentiment != 0*/;
  }

  function checkResponse(PredictionResponse memory _res) private {
    if (_isResponseReady(_res)) {
      // Call the callback function on the callback contract address
      bytes memory data = abi.encodeWithSelector(cbFunction, res);
      (bool success,) = cbAddress.call(data);
      require(success, "Unable to submit OracleMaster results to callback");
    }
  }

  function _startPredictionAnalysis() private {
    /////////////////////////////
    // Fetch current BTC price //
    /////////////////////////////

    AggregatorV3Interface priceFeed = AggregatorV3Interface(Constants.BTC_USD_PRICE_FEED_ADDR);
    (,int btcCurrentPrice,,,) = priceFeed.latestRoundData();

    res.btcPriceCurrent = uint(btcCurrentPrice);

    //////////////////////////////////////
    // Prepare BTC price prediction job //
    //////////////////////////////////////

    // TODO: For now, we're just (insecurely) generating some values

    // 10,000 = 100.00%
    // 1,000  = 10.00%
    // 100    = 1.00%
    // 10     = 0.10%
    // 1      = 0.01%

    uint _randBtcPredictRaw = generateRandom(2000);
    int percentMod = int(_randBtcPredictRaw) - 1000;
    int priceMod = int(btcCurrentPrice) * percentMod / 10000;
    res.btcPricePrediction = uint(btcCurrentPrice + priceMod);

    // NOTE: Commented out since there's no equivalent on Kovan testnet

    // OracleJob memory btcPricePredictionJob = super
    //   .createJob()
    //   .setOracle(
    //     Constants.PRICE_ORACLE_ADDR,
    //     Constants.PRICE_JOB_ID,
    //     Constants.ONE_LINK_PAYMENT
    //   )
    //   .withCallback(
    //     address(this),
    //     this.getBTCPricePrediction.selector
    //   );

    // btcPricePredictionJob.request.add("endpoint", "price");
    // btcPricePredictionJob.request.add("symbol", "BTC");
    // btcPricePredictionJob.request.add("days", "1");

    /////////////////////////////
    // Prepare TUSD assets job //
    /////////////////////////////

    // OracleJob memory tusdAssetsJob = super
    //   .createJob()
    //   .setOracle(
    //     Constants.HTTP_GET_ORACLE_ADDR,
    //     Constants.HTTP_GET_JOB_ID,
    //     Constants.ONE_TENTH_LINK_PAYMENT
    //   )
    //   .withCallback(
    //     address(this),
    //     this.getTusdAssets.selector
    //   );

    // Chainlink.Request memory tusdAssetsReq;
    // tusdAssetsReq.add("get", Constants.TUSD_URL);
    // tusdAssetsReq.add("path", "responseData.totalToken");
    // tusdAssetsReq.addInt("times", int(Constants.TUSD_MULT_AMT));
    // tusdAssetsJob.request = tusdAssetsReq;

    // uint _randTsudAssetsAmt = generateRandom(10 ** 16);
    // res.tusdAssetsAmt = 10 ** 17 + _randTsudAssetsAmt;

    Chainlink.Request memory tusdAssetsReq = buildChainlinkRequest(
      Constants.HTTP_GET_JOB_ID, address(this), this.getTusdAssets.selector
    );
    tusdAssetsReq.add("get", Constants.TUSD_URL);
    tusdAssetsReq.add("path", "responseData.totalToken");
    tusdAssetsReq.addInt("times", int(Constants.TUSD_MULT_AMT));

    sendChainlinkRequestTo(Constants.HTTP_GET_ORACLE_ADDR, tusdAssetsReq, Constants.ONE_TENTH_LINK_PAYMENT);

    ///////////////////////////////
    // Prepare TUSD reserves job //
    ///////////////////////////////

    // OracleJob memory tusdReservesJob = super
    //   .createJob()
    //   .setOracle(
    //     Constants.HTTP_GET_ORACLE_ADDR,
    //     Constants.HTTP_GET_JOB_ID,
    //     Constants.ONE_TENTH_LINK_PAYMENT
    //   )
    //   .withCallback(
    //     address(this),
    //     this.getTusdReserves.selector
    //   );

    // uint _randTsudReservesAmt = generateRandom(10 ** 16);
    // res.tusdReservesAmt = 10 ** 17 + _randTsudReservesAmt;

    Chainlink.Request memory tusdReservesReq = buildChainlinkRequest(
      Constants.HTTP_GET_JOB_ID, address(this), this.getTusdReserves.selector
    );
    tusdReservesReq.add("get", Constants.TUSD_URL);
    tusdReservesReq.add("path", "responseData.totalTrust");
    tusdReservesReq.addInt("times", int(Constants.TUSD_MULT_AMT));

    sendChainlinkRequestTo(Constants.HTTP_GET_ORACLE_ADDR, tusdReservesReq, Constants.ONE_TENTH_LINK_PAYMENT);

    // tusdReservesJob.request = tusdReservesReq;

    ///////////////////////////////////////
    // Prepare BTC sentiment analyis job //
    ///////////////////////////////////////

    // TODO: For now, we're just (insecurely) generating some values

    uint _randBtcSentimentRaw = generateRandom(20000);
    res.btcSentiment = int(_randBtcSentimentRaw) - 10000;

    // NOTE: Commented out since there's no equivalent on Kovan testnet

    // OracleJob memory btcSentimentJob = super
    //   .createJob()
    //   .setOracle(
    //     Constants.SENTIMENT_ORACLE_ADDR,
    //     Constants.SENTIMENT_JOB_ID,
    //     Constants.ONE_TENTH_LINK_PAYMENT
    //   )
    //   .withCallback(
    //     address(this),
    //     this.getBTCSentiment.selector
    //   );

    // btcSentimentJob.request.add("endpoint", "crypto-sentiment");
    // btcSentimentJob.request.add("token", "BTC");
    // btcSentimentJob.request.add("period", "24");

    /////////////////////////////
    // Execute all oracle jobs //
    /////////////////////////////

    // super.executeJob(btcPricePredictionJob);
    // super.executeJob(tusdAssetsJob);
    // super.executeJob(tusdReservesJob);
    // super.executeJob(btcSentimentJob);
  }

  ///////////////////////////
  // Fulfillment Functions //
  ///////////////////////////

  // function getBTCPricePrediction(bytes32 _requestID, uint _btcPricePrediction) public recordChainlinkFulfillment(_requestID) {
  //   res.btcPricePrediction = _btcPricePrediction;
  //   checkResponse(res);
  // }

  event UintLog(uint value);

  function getTusdAssets(bytes32 _requestID, uint _tusdAssetsAmt) public recordChainlinkFulfillment(_requestID) {
    emit UintLog(_tusdAssetsAmt);
    res.tusdAssetsAmt = _tusdAssetsAmt;
    checkResponse(res);
  }

  function getTusdReserves(bytes32 _requestID, uint _tusdReservesAmt) public recordChainlinkFulfillment(_requestID) {
    emit UintLog(_tusdReservesAmt);
    res.tusdReservesAmt = _tusdReservesAmt;
    checkResponse(res);
  }

  // function getBTCSentiment(bytes32 _requestID, int _btcSentiment) public recordChainlinkFulfillment(_requestID) {
  //   res.btcSentiment = _btcSentiment;
  //   checkResponse(res);
  // }
}
