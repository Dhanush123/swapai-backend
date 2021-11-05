pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import "./Swapper.sol";

contract OracleCaller {
  using SafeMath for uint;
  using Address for address;
  // Chainlink oracle code goes here
  Swapper private swapper;
  AggregatorV3Interface internal priceFeed;
  uint private constant fee = 0.01 * 1 ether;
  
  uint tusdRatio;
  uint btcSentiment;
  uint btcPriceCurrent;
  uint btcPricePrediction;
  address private constant priceOracleAddress = 0xfF07C97631Ff3bAb5e5e5660Cdf47AdEd8D4d4Fd;
  address private constant sentimentOracleAddress = 0x56dd6586DB0D08c6Ce7B2f2805af28616E082455;
  address private constant ratioOracleAddress = 0xfF07C97631Ff3bAb5e5e5660Cdf47AdEd8D4d4Fd; // replace with custom adapter address
  address private constant btcUsdPriceFeedAddress = 0x6135b13325bfC4B00278B4abC5e20bbce2D6580e;
  bytes32 private constant priceJobID = "35e14dbd490f4e3b9fbe92b85b32d98a";
  bytes32 private constant sentimentJobID = "35e14dbd490f4e3b9fbe92b85b32d98a";
  bytes32 private constant ratioJobID = ""; // replace with custom adapter job id

  constructor() {
    priceFeed = AggregatorV3Interface(btcUsdPriceFeedAddress);
    swapper = Swapper();
  }

  function trySwap() {
    requestTUSDRatio();
  }

  function shouldSwap() {
    bool isInsufficientTUSDRatio = tusdRatio < 9999; // 10000 means 1:1 asset:reserve ratio, less means $ assets > $ reserves
    bool isNegativeBTCSentiment = tusdRatio < 5000; // 5000 means 0.5 sentiment from range [-1,1]
    bool isBTCPriceGoingDown = (btcPriceCurrent/btcPricePrediction * 10**8) > 105000000; // check if > 5% decrease
    bool isNegativeFuture = isInsufficientTUSDRatio || isNegativeBTCSentiment || isBTCPriceGoingDown;
    if (isNegativeFuture) {

    }
  }
  
  function requestTUSDRatio() internal {
    Chainlink.Request memory req = buildChainlinkRequest(ratioJobID, address(this), this.getTUSDRatio.selector);
    sendChainlinkRequestTo(ratioOracleAddress, req, fee);
  }

  function getTUSDRatio(bytes32 _requestID, uint _ratio) public recordChainlinkFulfillment(_requestID) {
    ratio = _ratio;
    requestBTCSentiment();
  }

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