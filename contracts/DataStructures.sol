// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

struct SwapUser {
  // The 'exists' attribute is used purely for checking if a user exists. This works
  // since when you instantiate a new SwapUser, the default value is 'false'
  bool exists;

  uint tusdBalance;
  uint wbtcBalance;
  bool optInStatus;
}

struct PredictionResponse {
  uint btcPriceCurrent;
  uint btcPricePrediction;
  uint tusdAssetsAmt;
  uint tusdReservesAmt;
  int btcSentiment;
}
