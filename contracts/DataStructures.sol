// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

struct SwapUser {
  address userAddress;
  uint wbtcBalance;
  uint tusdBalance;
  bool optInStatus;
}

struct PredictionResponse {
  // uint tusdRatio;
  uint btcSentiment;
  uint btcPriceCurrent;
  uint btcPricePrediction;
  bool isNegativeFuture;
  bool isPositiveFuture;
}

struct JobInfo {
  bytes32 jobId;
  address cbAddress;
  bytes4 cbSignature;
  address oracleAddress;
  uint256 fee;
}

enum SwapDirection {
  toTUSD, toWBTC
}
