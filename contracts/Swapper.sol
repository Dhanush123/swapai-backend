pragma solidity ^0.8.7;

// 3rd-party library imports
import "@sushiswap/core/contracts/uniswapv2/UniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// 1st-party project imports
import "./Constants.sol";

contract Swapper is UniswapV2Router02 {
  ////////////////////
  // USER FUNCTIONS //
  ////////////////////

  function depositTUSD(uint _inputAmt) external {
    ERC20 TUSD = ERC20(Constants.KOVAN_TUSD);

    require(
      TUSD.transferFrom(msg.sender, address(this), _inputAmt),
      'Transfering of funds to contract failed.'
    );
  }

  function withdrawTUSD() internal {
    // TODO
  }

  //////////////////////////
  // AUTONOMOUS FUNCTIONS //
  //////////////////////////

  /*
   * Generic function to approve and perform swap from starting to ending token
   */
  function _swap(address _user, uint _inputAmt, address[] calldata _tokenPath) internal returns (uint) {
    ERC20 startToken = ERC20(_tokenPath[0]);

    // First get approval from the router to transfer from starting to ending token
    require(
      startToken.approve(Constants.SUSHIV2_ROUTER02, _inputAmt),
      'Approval for swapping from starting token failed.'
    );

    // Finally, perform the swap from starting to ending token via the token path specified
    uint[] memory swappedAmts = this.swapExactTokensForTokens(
      _inputAmt,                                // amount in terms of starting token
      Constants.MIN_OUTPUT_AMT,                 // min amount expected in terms of ending token
      _tokenPath,                               // path of swapping from starting to ending token
      _user,                                    // address of where the starting & ending token assets are/will be held
      block.timestamp + Constants.TX_DEF_EXPIRY // expiry date & time for transaction
    );

    return swappedAmts[swappedAmts.length - 1];
  }

  /*
   * Swapping TUSD -> BTC (WBTC)
   */
  function _swapTUSDtoWBTC(address _user, uint _inputAmt) internal returns (uint) {
    // require(_user.tusdBalance > 0, 'User does not have any TUSD to swap to WBTC');
    
    if (_user.tusdBalance > 0) {
      // Swap from TUSD in favor of WBTC (manual swap)

      address[3] memory path = [
        Constants.KOVAN_TUSD,
        Constants.KOVAN_WETH,
        Constants.KOVAN_WBTC
      ];

      uint finalWbtcBalance = _swap(_user.userAddress, _user.tusdBalance, path);

      _user.tusdBalance = 0;
      _user.wbtcBalance = finalWbtcBalance;
    }
  }

  /*
   * Swapping BTC (WBTC) -> TUSD
   */
  function _swapWBTCtoTUSD(SwapUser _user, uint _inputAmt) internal returns (uint) {
    // require(_user.wbtcBalance > 0, 'User does not have any WBTC to swap to TUSD');
    
    if (_user.wbtcBalance > 0) {
      // Swap from WBTC in favor of TUSD (manual swap)

      address[3] memory path = [
        Constants.KOVAN_WBTC,
        Constants.KOVAN_WETH,
        Constants.KOVAN_TUSD
      ];

      uint finalTusdBalance = _swap(_user.userAddress, _user.wbtcBalance, path);

      _user.tusdBalance = finalTusdBalance;
      _user.wbtcBalance = 0;
    }
  }

  function doManualSwap(SwapUser _user, bool swapTUSD) {
    if (swapTUSD) {
      // Swap from TUSD in favor of WBTC (manual swap)
      _swapTUSDtoWBTC();
    } else {
      // Swap from WBTC in favor of TUSD (manual swap)
      _swapWBTCtoTUSD();
    }
  }

  function doAutoSwap(SwapUser _user, bool isPositiveFuture, bool isNegativeFuture) external {
    if (isPositiveFuture) {
      // Swap from TUSD in favor of WBTC to capitalize on gains
      _swapTUSDtoWBTC();
    } else if (isNegativeFuture) {
      // Swap from WBTC in favor of TUSD to minimize losses
      _swapWBTCtoTUSD();
    }
    // Otherwise do nothing
  }
}
