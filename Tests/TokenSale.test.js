const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("TokenSale Contract", function () {
    let Token;
    let token;
    let TokenSale;
    let tokenSale;
    let owner;
    let addr1;
    let addr2;
    let addrs;

    // Token and TokenSale parameters
    const presaleStartTime = Math.floor(Date.now() / 1000); // current time
    const presaleEndTime = presaleStartTime + 86400; // 1 day later
    const publicSaleStartTime = presaleEndTime + 1;
    const publicSaleEndTime = publicSaleStartTime + 86400; // 1 day after public sale starts
    const presaleCap = ethers.utils.parseEther("1000"); // 1000 ETH
    const publicSaleCap = ethers.utils.parseEther("2000"); // 2000 ETH
    const minimumContribution = ethers.utils.parseEther("0.1"); // 0.1 ETH
    const maximumContribution = ethers.utils.parseEther("10"); // 10 ETH

    beforeEach(async function () {
        Token = await ethers.getContractFactory("Token");
        token = await Token.deploy();
        await token.deployed();

        TokenSale = await ethers.getContractFactory("TokenSale");
        tokenSale = await TokenSale.deploy(token.address, presaleStartTime, presaleEndTime, publicSaleStartTime, publicSaleEndTime, presaleCap, publicSaleCap, minimumContribution, maximumContribution);
        await tokenSale.deployed();

        [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
    });

    //contributed below minimum
    it("should reject contributions below the minimum during presale", async function () {
        await ethers.provider.send("evm_setNextBlockTimestamp", [presaleStartTime]);
        const smallContribution = ethers.utils.parseEther("0.01"); 
        await expect(tokenSale.connect(addr1).buyTokens({ value: smallContribution })).to.be.revertedWith("Contribution out of bounds");
    });
    
    //valid presale constribution
    it("should accept valid contributions during presale", async function () {
        await ethers.provider.send("evm_setNextBlockTimestamp", [presaleStartTime]);
        const validContribution = ethers.utils.parseEther("1"); 
        await expect(tokenSale.connect(addr1).buyTokens({ value: validContribution })).to.emit(tokenSale, "TokensPurchased").withArgs(addr1.address, validContribution);
    });
    
    //contributions after cap
    it("should not accept contributions once the public sale cap is reached", async function () {
        await ethers.provider.send("evm_setNextBlockTimestamp", [publicSaleStartTime]);
        const largeContribution = publicSaleCap;
        await tokenSale.connect(addr1).buyTokens({ value: largeContribution });
        await expect(tokenSale.connect(addr2).buyTokens({ value: minimumContribution })).to.be.revertedWith("Cap exceeded");
    });
    
    //contribution before presale
    it("should not accept contributions before presale starts", async function () {
        const earlyContribution = ethers.utils.parseEther("1");
        await ethers.provider.send("evm_setNextBlockTimestamp", [presaleStartTime - 10]);
        await expect(tokenSale.connect(addr1).buyTokens({ value: earlyContribution })).to.be.revertedWith("Sale not active");
    });
    
    //contribution after presale
    it("should not accept contributions after presale ends", async function () {
        const lateContribution = ethers.utils.parseEther("1");
        await ethers.provider.send("evm_setNextBlockTimestamp", [presaleEndTime + 10]);
        await expect(tokenSale.connect(addr1).buyTokens({ value: lateContribution })).to.be.revertedWith("Sale not active");
    });

    //public sale contribution timing
    it("should accept contributions during public sale", async function () {
        const publicSaleContribution = ethers.utils.parseEther("1");
        await ethers.provider.send("evm_setNextBlockTimestamp", [publicSaleStartTime + 10]);
        await expect(tokenSale.connect(addr1).buyTokens({ value: publicSaleContribution })).to.emit(tokenSale, "TokensPurchased").withArgs(addr1.address, publicSaleContribution);
    });
    
    //token distribution
    it("should distribute tokens immediately upon valid contribution", async function () {
        const contributionAmount = ethers.utils.parseEther("1");
        await ethers.provider.send("evm_setNextBlockTimestamp", [presaleStartTime]);
        await tokenSale.connect(addr1).buyTokens({ value: contributionAmount });
    
        const expectedTokenAmount = contributionAmount.mul(1000); // Assuming 1 ETH = 1000 Tokens
        const actualTokenAmount = await token.balanceOf(addr1.address);
        expect(actualTokenAmount).to.equal(expectedTokenAmount);
    });
    
    //transfering ownership
    it("should allow only the owner to transfer ownership", async function () {
        await expect(tokenSale.connect(addr1).transferOwnership(addr1.address)).to.be.revertedWith("Ownable: caller is not the owner");
        await tokenSale.connect(owner).transferOwnership(addr1.address);
        expect(await tokenSale.owner()).to.equal(addr1.address);
    });

    //refunds
    it("should allow refunds if minimum cap not reached", async function () {
        const contributionAmount = ethers.utils.parseEther("0.5");
        await ethers.provider.send("evm_setNextBlockTimestamp", [presaleStartTime]);
        await tokenSale.connect(addr1).buyTokens({ value: contributionAmount });
    
        await ethers.provider.send("evm_setNextBlockTimestamp", [publicSaleEndTime + 10]);
        await tokenSale.connect(owner).endPublicSale();
    
        const initialBalance = await ethers.provider.getBalance(addr1.address);
        await tokenSale.connect(addr1).claimRefund();
        const finalBalance = await ethers.provider.getBalance(addr1.address);
    
        expect(finalBalance).to.be.above(initialBalance);
    });    
    
});
