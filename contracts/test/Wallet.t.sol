// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console.sol";
import "../src/Wallet.sol";


contract Wallet_Test is Test {
    Wallet public wallet;
    address owner = address(10);
    address alice = address(1);
    address bob = address(2);

    function setUp() public {
        startHoax(owner, 1 ether);
        wallet = (new Wallet){value: 1 ether}();
        vm.deal(alice, 2 ether);
        vm.stopPrank();
    }

    function testDeploymentWithOwner() public {
        assertEq(wallet.getOwner(), owner);
    }

    function testReceive() public {
        vm.startPrank(alice);

        (bool success, ) = address(wallet).call{value: 1 ether}(abi.encodeWithSignature("receivedFunds()"));
        require(success, "Transaction failed");
        assertEq(address(wallet).balance, 2 ether);
        assertEq(wallet.getBalance(), 2 ether);
        
        vm.stopPrank();
    }

    function testTransferFunds() public {
        vm.startPrank(owner);

        wallet.transferToAddress(1 ether, payable(bob));
        assertEq(address(wallet).balance, 0 ether);
        assertEq(wallet.getBalance(), 0 ether);
        assertEq(address(bob).balance, 1 ether);

        vm.expectRevert("Wallet: not enough funds to transfer");
        wallet.transferToAddress(1 ether, payable(bob));

        vm.stopPrank();
    }

    function testTransferOwnership() public {
        vm.startPrank(owner);
        wallet.transferOwnership(alice);
        vm.stopPrank();

        vm.startPrank(alice);
        wallet.transferToAddress(1 ether, payable(bob));
        assertEq(address(wallet).balance, 0 ether);
        assertEq(wallet.getBalance(), 0 ether);
        assertEq(address(bob).balance, 1 ether);
    
        vm.stopPrank();
    }

    function testWithdrawToAddress() public {
        vm.startPrank(alice);
        vm.expectRevert("Ownable: only owner can call this function");
        wallet.withdrawToAddress(1 ether, payable(alice));
        vm.stopPrank();

        vm.startPrank(owner);
        wallet.withdrawToAddress(1 ether, payable(bob));

        assertEq(address(wallet).balance, 0 ether);
        assertEq(wallet.getBalance(), 0 ether);
        assertEq(address(bob).balance, 1 ether);

        vm.stopPrank();
    }
}


