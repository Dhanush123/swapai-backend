// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

// 3rd-party library imports
import { IUniswapV2Factory } from "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Router02 } from "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Router02.sol";
import { IUniswapV2Pair } from "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Pair.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// 1st-party project imports
import { Constants } from "./Constants.sol";
import { IPoolLiquifier } from "./interfaces/IPoolLiquifier.sol";

contract PoolLiquifier is IPoolLiquifier {
  address private tokenA;
  address private tokenB;

  constructor(address _tokenA, address _tokenB) public {
    tokenA = _tokenA;
    tokenB = _tokenB;
  }

  function fillPool(uint _amountA, uint _amountB, uint expiresIn) override external {
    IUniswapV2Factory sushiFactory = IUniswapV2Factory(Constants.SUSHIV2_FACTORY_ADDRESS);
    IUniswapV2Router02 sushiRouter = IUniswapV2Router02(Constants.SUSHIV2_ROUTER02_ADDRESS);

    // Create a new pair between the two tokens if it doesn't exist
    address tokenPair = sushiFactory.getPair(tokenA, tokenB);
    if (tokenPair == address(0))
      tokenPair = sushiFactory.createPair(tokenA, tokenB);

    // Transfer the amounts of the two tokens to this address
    IERC20(tokenA).transferFrom(msg.sender, address(this), _amountA);
    IERC20(tokenB).transferFrom(msg.sender, address(this), _amountB);

    // Approve SushiSwap to add liquidity with these two tokens
    IERC20(tokenA).approve(Constants.SUSHIV2_ROUTER02_ADDRESS, _amountA);
    IERC20(tokenB).approve(Constants.SUSHIV2_ROUTER02_ADDRESS, _amountB);

    // Add some liquidity to the pair
    (uint amountA, uint amountB, uint liquidityAdded) = sushiRouter.addLiquidity(
      tokenA, tokenB,
      _amountA, _amountB,
      1, 1,
      msg.sender,
      block.timestamp + expiresIn
    );

    uint totalLiquidity = IUniswapV2Pair(tokenPair).totalSupply();

    emit PoolFilled(amountA, amountB, liquidityAdded, totalLiquidity);
  }

  function drainPool(uint expiresIn) override external {
    IUniswapV2Factory sushiFactory = IUniswapV2Factory(Constants.SUSHIV2_FACTORY_ADDRESS);
    IUniswapV2Router02 sushiRouter = IUniswapV2Router02(Constants.SUSHIV2_ROUTER02_ADDRESS);

    address tokenPair = sushiFactory.getPair(tokenA, tokenB);
    uint ownedLiquidity = IERC20(tokenPair).balanceOf(msg.sender);

    // Transfer the amount of the liquidity token to this address
    IERC20(tokenPair).transferFrom(msg.sender, address(this), ownedLiquidity);

    // Approve SushiSwap to remove liquidity with the token pair
    IERC20(tokenPair).approve(Constants.SUSHIV2_ROUTER02_ADDRESS, ownedLiquidity);

    // Add some liquidity to the pair
    (uint amountA, uint amountB) = sushiRouter.removeLiquidity(
      tokenA, tokenB,
      ownedLiquidity,
      1, 1,
      msg.sender,
      block.timestamp + expiresIn
    );

    emit PoolDrained(ownedLiquidity, amountA, amountB);
  }
}
