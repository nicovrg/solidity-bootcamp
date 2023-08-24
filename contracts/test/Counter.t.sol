// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console.sol";
import "../src/Counter.sol";


contract CounterTest is Test {
    Counter public counterContract;

    function setUp() public {
        counterContract = new Counter();
    }

    function testIncrement() public {
        counterContract.increment();
        assertEq(counterContract.getCounter(), 1);
    }

    function testDecrement() public {
        counterContract.increment();
        counterContract.decrement();
        assertEq(counterContract.getCounter(), 0);
        counterContract.increment();
        counterContract.increment();
        counterContract.decrement();
        assertEq(counterContract.getCounter(), 1);
    }
}
