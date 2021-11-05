// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

// 3rd-party library imports
import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

// 1st-party project imports
import "./Swapper.sol";
import "./SwapAI.sol";

contract OracleCaller is ChainlinkClient {
  // Chainlink oracle code goes here
  uint private constant fee = 0.01 * 1 ether;
  uint private tusdRatio;
  uint private btcSentiment;
  uint private btcPriceCurrent;
  uint private btcPricePrediction;
  address private constant priceOracleAddress = 0xfF07C97631Ff3bAb5e5e5660Cdf47AdEd8D4d4Fd;
  address private constant sentimentOracleAddress = 0x56dd6586DB0D08c6Ce7B2f2805af28616E082455;
  address private constant ratioOracleAddress = 0xfF07C97631Ff3bAb5e5e5660Cdf47AdEd8D4d4Fd; // replace with custom adapter address
  address private constant btcUsdPriceFeedAddress = 0x6135b13325bfC4B00278B4abC5e20bbce2D6580e;
  bytes32 private constant priceJobID = "35e14dbd490f4e3b9fbe92b85b32d98a";
  bytes32 private constant sentimentJobID = "35e14dbd490f4e3b9fbe92b85b32d98a";
  bytes32 private constant ratioJobID = ""; // replace with custom adapter job id
  bool private force;
  AggregatorV3Interface private priceFeed;
  Swapper private swapper;
  SwapUser[] private currentUsersToSwap;

  event SwapUsersBalances(
    uint tusdRatio,
    uint btcSentiment,
    uint btcPriceCurrent,
    uint btcPricePrediction,
    bool isNegativeFuture,
    SwapUser[] users
  );

  constructor() public {
    priceFeed = AggregatorV3Interface(btcUsdPriceFeedAddress);
    swapper = Swapper();
  }

  // Should only be called by keeper
  function trySwapAuto(SwapUser[] memory _currentUsersToSwap, bool _force) internal {
    currentUsersToSwap = _currentUsersToSwap;
    force = _force;

    startPredictionAnalysis();
  }

  function trySwapManual(SwapUser[] memory _currentUsersToSwap, bool swapToTUSD) internal {
    currentUsersToSwap = _currentUsersToSwap;
    
    for (uint i = 0; i < currentUsersToSwap.length; i++) {
      swapper.doManualSwap(currentUsersToSwap[i], swapToTUSD);
    }
  }

  function shouldSwap() private {
    bool isInsufficientTUSDRatio = tusdRatio < 9999; // 10000 means 1:1 asset:reserve ratio, less means $ assets > $ reserves
    bool isNegativeBTCSentiment = btcSentiment < 2500; // 5000 means 0.5 sentiment from range [-1,1]
    bool isBTCPriceGoingDown = (btcPriceCurrent / btcPricePrediction * 10**8) > 105000000; // check if > 5% decrease
    bool isNegativeFuture = isInsufficientTUSDRatio || isNegativeBTCSentiment || isBTCPriceGoingDown;
    
    bool isSufficientTUSDRatio = tusdRatio >= 10000; 
    bool isPositiveBTCSentiment = btcSentiment > 7500; 
    bool isBTCPriceGoingUp = (btcPriceCurrent / btcPricePrediction * 10**8) < 95000000; // check if > 5% increase
    bool isPositiveFuture = isSufficientTUSDRatio && isPositiveBTCSentiment && isBTCPriceGoingUp;
    
    for (uint i = 0; i < currentUsersToSwap.length; i++) {
      swapper.doAutoSwap(currentUsersToSwap[i], isPositiveFuture, isNegativeFuture);
    }
  }

  function startPredictionAnalysis() private {
    requestTUSDRatio();
  }

  /////////////////////
  // Currency Ratios //
  /////////////////////
  
  function requestTUSDRatio() internal {
    Chainlink.Request memory req = buildChainlinkRequest(ratioJobID, address(this), this.getTUSDRatio.selector);
    sendChainlinkRequestTo(ratioOracleAddress, req, fee);
  }

  function getTUSDRatio(bytes32 _requestID, uint _ratio) public recordChainlinkFulfillment(_requestID) {
    tusdRatio = _ratio;
    requestBTCSentiment();
  }

  ///////////////////////////
  // BTC Sentiment Analyis //
  ///////////////////////////

  function requestBTCSentiment() internal {
    Chainlink.Request memory req = buildChainlinkRequest(sentimentJobID, address(this), this.getBTCSentiment.selector);
    req.add("token", "BTC");
    req.add("period", "24");
    sendChainlinkRequestTo(sentimentOracleAddress, req, fee);
  }

  function getBTCSentiment(bytes32 _requestID, uint _btcSentiment) public recordChainlinkFulfillment(_requestID) {
    btcSentiment = _btcSentiment;
    requestAndGetBTCPriceCurrent();
  }

  ///////////////////////////
  // BTC Price Predictions //
  ///////////////////////////
  
  function requestAndGetBTCPriceCurrent() internal {
    (
        uint80 roundID, 
        int price,
        uint startedAt,
        uint timeStamp,
        uint80 answeredInRound
    ) = priceFeed.latestRoundData();
    btcPriceCurrent = price;
    
    requestBTCPricePrediction();
  }

  function requestBTCPricePrediction() internal {
    Chainlink.Request memory req = buildChainlinkRequest(priceJobID, address(this), this.getBTCPricePrediction.selector);
    req.add("days", "1");
    sendChainlinkRequestTo(priceOracleAddress, req, fee);
  }

  function getBTCPricePrediction(bytes32 _requestID, uint _btcPricePrediction) public recordChainlinkFulfillment(_requestID) {
    btcPricePrediction = _btcPricePrediction;
    shouldSwap();
  }
}
