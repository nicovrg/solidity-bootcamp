// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";
import "../src/WETH_.sol";

contract WETHTest is Test {
    WETH_ public weth;

    address alice = address(1);
    address bob = address(2);
    address carlos = address(3);

    uint depositAmount = 1 ether;
    uint initialBalance = 10 ether;

    event Deposit(address indexed from, uint amount);
    event Withdraw(address indexed to, uint amount);

    function setUp() public {
        weth = new WETH_();
        vm.deal(alice, initialBalance);
        vm.deal(bob, initialBalance);
        
        vm.startPrank(bob);
        (bool success, ) = address(weth).call{value: depositAmount}("");
        assertTrue(success);
        vm.stopPrank();
    }

    function testReceive() public {
        vm.startPrank(alice);

        vm.expectEmit(true, false, false, true);
        emit Deposit(alice, depositAmount);

        (bool success, ) = address(weth).call{value: depositAmount}("");
        assertTrue(success);

        assertEq(address(weth).balance, depositAmount * 2);
        assertEq(weth.totalSupply(), depositAmount * 2);
        assertEq(weth.balanceOf(alice), depositAmount);
        assertEq(alice.balance, initialBalance - depositAmount);
        vm.stopPrank();
    }

    function testWithdraw() public {
        vm.startPrank(alice);

        (bool success, ) = address(weth).call{value: depositAmount}("");
        require(success);

        emit log_named_uint("Balance alice", weth.balanceOf(alice));

        vm.expectEmit(true, false, false, true);
        emit Withdraw(alice, depositAmount);

        weth.withdraw(depositAmount);

        vm.expectRevert("WETH: not enough fund to withdraw");
        weth.withdraw(depositAmount);

        assertEq(address(weth).balance, 1 ether);
        assertEq(weth.totalSupply(), 1 ether);
        assertEq(weth.balanceOf(alice), 0);
        assertEq(alice.balance, initialBalance);
        vm.stopPrank();
    }

    function testApprove() public {
        vm.startPrank(bob);
        weth.approve(alice, 0.5 ether);
        assertEq(weth.allowance(bob, alice), 0.5 ether);
        vm.stopPrank();
    }

    function testTransfer() public {
        vm.startPrank(bob);
        weth.transfer(alice, 0.5 ether);
        weth.transfer(alice, 0.5 ether);
        assertEq(weth.balanceOf(alice), 1 ether);
        vm.expectRevert("WETH: Not enough funds");
        weth.transfer(alice, 0.5 ether);
        vm.stopPrank();
    }

    function testTransferFrom() public {
        vm.startPrank(bob);
        weth.approve(alice, 1 ether);
        vm.stopPrank();

        vm.startPrank(alice);
        weth.transferFrom(bob, carlos, 0.5 ether);
        weth.transferFrom(bob, carlos, 0.5 ether);

        vm.expectRevert("WETH: Not enough funds");
        weth.transferFrom(bob, carlos, 0.5 ether);

        vm.expectRevert("WETH: Not allowed to transfer this amount");
        weth.transferFrom(carlos, bob, 0.5 ether);

        assertEq(weth.balanceOf(alice), 0);
        assertEq(weth.balanceOf(carlos), 1 ether);

        vm.stopPrank();
    }
}
