// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenSwap {
    // ERC20 token interfaces for tokens A and B
    IERC20 public tokenA;
    IERC20 public tokenB;

    // Fixed exchange rate from Token A to Token B
    uint256 public rateTokenAToTokenB; 

    // Event to log the details of a swap operation
    event Swap(address indexed user, address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut);

    // Contract constructor initializes the token contracts and exchange rate
    constructor(address _tokenA, address _tokenB, uint256 _rateTokenAToTokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        rateTokenAToTokenB = _rateTokenAToTokenB;
    }

    // Function to swap Token A for Token B
    function swapTokenAForTokenB(uint256 _amountIn) external {
        uint256 amountOut = _amountIn * rateTokenAToTokenB;

        // Enough Token A, B and approval
        require(tokenA.balanceOf(msg.sender) >= _amountIn, "Insufficient Token A balance");
        require(tokenA.allowance(msg.sender, address(this)) >= _amountIn, "Insufficient allowance for Token A");
        require(tokenB.balanceOf(address(this)) >= amountOut, "Insufficient Token B balance in contract");

        //Transfer
        tokenA.transferFrom(msg.sender, address(this), _amountIn);
        tokenB.transfer(msg.sender, amountOut);
        emit Swap(msg.sender, address(tokenA), address(tokenB), _amountIn, amountOut);
    }

    // Function to swap Token B for Token A
    function swapTokenBForTokenA(uint256 _amountIn) external {
        uint256 amountOut = _amountIn / rateTokenAToTokenB;

        //Check enough A
        require(tokenA.balanceOf(address(this)) >= amountOut, "Insufficient Token A balance in contract");

        // Transfer
        tokenB.transferFrom(msg.sender, address(this), _amountIn);
        tokenA.transfer(msg.sender, amountOut);
        emit Swap(msg.sender, address(tokenB), address(tokenA), _amountIn, amountOut);
    }
}
