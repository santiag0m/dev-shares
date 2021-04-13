//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

import "hardhat/console.sol";

contract DevShares {
    address founder;
    uint16 totalShares;
    uint16 totalDevShares;
    uint16 votingRound;

    mapping(address => uint16) shares;
    mapping(address => bool) regDev;
    mapping(address => bool) dependency;

    mapping(address => uint16) assignedRound;
    mapping(address => uint16) votesRegFavor;
    mapping(address => uint16) votesRegAgainst;
    mapping(bytes32 => bool) hasVoted;

    event Sent(address from, address to, uint256 amount);

    constructor(uint16 _totalShares) {
        // Assign all shares to the founder
        founder = msg.sender;
        totalShares = _totalShares;
        shares[founder] += totalShares;
        // Register the founder as developer
        totalDevShares = totalShares;
        regDev[founder] = true;
        // Initialize voting round to be non-zero
        votingRound = 1;
    }

    function transferDevShares(address receiver, uint16 amount) public {
        require(amount <= shares[msg.sender], "Insufficient shares.");
        require(regDev[receiver], "Receiver is not a registered developer.");
        shares[msg.sender] -= amount;
        shares[receiver] += amount;
        emit Sent(msg.sender, receiver, amount);
    }

    function registerDevVote(address candidate, bool voteFavor) public {
        require(regDev[msg.sender], "Only registered devs can vote.");
        require(regDev[candidate] == false, "Candidate is already registered.");

        if (assignedRound[candidate] == 0) {
            assignedRound[candidate] = votingRound;
            votingRound += 1;
        }

        bytes32 voterHash;
        voterHash = keccak256(abi.encode(msg.sender, assignedRound[candidate]));

        require(hasVoted[voterHash] == false, "Sender has already voted.");

        if (voteFavor) {
            votesRegFavor[candidate] += shares[msg.sender];
            if (votesRegFavor[candidate] > ((totalDevShares / 2) + 1)) {
                regDev[candidate] = true;
                votesRegFavor[candidate] = 0;
                votesRegAgainst[candidate] = 0;
            }
        } else {
            votesRegAgainst[candidate] += shares[msg.sender];
            if (votesRegAgainst[candidate] > ((totalDevShares / 2) + 1)) {
                votesRegFavor[candidate] = 0;
                votesRegAgainst[candidate] = 0;
            }
        }

        hasVoted[voterHash] = true;
    }
}
