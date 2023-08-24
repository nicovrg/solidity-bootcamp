// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Counter {
    uint256 private counter;

    event Update(uint counter);

    function getCounter() public view returns (uint256) {
        return counter;
    }

    function increment() public {
        counter++;
        emit Update(counter);
    }

    function decrement() external {
        counter--;
        emit Update(counter);
    }
}