// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../TokenA.sol";
import "../TokenB.sol";
import "../TokenSwap.sol";

contract TokenSwapTest is Test {
    TokenA tokenA;
    TokenB tokenB;
    TokenSwap tokenSwap;

    address user = address(1);
    address pool = address(2);

    function setUp() public {
        tokenA = new TokenA();
        tokenB = new TokenB();

        tokenA.mint(user, 1000 ether);
        tokenB.mint(pool, 1000 ether);

        tokenSwap = new TokenSwap(address(tokenA), address(tokenB), 1 ether);

        vm.startPrank(user);
        tokenA.approve(address(tokenSwap), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(pool);
        tokenB.approve(address(tokenSwap), type(uint256).max);
        tokenB.transfer(address(tokenSwap), 1000 ether);
        vm.stopPrank();
    }

    function testProperAToBSwap() public {
    vm.startPrank(user);
    tokenSwap.swapTokenAForTokenB(10 ether);
    assertEq(tokenA.balanceOf(user), 990 ether);
    assertEq(tokenB.balanceOf(user), 10 ether);
    vm.stopPrank();
    }

    function testProperBToASwap() public {
    vm.startPrank(pool);
    tokenB.transfer(user, 10 ether);
    vm.stopPrank();

    vm.startPrank(user);
    tokenSwap.swapTokenBForTokenA(10 ether);
    assertEq(tokenB.balanceOf(user), 0 ether);
    assertEq(tokenA.balanceOf(user), 1000 ether); // Assuming 1:1 swap rate
    vm.stopPrank();
    }

    function testFailNotEnoughTokenA() public {
        vm.startPrank(user);
        tokenSwap.swapTokenAForTokenB(1001 ether); // User only has 1000 ether
        vm.stopPrank();
    }

    function testFailNotEnoughTokenB() public {
        vm.startPrank(user);
        tokenSwap.swapTokenBForTokenA(1001 ether); // User has 0 ether of token B
        vm.stopPrank();
    }

    function testFailPoolNotEnoughTokenA() public {
        vm.startPrank(user);
        tokenSwap.swapTokenBForTokenA(1001 ether); // Pool has 1000 ether of token A
        vm.stopPrank();
    }

    function testFailPoolNotEnoughTokenB() public {
    vm.startPrank(user);
    tokenA.transfer(address(tokenSwap), 1000 ether); // User deposits 1000 ether of Token A
    tokenSwap.swapTokenAForTokenB(1001 ether); // Attempting to swap more than the pool's balance of Token B
    vm.stopPrank();
    }


}
