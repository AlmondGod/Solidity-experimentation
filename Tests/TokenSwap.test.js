const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("TokenSwap Contract", function () {
    let TokenA, TokenB, tokenA, tokenB, TokenSwap, tokenSwap;
    let owner, user, pool;
    const initialBalance = ethers.utils.parseUnits('1000', 'ether'); // Initial token balance for testing
    const rateTokenAToTokenB = 1; // Example rate: 1 Token A = 1 Token B

    beforeEach(async function () {
        [owner, user, pool] = await ethers.getSigners();

        //Deploy Tokens A and B for testing
        TokenA = await ethers.getContractFactory("TokenA");
        tokenA = await TokenA.deploy();
        await tokenA.deployed();

        TokenB = await ethers.getContractFactory("TokenB");
        tokenB = await TokenB.deploy();
        await tokenB.deployed();

        //Mint a and b
        await tokenA.mint(user.address, initialBalance);
        await tokenB.mint(pool.address, initialBalance);

        // Deploy TokenSwap contract
        TokenSwap = await ethers.getContractFactory("TokenSwap");
        tokenSwap = await TokenSwap.deploy(tokenA.address, tokenB.address, rateTokenAToTokenB);
        await tokenSwap.deployed();

        // Approve TokenSwap to spend user's TokenA and pool's TokenB
        await tokenA.connect(user).approve(tokenSwap.address, initialBalance);
        await tokenB.connect(pool).approve(tokenSwap.address, initialBalance);

        // Transfer TokenB to TokenSwap for liquidity
        await tokenB.connect(pool).transfer(tokenSwap.address, initialBalance);
    });

    //proper A to B swap
    it("should allow a proper A to B swap", async function () {
        const amountToSwap = ethers.utils.parseUnits('10', 'ether');
        await tokenSwap.connect(user).swapTokenAForTokenB(amountToSwap);
    
        expect(await tokenA.balanceOf(user.address)).to.equal(initialBalance.sub(amountToSwap));
        expect(await tokenB.balanceOf(user.address)).to.equal(amountToSwap);
    });

    //proper B to A swap
    it("should allow a proper B to A swap", async function () {
        const amountToSwap = ethers.utils.parseUnits('10', 'ether');

        await tokenB.connect(pool).transfer(user.address, amountToSwap);
        await tokenB.connect(user).approve(tokenSwap.address, amountToSwap);
        await tokenSwap.connect(user).swapTokenBForTokenA(amountToSwap);

        expect(await tokenB.balanceOf(user.address)).to.equal(0);
        expect(await tokenA.balanceOf(user.address)).to.equal(initialBalance.sub(amountToSwap.div(rateTokenAToTokenB)));
    });
    
    //user not enough A for A to B swap
    it("should fail if user doesn't have enough Token A for A to B swap", async function () {
        const amountToSwap = initialBalance.add(1); // More than user's balance
        await expect(tokenSwap.connect(user).swapTokenAForTokenB(amountToSwap)).to.be.revertedWith("Insufficient Token A balance");
    });

    //user not enough B for B to A swap
    it("should fail if user doesn't have enough Token B for B to A swap", async function () {
        const amountToSwap = ethers.utils.parseUnits('1001', 'ether'); // More than user's balance (1000 initially minted to pool)
        await expect(tokenSwap.connect(user).swapTokenBForTokenA(amountToSwap)).to.be.revertedWith("Insufficient Token B balance");
    });

    //contract not enough A for B to A
    it("should fail if pool doesn't have enough Token A for B to A swap", async function () {
        const amountToSwap = initialBalance; // Equal to pool's Token B balance
        await tokenB.connect(pool).transfer(user.address, amountToSwap);
        await tokenB.connect(user).approve(tokenSwap.address, amountToSwap);
    
        // Attempting to swap more Token B than the equivalent Token A available in the pool
        await expect(tokenSwap.connect(user).swapTokenBForTokenA(amountToSwap)).to.be.revertedWith("Insufficient Token A balance in contract");
    });

    //contract not enough B for A to B
    it("should fail if pool doesn't have enough Token B for A to B swap", async function () {
        const amountToSwap = initialBalance.add(1); // More than the Token B balance in the contract
        await expect(tokenSwap.connect(user).swapTokenAForTokenB(amountToSwap)).to.be.revertedWith("Insufficient Token B balance in contract");
    });
    

});
