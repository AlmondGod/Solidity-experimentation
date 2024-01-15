// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenSale is ReentrancyGuard, Ownable {
    IERC20 public token;

    uint256 public presaleStartTime;
    uint256 public presaleEndTime;
    uint256 public publicSaleStartTime;
    uint256 public publicSaleEndTime;

    uint256 public presaleCap;
    uint256 public publicSaleCap;

    uint256 public minimumContribution;
    uint256 public maximumContribution;

    uint256 public totalRaised;

    mapping(address => uint256) public contributions;

    enum SalePhase { NotStarted, Presale, PublicSale, Ended }
    SalePhase public currentPhase = SalePhase.NotStarted;

    event TokensPurchased(address indexed purchaser, uint256 etherAmount, uint256 tokenAmount);
    event RefundClaimed(address indexed claimant, uint256 amount);

    constructor(
        address _tokenAddress,
        uint256 _presaleStartTime,
        uint256 _presaleEndTime,
        uint256 _publicSaleStartTime,
        uint256 _publicSaleEndTime,
        uint256 _presaleCap,
        uint256 _publicSaleCap,
        uint256 _minimumContribution,
        uint256 _maximumContribution
    ) {
        require(_tokenAddress != address(0), "Token address cannot be zero");
        require(_presaleEndTime > _presaleStartTime, "Invalid presale time range");
        require(_publicSaleEndTime > _publicSaleStartTime, "Invalid public sale time range");

        token = IERC20(_tokenAddress);
        presaleStartTime = _presaleStartTime;
        presaleEndTime = _presaleEndTime;
        publicSaleStartTime = _publicSaleStartTime;
        publicSaleEndTime = _publicSaleEndTime;
        presaleCap = _presaleCap;
        publicSaleCap = _publicSaleCap;
        minimumContribution = _minimumContribution;
        maximumContribution = _maximumContribution;
    }

    function buyTokens() public payable nonReentrant {
        require(currentPhase != SalePhase.NotStarted && currentPhase != SalePhase.Ended, "Sale not active");
        require(msg.value >= minimumContribution && msg.value <= maximumContribution, "Contribution out of bounds");

        uint256 contribution = msg.value;
        uint256 refund = 0;

        if (currentPhase == SalePhase.Presale) {
            require(block.timestamp >= presaleStartTime && block.timestamp <= presaleEndTime, "Presale not active");
            if (totalRaised + contribution > presaleCap) {
                refund = totalRaised + contribution - presaleCap;
                contribution = presaleCap - totalRaised;
            }
        } else if (currentPhase == SalePhase.PublicSale) {
            require(block.timestamp >= publicSaleStartTime && block.timestamp <= publicSaleEndTime, "Public sale not active");
            if (totalRaised + contribution > publicSaleCap) {
                refund = totalRaised + contribution - publicSaleCap;
                contribution = publicSaleCap - totalRaised;
            }
        }

        totalRaised += contribution;
        contributions[msg.sender] += contribution;

        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }

        uint256 tokenAmount = calculateTokenAmount(contribution);
        token.transfer(msg.sender, tokenAmount);

        emit TokensPurchased(msg.sender, contribution, tokenAmount);
    }

    function calculateTokenAmount(uint256 etherAmount) internal pure returns (uint256) {
        uint256 tokenRate = 1000;
        return etherAmount * tokenRate;
    }

    function claimRefund() public nonReentrant {
        require(currentPhase == SalePhase.Ended, "Sale not ended");
        require(totalRaised < presaleCap || totalRaised < publicSaleCap, "Caps reached, no refunds");

        uint256 amountContributed = contributions[msg.sender];
        require(amountContributed > 0, "No contributions from sender");

        contributions[msg.sender] = 0;
        payable(msg.sender).transfer(amountContributed);

        emit RefundClaimed(msg.sender, amountContributed);
    }

    function startPresale() external onlyOwner {
        require(currentPhase == SalePhase.NotStarted, "Presale already started or completed");
        currentPhase = SalePhase.Presale;
    }

    function endPresale() external onlyOwner {
        require(currentPhase == SalePhase.Presale, "Presale not active");
        currentPhase = SalePhase.PublicSale;
    }

    function startPublicSale() external onlyOwner {
        require(currentPhase == SalePhase.Presale, "Public sale cannot start before presale ends");
        currentPhase = SalePhase.PublicSale;
    }

    function endPublicSale() external onlyOwner {
        require(currentPhase == SalePhase.PublicSale, "Public sale not active");
        currentPhase = SalePhase.Ended;
    }

    function withdrawFunds() external onlyOwner {
        require(address(this).balance > 0, "No funds to withdraw");
        payable(owner()).transfer(address(this).balance);
    }

    function remainingTokens() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function recoverUnsoldTokens() external onlyOwner {
        require(currentPhase == SalePhase.Ended, "Sale not ended");
        token.transfer(owner(), remainingTokens());
    }
}
