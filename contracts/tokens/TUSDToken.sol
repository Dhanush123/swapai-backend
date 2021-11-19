// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TUSDToken is ERC20 {
  using SafeERC20 for IERC20;

  constructor(uint256 initialSupply) ERC20("TrueUSD", "TUSD") public {
    _setupDecimals(18);
    _mint(msg.sender, initialSupply * (10 ** uint256(decimals())));
  }
}
