// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DecentralizedVoting {
    uint public numVoters;
    address public owner;
    uint public endTime;
    uint private endofArray = 0;
    bool public voteEnded = false;
    address public winner;

    address[] public candidates = new address[](1);
    uint candidatesIndex = 0;
    
    address public currentWinner;
    uint public currentHighestVotes = 0;
    address[] public currentWinners = new address[](1);
    uint currentWinnersIndex = 0;

    mapping(address => uint) public voters;
    mapping(address => uint) public voteCounts; //these represent the vote counts plus one

    event Vote(address _voter, address _vote);
    event Registration(address _voter);
    event CandidateAdded(address _candidateName);
    event CandidateWon(address _candidateName, uint votes);
    event MultipleCandidatesWon(address[] _candidateNames, uint votes);


    constructor(uint _endTime) {
        require(_endTime >= block.timestamp, "end time must be in future"); 
        endTime = _endTime;
        owner = msg.sender;
    }

    //register a voter as long as they are not registered
    function registerVoter() public {
        require(voters[msg.sender] == 0, "you cannot reregister yourself");
        emit Registration(msg.sender);
        voters[msg.sender] = 1;
    }

    //all registered voters who have not yet voted can cast votes
    function castVote(address _candidate) public {
        require(voters[msg.sender] != 2, "you already voted!");
        require(voteCounts[_candidate] > 0, "your vote is not a candidate!");
        emit Vote(msg.sender, _candidate);
        voters[msg.sender] = 2;
        voteCounts[_candidate]++;
    }

    //the owner can add voting candidates
    function addCandidates(address _candidate) public {
        require(msg.sender == owner, "only owner can add candidates");
        require(voteCounts[_candidate] == 0, "candidate is already added");
        voteCounts[_candidate] == 1;  
        candidates[candidatesIndex] == _candidate;
        candidatesIndex++;  
    }   
    
    //end the voting time period and emit event showing winner(s)
    function endVote() public {
        require(msg.sender == owner, "only owner can end vote");
        require(block.timestamp > endTime, "can only end after endTime");
        require(!voteEnded, "vote already ended");
        
        for(uint i = 0; i < candidates.length; i++) {
            address currentCandidate = candidates[i];
            if (voteCounts[currentCandidate] > currentHighestVotes) {
                currentWinner = currentCandidate;
                currentHighestVotes = voteCounts[currentCandidate];
                currentWinners = new address[](1);
                currentWinners[0] = currentWinner;
                currentWinnersIndex = 1;
            }

            //multiple winners handling
            if (voteCounts[currentCandidate] == currentHighestVotes) {
                currentWinners[currentWinnersIndex] = currentCandidate;
                currentWinnersIndex++;
            }
        }

        //emit winner(s)
        if (currentWinners.length < 2) {
            winner = currentWinner;
            emit CandidateWon(winner, currentHighestVotes);
        } else {
            emit MultipleCandidatesWon(currentWinners, currentHighestVotes);
        }

        voteEnded = true;
    }

}
