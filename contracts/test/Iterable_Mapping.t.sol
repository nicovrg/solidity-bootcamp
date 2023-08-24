// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console.sol";
import "../src/Iterable_Mapping.sol";


contract Iterable_Mapping_Test is Test {
    Iterable_Mapping public iterable;

    uint256 value1 = 10;
    uint256 value2 = 20;
    uint256 value3 = 30;
    
    address addr1 = address(1);
    address addr2 = address(2);
    address addr3 = address(3);

    function setUp() public {
        iterable = new Iterable_Mapping();
        iterable.addToMapping(addr1, value1);
        iterable.addToMapping(addr2, value2);
        iterable.addToMapping(addr3, value3);
    }

    function testAddToMappingWithKey() external {
        assertEq(iterable.getValueFromAddress(addr1), value1);
        assertEq(iterable.getValueFromAddress(addr2), value2);
        assertEq(iterable.getValueFromAddress(addr3), value3);
    }

    function testAddToMappingWithIndex() external {
        assertEq(iterable.getValueFromIndex(0), value1);
        assertEq(iterable.getValueFromIndex(1), value2);
        assertEq(iterable.getValueFromIndex(2), value3);
    }

    function testRemoveFromMappingWithKey() external {
        iterable.removeFromMappingWithKey(addr1);
        assertEq(iterable.getValueFromAddress(addr1), 0);
    }

    function testRemoveFromMappingWithIndex() external {
        iterable.removeFromMappingWithIndex(2);
        assertEq(iterable.getValueFromIndex(2), 0);
    }
    function testRetrieveFromMappingWithKey() external {
        assertEq(iterable.getValueFromAddress(addr2), value2);
    }
    function testRetrieveFromMappingWithIndex() external {
        assertEq(iterable.getValueFromIndex(0), value1);
    }

    function testIterateOnMapping() external {
        for (uint i = 0; i < 3; i++) {
            address addr = iterable.getAddressFromIndex(i);
            iterable.addToMapping(addr, iterable.getValueFromIndex(i) * 2);
        }
        assertEq(iterable.getValueFromIndex(0), value1 * 2);
        assertEq(iterable.getValueFromIndex(1), value2 * 2);
        assertEq(iterable.getValueFromIndex(2), value3 * 2);
    }
}
