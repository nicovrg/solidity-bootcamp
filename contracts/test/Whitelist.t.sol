// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console.sol";
import "../src/Whitelist.sol";


contract Whitelist_Test is Test {
    Whitelist public whitelist;

    uint32 max = 2;
    address addr_0 = address(1);
    address addr_1 = address(2);
    address addr_2 = address(3);

    function setUp() public {
        whitelist = new Whitelist(max);
    }

    function testCheckMaxSize() public {
        assertEq(whitelist.getWhitelistMax(), max);
    }

    function testAddToWhitelist() public {
        vm.startPrank(addr_0);
        assertEq(whitelist.isAddressWhitelisted(addr_0), false);
        whitelist.addToWhitelist();
        assertEq(whitelist.isAddressWhitelisted(addr_0), true);
        vm.expectRevert("address already in the whitelist");
        whitelist.addToWhitelist();
        vm.stopPrank();
        
        vm.startPrank(addr_1);
        whitelist.addToWhitelist();
        vm.stopPrank();

        vm.startPrank(addr_2);
        vm.expectRevert("whitelist is full");
        whitelist.addToWhitelist();
        vm.stopPrank();

        address[] memory array = new address[](2);
        array[0] = addr_0;
        array[1] = addr_1;
        assertEq(whitelist.getWhitelistArray(), array);
    }
}

// syntax for storage array
// address[] storage array = new address[];
// address[2] array = [address(1), address(2)];

// syntax for memory array
// address[] memory array = new address[](2);
// array[x] = y;