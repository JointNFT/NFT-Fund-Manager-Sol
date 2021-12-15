// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./nftFund.sol";


contract Factory {
     erc20Fund[] public funds;
     uint disabledCount;

     event FundCreated(address fundAddress, string name, string symbol, uint tokenPrice, address owner, string fundImgUrl);

     function createFund(string memory name, string memory symbol, uint tokenPrice, string memory fundImgUrl) payable external returns(address) {
        erc20Fund fund = (new erc20Fund){value: msg.value}(name, symbol, tokenPrice, msg.sender, fundImgUrl);
        funds.push(fund);
        emit FundCreated(address(fund), name, symbol, tokenPrice, msg.sender, fundImgUrl);
        return address(fund);
     }

     function getFunds() external view returns(erc20Fund[] memory){
        return funds;
     }

     function getNoOfFundsCreated() external view returns(uint) {
        return funds.length;
     }

     function deleteFund(uint index) external {
        require(index < funds.length, "Invalid input");
        funds[index] = funds[funds.length - 1];
        funds.pop();
     }
}