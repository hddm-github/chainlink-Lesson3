//SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.20;

contract Parent {
    uint256 public a;

    function addOne() public {
        a++;
    }
}

contract Child is Parent{

    function addTwo() public {
        a += 2;
    }
}


// ERC20: Fungible Token
// ERC721: NFT - Non-Fungible Token