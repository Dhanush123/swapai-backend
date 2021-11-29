// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

// 3rd-party library imports
import { BufferChainlink } from "@chainlink/contracts/src/v0.6/vendor/BufferChainlink.sol";
import { CBORChainlink } from "@chainlink/contracts/src/v0.6/vendor/CBORChainlink.sol";

library JobBuilder {
  // Copied from @chainlink/contracts/src/v0.6/Chainlink.sol
  uint256 internal constant REQ_DEFAULT_BUFFER_SIZE = 256;

  using CBORChainlink for BufferChainlink.buffer;

  struct OracleJob {
    address oracleAddress;
    bytes32 specId;
    uint256 fee;
    address cbAddress;
    bytes4 cbFunction;

    BufferChainlink.buffer buffer;
  }

  function initialize(
    OracleJob memory self
  ) internal pure returns (OracleJob memory) {
    BufferChainlink.init(self.buffer, REQ_DEFAULT_BUFFER_SIZE);
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

  /////////////////////////////////////////////////////////////
  // COPIED FROM @chainlink/contracts/src/v0.6/Chainlink.sol //
  /////////////////////////////////////////////////////////////

  function setBuffer(OracleJob memory self, bytes memory _data)
    internal pure returns (OracleJob memory)
  {
    BufferChainlink.init(self.buffer, _data.length);
    BufferChainlink.append(self.buffer, _data);
    return self;
  }

  function addStringToBuffer(OracleJob memory self, string memory _key, string memory _value)
    internal pure returns (OracleJob memory)
  {
    self.buffer.encodeString(_key);
    self.buffer.encodeString(_value);
    return self;
  }

  function addBytesToBuffer(OracleJob memory self, string memory _key, bytes memory _value)
    internal pure returns (OracleJob memory)
  {
    self.buffer.encodeString(_key);
    self.buffer.encodeBytes(_value);
    return self;
  }

  function addIntegerToBuffer(OracleJob memory self, string memory _key, int256 _value)
    internal pure returns (OracleJob memory)
  {
    self.buffer.encodeString(_key);
    self.buffer.encodeInt(_value);
    return self;
  }

  function addUintegerToBuffer(OracleJob memory self, string memory _key, uint256 _value)
    internal pure returns (OracleJob memory)
  {
    self.buffer.encodeString(_key);
    self.buffer.encodeUInt(_value);
    return self;
  }

  function addStringArrayToBuffer(OracleJob memory self, string memory _key, string[] memory _values)
    internal pure returns (OracleJob memory)
  {
    self.buffer.encodeString(_key);
    self.buffer.startArray();
    for (uint256 i = 0; i < _values.length; i++) {
      self.buffer.encodeString(_values[i]);
    }
    self.buffer.endSequence();
    return self;
  }
}
