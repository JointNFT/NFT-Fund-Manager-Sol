// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./nftFund.sol";
import "./erc20.sol";


contract jointNFTVote {
    string public desc;
    uint private yesVotes;
    uint private noVotes;
    mapping(address => uint) private yesVotesCasted;
    mapping(address => uint) private noVotesCasted;

    erc20Fund associatedFund;

    event VotesCasted(bool isYes, uint amount);

    constructor(address fundAddress, string memory desc_){
        associatedFund = erc20Fund(fundAddress);
        desc = desc_;
    }

    function getAssociatedFund() public view returns(address) {
        return address(associatedFund);
    }

    function getTotalYesVotes() public view returns(uint) {
        return yesVotes;
    }

    function getTotalNoVotes() public view returns(uint) {
        return noVotes;
    }
    
    function getYesVotesByUser() public view returns(uint) {
        return yesVotesCasted[msg.sender];
    }

    function getNoVotesByUser() public view returns(uint) {
        return noVotesCasted[msg.sender];
    }

    function totalVotesPossible() public view returns(uint) {
        return associatedFund.balanceOf(msg.sender);
    }

    function vote(bool isYes, uint amount) public virtual {
        uint totalVotesPossible = associatedFund.balanceOf(msg.sender);
        uint votedYes = yesVotesCasted[msg.sender];
        uint votedNo = noVotesCasted[msg.sender];

        require((totalVotesPossible) >= (votedYes + votedNo + amount), "You dont own enough tokens to vote that much");

        if(isYes) {
            yesVotesCasted[msg.sender] += amount;
            yesVotes += amount;
        } else {
            noVotesCasted[msg.sender] += amount;
            noVotes += amount;
        }

        emit VotesCasted(isYes, amount);

    }

    function resetVotes() public virtual {
        yesVotesCasted[msg.sender] = 0;
        noVotesCasted[msg.sender] = 0;
    }

}