// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

// 3rd-party library imports
import { UniswapV2Router02 } from "@sushiswap/core/contracts/uniswapv2/UniswapV2Router02.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

// 1st-party project imports
import { Constants } from "./Constants.sol";
import { SwapUser } from "./DataStructures.sol";

contract TokenSwapper {
  using SafeMath for uint;
  using Address for address;
  using SafeERC20 for IERC20;

  function depositTUSD(uint _inputAmt) external {
    IERC20 TUSD = IERC20(Constants.KOVAN_TUSD);

    require(
      TUSD.transferFrom(msg.sender, address(this), _inputAmt),
      'Transfering of funds to contract failed.'
    );
  }

  function withdrawTUSD() internal {
    // TODO
  }

  /*
   * Generic function to approve and perform swap from starting to ending token
   */
  function _swapTokens(address _user, uint _inputAmt, address[] memory _tokenPath) internal returns (uint) {
    IERC20 startToken = IERC20(_tokenPath[0]);

    // First get approval from the router to transfer from starting to ending token
    require(
      startToken.approve(_user, _inputAmt),
      'Approval for swapping from starting token failed.'
    );

    UniswapV2Router02 swapRouter = new UniswapV2Router02(
      Constants.SUSHIV2_ROUTER02_ADDRESS,
      address(0) // TODO: FIX THIS
    );

    // Finally, perform the swap from starting to ending token via the token path specified
    uint[] memory swappedAmts = swapRouter.swapExactTokensForTokens(
      _inputAmt,                                 // amount in terms of starting token
      Constants.MIN_OUTPUT_AMT,                  // min amount expected in terms of ending token
      _tokenPath,                                // path of swapping from starting to ending token
      _user,                                     // address of where the starting & ending token assets are/will be held
      block.timestamp + Constants.TX_DEF_EXPIRY  // expiry date & time for transaction
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
      address[] memory path = new address[](3);
      path[0] = Constants.KOVAN_TUSD;
      path[1] = Constants.KOVAN_WETH;
      path[2] = Constants.KOVAN_WBTC;

      uint finalWbtcBalance = _swapTokens(_user.userAddress, _user.tusdBalance, path);

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
      address[] memory path = new address[](3);
      path[0] = Constants.KOVAN_WBTC;
      path[1] = Constants.KOVAN_WETH;
      path[2] = Constants.KOVAN_TUSD;

      uint finalTusdBalance = _swapTokens(_user.userAddress, _user.wbtcBalance, path);

      _user.tusdBalance = finalTusdBalance;
      _user.wbtcBalance = 0;
    }
  }

  function doManualSwap(SwapUser memory _user, bool swapTUSD) external {
    if (swapTUSD) {
      // Swap from TUSD to WBTC (manual swap)
      _swapTUSDtoWBTC(_user);
    } else {
      // Swap from WBTC to TUSD (manual swap)
      _swapWBTCtoTUSD(_user);
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
