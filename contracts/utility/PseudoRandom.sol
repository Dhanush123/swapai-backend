// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

library PseudoRandom {
  function generate(uint max) public view returns(uint256) {
    uint256 seed = uint256(keccak256(abi.encodePacked(
      block.timestamp + block.difficulty +
      ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)) +
      block.gaslimit +
      ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)) +
      block.number
    )));

    return (seed - ((seed / max) * max));
  }
}
