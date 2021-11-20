// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./nftFund.sol";


contract Factory{
     erc20Fund[] public funds;
     uint disabledCount;

     event FundCreated(address fundAddress, string name);

     function createFund(string memory name, string memory symbol, uint tokenPrice) external{
       erc20Fund fund = new erc20Fund(name, symbol, tokenPrice);
       funds.push(fund);
       emit FundCreated(address(fund), name);
     }

     function getFunds() external view returns(erc20Fund[] memory){
    //   _funds = new erc20Fund[](funds.length- disabledCount);
    //   uint count;
    //   for(uint i=0;i<funds.length; i++){
    //       if(funds[i].isEnabled()){
    //          _funds[count] = funds[i];
    //          count++;
    //       }
    //     }
        return funds;
     }  
 
}