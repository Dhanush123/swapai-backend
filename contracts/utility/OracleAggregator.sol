// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

// 3rd-party library imports
import { ChainlinkClient } from "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";

// 1st-party project imports
import { OracleJob } from "./OracleJob.sol";
import { JobBuilder } from "./JobBuilder.sol";

contract OracleAggregator is ChainlinkClient {
  using JobBuilder for OracleJob;

  //////////////////////
  // Real oracle jobs //
  //////////////////////

  function createJob() internal pure returns (OracleJob memory) {
    OracleJob memory job;
    job.initialize();
    return job;
  }

  function executeJob(
    OracleJob memory job
  ) internal {
    // NOTE: Equivalent to buildChainlinkRequest()
    job.request.initialize(job.specId, job.cbAddress, job.cbFunction);

    super.sendChainlinkRequestTo(job.oracleAddress, job.request, job.fee);
  }

  // //////////////////////
  // // Mock oracle jobs //
  // //////////////////////

  // function createMockJob() internal pure returns (MockOracleJob memory) {
  //   MockOracleJob memory mjob;
  //   mjob.initialize();
  //   return mjob;
  // }

  // function executeMockJob(
  //   OracleJob memory job
  // ) internal {
  //   // NOTE: Equivalent to buildChainlinkRequest()
  //   job.request.initialize(job.specId, job.cbAddress, job.cbFunction);

  //   super.sendChainlinkRequestTo(job.oracleAddress, job.request, job.fee);
  // }
}
