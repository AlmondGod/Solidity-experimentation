
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenSwap {
    IERC20 public tokenA;
    IERC20 public tokenB;
    uint256 public rateTokenAToTokenB; // Token B number per one Token A

    event Swap(address indexed user, address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut);

    constructor(address _tokenA, address _tokenB, uint256 _rateTokenAToTokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        rateTokenAToTokenB = _rateTokenAToTokenB;
    }

    function swapTokenAForTokenB(uint256 _amountIn) external {
        uint256 amountOut = _amountIn * rateTokenAToTokenB;

        require(tokenA.balanceOf(msg.sender) >= _amountIn, "Insufficient Token A balance");
        require(tokenA.allowance(msg.sender, address(this)) >= _amountIn, "Insufficient allowance for Token A");
        require(tokenB.balanceOf(address(this)) >= amountOut, "Insufficient Token B balance in contract");

        tokenA.transferFrom(msg.sender, address(this), _amountIn);
        tokenB.transfer(msg.sender, amountOut);

        emit Swap(msg.sender, address(tokenA), address(tokenB), _amountIn, amountOut);
    }

    function swapTokenBForTokenA(uint256 _amountIn) external {
        uint256 amountOut = _amountIn / rateTokenAToTokenB;

        require(tokenB.balanceOf(msg.sender) >= _amountIn, "Insufficient Token B balance");
        require(tokenB.allowance(msg.sender, address(this)) >= _amountIn, "Insufficient allowance for Token B");
        require(tokenA.balanceOf(address(this)) >= amountOut, "Insufficient Token A balance in contract");

        tokenB.transferFrom(msg.sender, address(this), _amountIn);
        tokenA.transfer(msg.sender, amountOut);

        emit Swap(msg.sender, address(tokenB), address(tokenA), _amountIn, amountOut);
    }
}
