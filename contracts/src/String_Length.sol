// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract String_Length {
    
    function strLength(string memory str) public pure returns (uint256) {
        return bytes(str).length;
    }

}
