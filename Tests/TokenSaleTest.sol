// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/TokenSale.sol";
import "../src/MockERC20.sol";

contract TokenSaleTest is Test {
    TokenSale tokenSale;
    MockERC20 token;
    address user = address(1);

    uint256 presaleStartTime;
    uint256 presaleEndTime;
    uint256 publicSaleStartTime;
    uint256 publicSaleEndTime;
    uint256 presaleCap;
    uint256 publicSaleCap;
    uint256 minimumContribution;
    uint256 maximumContribution;

    function setUp() public {
        presaleStartTime = block.timestamp;
        presaleEndTime = presaleStartTime + 1 days;
        publicSaleStartTime = presaleEndTime;
        publicSaleEndTime = publicSaleStartTime + 1 days;
        presaleCap = 100 ether;
        publicSaleCap = 200 ether;
        minimumContribution = 0.1 ether;
        maximumContribution = 10 ether;

        token = new MockERC20("MockToken", "MKT", 18);
        tokenSale = new TokenSale(
            address(token),
            presaleStartTime,
            presaleEndTime,
            publicSaleStartTime,
            publicSaleEndTime,
            presaleCap,
            publicSaleCap,
            minimumContribution,
            maximumContribution
        );

        token.transfer(address(tokenSale), token.totalSupply() / 2);
    }

    function testSuccessfulPresaleContribution() public {
    vm.warp(presaleStartTime + 1); // Warp to presale period
    vm.startPrank(user);
    tokenSale.buyTokens{value: 1 ether}();
    assertEq(token.balanceOf(user), 1000 ether); // Assuming rate is 100

    }

    function testFailContributionBeforePresale() public {
    vm.startPrank(user);
    vm.expectRevert("Sale not active");
    tokenSale.buyTokens{value: 1 ether}();
    vm.stopPrank();
    }

    function testFailBelowMinimumContribution() public {
    vm.warp(presaleStartTime + 1); // Warp to presale period
    vm.startPrank(user);
    vm.expectRevert("Contribution out of bounds");
    tokenSale.buyTokens{value: 0.05 ether}(); // Less than the minimum contribution
    vm.stopPrank();
    }

    function testFailAboveMaximumContribution() public {
    vm.warp(presaleStartTime + 1); // Warp to presale period
    vm.startPrank(user);
    vm.expectRevert("Contribution out of bounds");
    tokenSale.buyTokens{value: 15 ether}(); // More than the maximum contribution
    vm.stopPrank();
    }

    function testRefundWhenCapExceeded() public {
    vm.warp(presaleStartTime + 1); // Warp to presale period
    vm.deal(address(tokenSale), presaleCap); // Fund the contract to the presale cap
    vm.startPrank(user);
    uint256 initialBalance = user.balance;
    uint256 overContribution = 5 ether;
    tokenSale.buyTokens{value: overContribution}();
    uint256 refundedAmount = user.balance - initialBalance;
    assertEq(refundedAmount, overContribution - maximumContribution); // Should refund the amount that exceeded the cap
    vm.stopPrank();
    }

    function testSuccessfulPublicSaleContribution() public {
    vm.warp(publicSaleStartTime + 1); // Warp to public sale period
    vm.startPrank(user);
    tokenSale.buyTokens{value: 2 ether}();
    assertEq(token.balanceOf(user), 2000 ether); // Assuming rate is 1000 tokens per ETH
    vm.stopPrank();
    }

}