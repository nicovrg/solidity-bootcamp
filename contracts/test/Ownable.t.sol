// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console.sol";
import "../src/Ownable.sol";

contract MockOwnable is Ownable {
    /* 
        An abstract contract cannot be instantiated on its own.
        It typically contains one or more functions that are declared without implementation details. 
        It serves as a blueprint or interface for other contracts to inherit from. 
        To test an abstract contract we first need to inherit it with a non abstract contract.
    */
}


contract OwnableTest is Test {
    MockOwnable public ownableContract;
    
    address owner1 = address(1);
    address owner2 = address(2);
    address owner3 = address(3);

    function setUp() public {
        vm.startPrank(owner1);
        ownableContract = new MockOwnable();
        vm.stopPrank();
    }

    function testInitialOwner() public {
        assertEq(ownableContract.owner(), owner1);
    }

    function testTransferOwnership() public {
        vm.startPrank(owner2);
        vm.expectRevert("Ownable: only owner can call this function");
        ownableContract.transferOwnership(owner2);
        vm.stopPrank();

        vm.startPrank(owner1);
        vm.expectRevert("Ownable: address cannot be zero");
        ownableContract.transferOwnership(address(0));
        
        ownableContract.transferOwnership(owner2);
        assertEq(ownableContract.owner(), owner2);
        vm.stopPrank();
    }
}
