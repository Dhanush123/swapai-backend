// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TUSDToken is ERC20 {
  constructor(
    address recipientA, uint256 initialSupplyA,
    address recipientB, uint256 initialSupplyB
  ) public ERC20("TrueUSD", "TUSD") {
    _setupDecimals(18);
    _mint(recipientA, initialSupplyA * (10 ** uint256(decimals())));
    _mint(recipientB, initialSupplyB * (10 ** uint256(decimals())));
  }
}
