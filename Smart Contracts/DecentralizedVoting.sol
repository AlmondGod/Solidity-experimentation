// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DecentralizedVoting is Ownable {
    uint public numVoters;
    uint public endTime;
    bool public voteEnded = false;
    address public winner;

    // Using dynamic array instead of fixed-size array
    address[] public candidates;

    // Keeping track of the current winner and highest votes
    address public currentWinner;
    uint public currentHighestVotes = 0;

    mapping(address => uint) public voters;
    mapping(address => uint) public voteCounts; // Representing the vote counts

    event Vote(address indexed voter, address indexed vote);
    event Registration(address indexed voter);
    event CandidateAdded(address indexed candidateName);
    event CandidateWon(address indexed candidateName, uint votes);
    event MultipleCandidatesWon(address[] candidateNames, uint votes);

    constructor(uint _endTime) Ownable() {
        require(_endTime >= block.timestamp, "End time must be in future");
        endTime = _endTime;
    }

    function registerVoter() public {
        require(voters[msg.sender] == 0, "Cannot re-register");
        emit Registration(msg.sender);
        voters[msg.sender] = 1;
        numVoters++;
    }

    function castVote(address _candidate) public {
        require(voters[msg.sender] == 1, "Not registered or already voted");
        require(voteCounts[_candidate] > 0, "Not a valid candidate");
        emit Vote(msg.sender, _candidate);
        voters[msg.sender] = 2; // Mark as voted
        voteCounts[_candidate]++;

        // Update current winner and highest votes
        if (voteCounts[_candidate] > currentHighestVotes) {
            currentWinner = _candidate;
            currentHighestVotes = voteCounts[_candidate];
            winner = currentWinner; // Set the winner if single highest
        } else if (voteCounts[_candidate] == currentHighestVotes) {
            winner = address(0); // Clear winner in case of a tie
        }
    }

    function addCandidates(address _candidate) public onlyOwner {
        require(voteCounts[_candidate] == 0, "Candidate already added");
        voteCounts[_candidate] = 1; // Initialize vote count
        candidates.push(_candidate);
        emit CandidateAdded(_candidate);
    }

    function endVote() public onlyOwner {
        require(block.timestamp > endTime, "Voting period not yet ended");
        require(!voteEnded, "Vote already ended");
        voteEnded = true;
        // Winner is already set in castVote, no need to iterate
        if (winner == address(0)) {
            emit MultipleCandidatesWon(candidates, currentHighestVotes);
        } else {
            emit CandidateWon(winner, currentHighestVotes);
        }
    }
}
