// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

// 3rd-party library imports
import { IUniswapV2Router02 } from "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Router02.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// 1st-party project imports
import { Constants } from "./Constants.sol";
import { SwapUser } from "./DataStructures.sol";

contract TokenSwapper {
  address private tusdTokenAddr;
  address private wbtcTokenAddr;

  constructor(address _tusdTokenAddr, address _wbtcTokenAddr) public {
    tusdTokenAddr = _tusdTokenAddr;
    wbtcTokenAddr = _wbtcTokenAddr;
  }

  /*
   * Generic function to approve and perform swap from starting to ending token
   */
  function _swapTokens(uint _inputAmt, address[] memory _tokenPath) internal returns (uint) {
    // First get approval to transfer from starting to ending token via the router
    require(
      IERC20(_tokenPath[0]).approve(Constants.SUSHIV2_ROUTER02_ADDRESS, _inputAmt),
      "APPROVE_SWAP_START_TOKEN_FAIL"
    );

    IUniswapV2Router02 swapRouter = IUniswapV2Router02(
      Constants.SUSHIV2_ROUTER02_ADDRESS
    );

    // Finally, perform the swap from starting to ending token via the token path specified
    uint[] memory swappedAmts = swapRouter.swapExactTokensForTokens(
      _inputAmt,       // amount in terms of starting token
      1,               // min amount expected in terms of ending token
      _tokenPath,      // path of swapping from starting to ending token
      address(this),   // address of where the starting & ending token assets are/will be held
      block.timestamp  // expiry time for transaction
    );

    return swappedAmts[swappedAmts.length - 1];
  }

  /*
   * Swapping TUSD -> BTC (WBTC)
   */
  function swapToWBTC(SwapUser memory _user) external returns (SwapUser memory) {
    require(_user.tusdBalance > 0, "USER_SWAP_TUSD_NOT_FOUND");

    // HACK: This form of array initialization is used to bypass a type cast error
    address[] memory path = new address[](2);
    path[0] = tusdTokenAddr;
    path[1] = wbtcTokenAddr;

    uint addedWbtcBalance = _swapTokens(_user.tusdBalance, path);

    _user.tusdBalance = 0;
    _user.wbtcBalance += addedWbtcBalance;

    return _user;
  }

  /*
   * Swapping BTC (WBTC) -> TUSD
   */
  function swapToTUSD(SwapUser memory _user) external returns (SwapUser memory) {
    require(_user.wbtcBalance > 0, "USER_SWAP_WBTC_NOT_FOUND");

    // HACK: This form of array initialization is used to bypass a type cast error
    address[] memory path = new address[](2);
    path[0] = wbtcTokenAddr;
    path[1] = tusdTokenAddr;

    uint addedTusdBalance = _swapTokens(_user.wbtcBalance, path);

    _user.tusdBalance += addedTusdBalance;
    _user.wbtcBalance = 0;

    return _user;
  }
}
