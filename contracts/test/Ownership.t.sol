// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console2.sol";
import "../src/Ownership.sol";

contract Ownership_Test is Test {
    Ownership internal _contract;
    address internal owner = address(1);

    function setUp() public {
        _contract = new Ownership(owner);
    }

    function testChangeName() public {
        vm.startPrank(owner);
        _contract.changeName("contract");
        assertEq(_contract.getName(), "contract");
        vm.stopPrank();
    }

    function testOwnership() public {
        assertEq(_contract.owner(), owner);
        
        vm.startPrank(owner);
        
        address newOwner = address(2);
        _contract.transferOwnership(newOwner);
        assertEq(_contract.owner(), newOwner);

        assertEq(_contract.historicalOwner(0), owner);

        vm.stopPrank();
    }
}
