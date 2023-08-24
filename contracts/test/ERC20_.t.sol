// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console.sol";
import "../src/ERC20_.sol";


contract ERC20_Test is Test {

    ERC20_ public ercContract;
    
    address internal deployer = address(1);
    address internal alice = address(2);
    address internal bob = address(3);
    address internal carlos = address(4);
    address internal randomContract = address(5);

    string name = "ercToken";
    string symbol = "erc";
    uint8 decimals = 18;

    uint32 totalSupply = 1000;

    uint8 aliceMint = 10;
    uint8 bobMint = 50;
    uint32 supply = 60;

    function setUp() public {
        vm.startPrank(deployer);
        ercContract = new ERC20_(name, symbol, totalSupply);
        ercContract._mint(alice, 10);
        ercContract._mint(bob, 50);
        vm.stopPrank();
    }

    function testContractState() public {
        assertEq(ercContract.name(), name);        
        assertEq(ercContract.symbol(), symbol);        
        assertEq(ercContract.decimals(), decimals);
        assertEq(ercContract.supply(), supply);
        assertEq(ercContract.totalSupply(), totalSupply);
    }

    function testAllowance() public {
        vm.startPrank(alice);

        assertEq(ercContract.allowance(alice, address(ercContract)), 0);
        ercContract.approve(randomContract, 100);
        assertEq(ercContract.allowance(alice, address(randomContract)), 100);

        ercContract.approve(randomContract, 0);
        assertEq(ercContract.allowance(alice, address(randomContract)), 0);

        vm.stopPrank();
    }

    function testBalanceOf() public {
        vm.startPrank(alice);
        assertEq(ercContract.balanceOf(alice), aliceMint);
        vm.stopPrank();
    }

    function testTransfer() public {
        vm.startPrank(alice);
        
        ercContract.transfer(carlos, 5);
        assertEq(ercContract.balanceOf(alice), 5);
        assertEq(ercContract.balanceOf(carlos), 5);
        
        vm.expectRevert("ERC20_: not enough funds");
        ercContract.transfer(carlos, 10);
        
        vm.stopPrank();
    }
    function testTransferFrom() public {
        vm.startPrank(alice);
        ercContract.approve(bob, 5);
        vm.stopPrank();

        vm.startPrank(bob);
        ercContract.transferFrom(alice, carlos, 5);
        assertEq(ercContract.balanceOf(alice), 5);
        assertEq(ercContract.balanceOf(carlos), 5);
        assertEq(ercContract.allowance(alice, address(bob)), 0);


        vm.expectRevert();
        ercContract.transferFrom(alice, carlos, 5);
        vm.stopPrank();
    }

    function testMint() public {
        vm.startPrank(deployer);
        assertEq(ercContract.supply(), supply);

        ercContract._mint(carlos, 100);
        assertEq(ercContract.balanceOf(carlos), 100);
        assertEq(ercContract.supply(), 100 + supply);

        vm.expectRevert("ERC20_: can't mint more than total supply");
        ercContract._mint(carlos, 840);

        vm.stopPrank();
    }

    function testBurn() public {
        vm.startPrank(deployer);
        assertEq(ercContract.supply(), supply);
        
        ercContract._burn(bob, 30);
        assertEq(ercContract.balanceOf(bob), bobMint - 30);
        assertEq(ercContract.supply(), supply - 30);

        vm.expectRevert();
        ercContract._burn(bob, 30);
        
        vm.stopPrank();
    }
}