// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "../DecentralizedVoting.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DecentralizedVotingTest is DSTest {
    DecentralizedVoting public voting;
    address[] candidateAddresses;

    function setUp() public {
        candidateAddresses = new address[](2);
        candidateAddresses[0] = address(1); // Mock candidate address
        candidateAddresses[1] = address(2); // Mock candidate address
        voting = new DecentralizedVoting(block.timestamp + 1 days); // Set the end time to 1 day from now
    }

    function testVoterRegistration() public {
        voting.registerVoter();
        assertEq(voting.voters(address(this)), 1, "Voter registration failed");
    }

    function testAddCandidate() public {
        voting.addCandidates(candidateAddresses[0]);
        assertEq(voting.voteCounts(candidateAddresses[0]), 1, "Candidate addition failed");
    }

    function testVoteCasting() public {
        voting.registerVoter();
        voting.addCandidates(candidateAddresses[0]);
        voting.castVote(candidateAddresses[0]);
        assertEq(voting.voteCounts(candidateAddresses[0]), 2, "Vote casting failed");
    }

    function testEndVoteSingleWinner() public {
        voting.registerVoter();
        voting.addCandidates(candidateAddresses[0]);
        voting.addCandidates(candidateAddresses[1]);
        voting.castVote(candidateAddresses[0]);
        voting.castVote(candidateAddresses[0]);

        // Fast forward time to end the voting period
        vm.warp(block.timestamp + 2 days);

        voting.endVote();
        assertEq(voting.winner(), candidateAddresses[0], "Wrong winner declared");
    }

    function testEndVoteMultipleWinners() public {
        voting.registerVoter();
        voting.addCandidates(candidateAddresses[0]);
        voting.addCandidates(candidateAddresses[1]);
        voting.castVote(candidateAddresses[0]);
        voting.castVote(candidateAddresses[1]);

        // Fast forward time to end the voting period
        vm.warp(block.timestamp + 2 days);

        voting.endVote();
        assertEq(voting.currentWinners(0), candidateAddresses[0], "First winner incorrect");
        assertEq(voting.currentWinners(1), candidateAddresses[1], "Second winner incorrect");
    }
}
