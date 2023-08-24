// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console.sol";
import "../src/ERC20_.sol";
import "../src/WETH_.sol";
import "../src/Farm.sol";


contract Farm_Test is Test {
    WETH_ public weth;
    ERC20_ public rewardToken;
    Farm public farm;
    
    address internal alice = address(1); 
    address internal bob = address(2); 

    bool aliceSuccess = false;
    bool bobSuccess = false;

    function setUp() public {
        weth = new WETH_();
        rewardToken = new ERC20_("rewardToken", "erc", 100000000000);
        farm = new Farm(address(rewardToken), address(weth));

        vm.startPrank(alice); 
        vm.deal(alice, 10 ether);
        (aliceSuccess, ) = address(weth).call{value: 10 ether}("");
        weth.approve(address(farm), 10 ether);
        vm.stopPrank();        
 
        vm.startPrank(bob); 
        vm.deal(bob, 10 ether);
        (bobSuccess, ) = address(weth).call{value: 10 ether}("");
        weth.approve(address(farm), 10 ether);
        vm.stopPrank();        
 
    }

    function testSetUp() public {
        assertTrue(aliceSuccess);
        assertTrue(bobSuccess);
        assertEq(address(weth).balance, 20 ether);
    }

    function testStake() public {
        vm.startPrank(alice);
        
        vm.expectRevert("Farm: Cannot stake 0");
        farm.stake(0);

        assertEq(farm.getBalanceOf(alice), 0);
        assertEq(farm.getTotalSupply(), 0);
        farm.stake(10 ether);
        assertEq(farm.getBalanceOf(alice), 10 ether);
        assertEq(farm.getTotalSupply(), 10 ether);

        vm.stopPrank();
    }

    function testUnstake() public {
        vm.startPrank(alice);

        vm.expectRevert("Farm: Cannot unstake 0");
        farm.unstake(0);

        farm.stake(10 ether);
        assertEq(farm.getBalanceOf(alice), 10 ether);
        assertEq(farm.getTotalSupply(), 10 ether);
        farm.unstake(10 ether);
        assertEq(farm.getBalanceOf(alice), 0 ether);
        assertEq(farm.getTotalSupply(), 0 ether);
    
        vm.stopPrank();
    }

    function testGetRewardSoloStaker() public {
        vm.startPrank(alice);

        farm.stake(10 ether);
        farm.claimRewards();
        assertEq(rewardToken.balanceOf(alice), 0);
        
        vm.warp(block.timestamp + 24 hours);
        uint expectedRewards = 24 hours * farm.rewardRate();
        farm.claimRewards();
        assertEq(rewardToken.balanceOf(alice), expectedRewards);

        vm.stopPrank();
    }

    function testGetRewardDualStaker() public {
        uint aliceStake = 10 ether;
        uint bobStake = 5 ether;
        
        vm.startPrank(alice);
        farm.stake(aliceStake);
        vm.stopPrank();

        vm.startPrank(bob);
        farm.stake(bobStake);
        vm.stopPrank();

        vm.warp(block.timestamp + 24 hours);
        
        uint aliceExpectedRewards = (24 hours * farm.rewardRate()) * aliceStake / (aliceStake + bobStake);
        uint bobExpectedRewards = 24 hours * farm.rewardRate() * bobStake / (aliceStake + bobStake);

        vm.startPrank(alice);
        farm.claimRewards();
        assertEq(rewardToken.balanceOf(alice), aliceExpectedRewards);
        vm.stopPrank();

        vm.startPrank(bob);
        farm.claimRewards();
        assertEq(rewardToken.balanceOf(bob), bobExpectedRewards);
        vm.stopPrank();
    }

    function testExit() public {
        vm.startPrank(alice);

        farm.stake(10 ether);
        vm.warp(block.timestamp + 24 hours);

        farm.exit();
        assertEq(farm.getBalanceOf(alice), 0 ether);
        assertEq(rewardToken.balanceOf(alice), 24 hours * farm.rewardRate());

        vm.stopPrank();

    }

    // need to add test for reward exceeding total supply
}
