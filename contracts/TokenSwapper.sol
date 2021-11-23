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
      'Approval for swapping from starting token failed.'
    );

    IUniswapV2Router02 swapRouter = IUniswapV2Router02(
      Constants.SUSHIV2_ROUTER02_ADDRESS
    );

    // Finally, perform the swap from starting to ending token via the token path specified
    uint[] memory swappedAmts = swapRouter.swapExactTokensForTokens(
      _inputAmt,                 // amount in terms of starting token
      Constants.MIN_OUTPUT_AMT,  // min amount expected in terms of ending token
      _tokenPath,                // path of swapping from starting to ending token
      address(this),             // address of where the starting & ending token assets are/will be held
      block.timestamp            // expiry time for transaction
    );

    return swappedAmts[swappedAmts.length - 1];
  }

  /*
   * Swapping TUSD -> BTC (WBTC)
   */
  function _swapTUSDtoWBTC(SwapUser memory _user) internal returns (uint) {
    // require(_user.tusdBalance > 0, 'User does not have any TUSD to swap to WBTC');

    if (_user.tusdBalance > 0) {
      // Swap from TUSD in favor of WBTC (manual swap)

      // HACK: This form of array initialization is used to bypass a type cast error
      address[] memory path = new address[](2);
      path[0] = tusdTokenAddr;
      path[1] = wbtcTokenAddr;

      uint finalWbtcBalance = _swapTokens(_user.tusdBalance, path);

      _user.tusdBalance = 0;
      _user.wbtcBalance = finalWbtcBalance;
    }
  }

  /*
   * Swapping BTC (WBTC) -> TUSD
   */
  function _swapWBTCtoTUSD(SwapUser memory _user) internal returns (uint) {
    // require(_user.wbtcBalance > 0, 'User does not have any WBTC to swap to TUSD');

    if (_user.wbtcBalance > 0) {
      // Swap from WBTC in favor of TUSD (manual swap)

      // HACK: This form of array initialization is used to bypass a type cast error
      address[] memory path = new address[](2);
      path[0] = wbtcTokenAddr;
      path[1] = tusdTokenAddr;

      uint finalTusdBalance = _swapTokens(_user.wbtcBalance, path);

      _user.tusdBalance = finalTusdBalance;
      _user.wbtcBalance = 0;
    }
  }

  function doManualSwap(SwapUser memory _user, bool swapToTUSD) external {
    if (swapToTUSD) {
      // Swap from WBTC to TUSD (manual swap)
      _swapWBTCtoTUSD(_user);
    } else {
      // Swap from TUSD to WBTC (manual swap)
      _swapTUSDtoWBTC(_user);
    }
  }

  function doAutoSwap(SwapUser memory _user, bool isPositiveFuture, bool isNegativeFuture) external {
    if (isPositiveFuture) {
      // Swap from TUSD in favor of WBTC to capitalize on gains
      _swapTUSDtoWBTC(_user);
    } else if (isNegativeFuture) {
      // Swap from WBTC in favor of TUSD to minimize losses
      _swapWBTCtoTUSD(_user);
    }
    // Otherwise do nothing
  }
}
