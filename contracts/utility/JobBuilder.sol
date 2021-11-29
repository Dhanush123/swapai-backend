// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

// 3rd-party library imports
import { Chainlink, ChainlinkClient } from "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";
import { BufferChainlink } from "@chainlink/contracts/src/v0.6/vendor/BufferChainlink.sol";

// 1st-party library imports
import { OracleJob } from "./OracleJob.sol";

library JobBuilder {
  // Copied from @chainlink/contracts/src/v0.6/Chainlink.sol
  uint256 internal constant REQ_DEFAULT_BUFFER_SIZE = 256;

  using Chainlink for Chainlink.Request;

  function initialize(
    OracleJob memory self
  ) internal pure returns (OracleJob memory) {
    BufferChainlink.init(self.request.buf, REQ_DEFAULT_BUFFER_SIZE);
  }

  function setOracle(
    OracleJob memory self,
    address oracleAddress,
    bytes32 specId,
    uint256 fee
  ) internal pure returns (OracleJob memory) {
    self.oracleAddress = oracleAddress;
    self.specId = specId;
    self.fee = fee;
    return self;
  }

  function withCallback(
    OracleJob memory self,
    address cbAddress,
    bytes4 cbFunction
  ) internal pure returns (OracleJob memory) {
    self.cbAddress = cbAddress;
    self.cbFunction = cbFunction;
    return self;
  }
}
