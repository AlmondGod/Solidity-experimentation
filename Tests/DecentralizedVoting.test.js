const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("DecentralizedVoting Contract", function () {
    let DecentralizedVoting;
    let voting;
    let owner;
    let voter1;
    let voter2;
    let candidate1;
    let candidate2;

    beforeEach(async function () {
        DecentralizedVoting = await ethers.getContractFactory("DecentralizedVoting");
        [owner, voter1, voter2, candidate1, candidate2] = await ethers.getSigners();
        voting = await DecentralizedVoting.deploy(ethers.utils.parseUnits('1000', 'wei'));
        await voting.deployed();
    });

    //voter registration
    it("should allow a new voter to register", async function () {
        await voting.connect(voter1).registerVoter();
        const voterStatus = await voting.voters(voter1.address);
        expect(voterStatus).to.equal(1);
    });

    //candidate addition
    it("should allow the owner to add a new candidate", async function () {
        await voting.connect(owner).addCandidates(candidate1.address);
        const candidateVoteCount = await voting.voteCounts(candidate1.address);
        expect(candidateVoteCount).to.equal(1);
    });

    //cast vote
    it("should allow a registered voter to cast a vote", async function () {
        await voting.connect(owner).addCandidates(candidate1.address);
        await voting.connect(voter1).registerVoter();
        await voting.connect(voter1).castVote(candidate1.address);
        const voteCount = await voting.voteCounts(candidate1.address);
        expect(voteCount).to.equal(2); // 1 for candidate addition, 1 for vote
    });

    //ending vote
    it("should allow the owner to end the vote", async function () {
        // Fast forward time to ensure endTime has passed
        await ethers.provider.send("evm_increaseTime", [1001]); // increase time by 1001 seconds
        await ethers.provider.send("evm_mine"); // mine the next block
    
        await voting.connect(owner).endVote();
        const voteEndedStatus = await voting.voteEnded();
        expect(voteEndedStatus).to.be.true;
    });
    
    //non owner trying to add candidates
    it("should not allow a non-owner to register a candidate", async function () {
        await expect(voting.connect(voter1).addCandidates(candidate1.address)).to.be.revertedWith("only owner can add candidates");
    });
    
    //voter registering already registered
    it("should not allow an already registered voter to register again", async function () {
        await voting.connect(voter1).registerVoter();
        await expect(voting.connect(voter1).registerVoter()).to.be.revertedWith("you cannot reregister yourself");
    });

    //voter who voted tries to revote
    it("should not allow a voter who has already voted to vote again", async function () {
        await voting.connect(owner).addCandidates(candidate1.address);
        await voting.connect(voter1).registerVoter();
        await voting.connect(voter1).castVote(candidate1.address);
        await expect(voting.connect(voter1).castVote(candidate1.address)).to.be.revertedWith("you already voted!");
    });

    //owner tries to end before end time
    it("should not allow the vote to end before the end time", async function () {
        await expect(voting.connect(owner).endVote()).to.be.revertedWith("can only end after endTime");
    });

    //multiple winners tied
    it("should handle multiple winners with a tie", async function () {
        await voting.connect(owner).addCandidates(candidate1.address);
        await voting.connect(owner).addCandidates(candidate2.address);
    
        await voting.connect(voter1).registerVoter();
        await voting.connect(voter2).registerVoter();
    
        await voting.connect(voter1).castVote(candidate1.address);
        await voting.connect(voter2).castVote(candidate2.address);
    
        await ethers.provider.send("evm_increaseTime", [1001]);
        await ethers.provider.send("evm_mine");
    
        await voting.connect(owner).endVote();
    
        expect(await voting.currentHighestVotes()).to.equal(2);
        expect(await voting.currentWinners(0)).to.equal(candidate1.address);
        expect(await voting.currentWinners(1)).to.equal(candidate2.address);
    });

    //candidate with most votes wins
    it("should ensure the candidate with the most votes wins", async function () {
        await voting.connect(owner).addCandidates(candidate1.address);
        await voting.connect(owner).addCandidates(candidate2.address);
    
        await voting.connect(voter1).registerVoter();
        await voting.connect(voter2).registerVoter();
    
        await voting.connect(voter1).castVote(candidate1.address);
        await voting.connect(voter2).castVote(candidate1.address); 
        
        await ethers.provider.send("evm_increaseTime", [1001]);
        await ethers.provider.send("evm_mine");
    
        await voting.connect(owner).endVote();
    
        expect(await voting.winner()).to.equal(candidate1.address);
    });
    
});