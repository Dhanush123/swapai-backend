// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

// 3rd-party library imports
import { Chainlink } from "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";

struct OracleJob {
  address oracleAddress;
  bytes32 specId;
  uint256 fee;
  address cbAddress;
  bytes4 cbFunction;

  Chainlink.Request request;
}
