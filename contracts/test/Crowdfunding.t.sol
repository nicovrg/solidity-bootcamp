// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console.sol";
import "../src/Crowdfunding.sol";


contract CrowdfundingTest is Test {
    Crowdfunding public crowdfund;

    address addr_1 = address(1);
    address addr_2 = address(2);

    uint camp1 = 0;
    uint camp2 = 0;

    enum TYPE {
        STARTUP,
        CHARITY
    }

    enum STATE {
        ACTIVE,
        NOT_FUNDED,
        PARTIALLY_FUNDED,
        FULLY_FUNDED
    }

    function setUp() public {
        vm.startPrank(addr_1);
        crowdfund = new Crowdfunding();
        camp1 = crowdfund.createCampaign("campaign1", 2 ether, 10 days, false, true);
        vm.stopPrank();
        vm.startPrank(addr_2);
        camp2 = crowdfund.createCampaign("campaign2", 20 ether, 30 days, true, false);
        vm.stopPrank();
    }

    function testCreateCampaign() public {
        assertEq(crowdfund.getCampaign(camp1).id, camp1);
        assertEq(crowdfund.getCampaign(camp1).name, "campaign1");
        assertEq(crowdfund.getCampaign(camp1).owner, addr_1);
        assertEq(crowdfund.getCampaign(camp1).goal, 2 ether);
        assertEq(crowdfund.getCampaign(camp1).fund, 0);
        assertEq(crowdfund.getCampaign(camp1).start, 1);
        assertEq(crowdfund.getCampaign(camp1).end, 1 + 10 days);
        assertEq(uint256(crowdfund.getCampaign(camp1).state), uint256(STATE.ACTIVE));
        assertEq(uint256(crowdfund.getCampaign(camp1).campain_type), uint256(TYPE.CHARITY));

        assertEq(crowdfund.getCampaign(camp2).id, camp2);
        assertEq(crowdfund.getCampaign(camp2).name, "campaign2");
        assertEq(crowdfund.getCampaign(camp2).owner, addr_2);
        assertEq(crowdfund.getCampaign(camp2).goal, 20 ether);
        assertEq(crowdfund.getCampaign(camp2).fund, 0);
        assertEq(crowdfund.getCampaign(camp2).start, 1);
        assertEq(crowdfund.getCampaign(camp2).end, 1 + 30 days);
        assertEq(uint256(crowdfund.getCampaign(camp2).state), uint256(STATE.ACTIVE));
        assertEq(uint256(crowdfund.getCampaign(camp2).campain_type), uint256(TYPE.STARTUP));
    }

    function testCreateCampaignFail() public {
        vm.expectRevert();
        crowdfund.createCampaign("campaign3", 50, 100 days, false, true);

        vm.expectRevert();
        crowdfund.createCampaign("campaign4", 50, 10 days, true, true);
    }

    function testFundCampaign() public {
        vm.deal(addr_2, 3 ether);
        vm.startPrank(addr_2);
        crowdfund.fundCampaign{value: 1 ether}(camp1);
        address(crowdfund).call{value: 1 ether}(abi.encodeWithSignature("fundCampaign(uint256)", camp1));
        assertEq(crowdfund.getCampaign(camp1).fund, 2 ether);
        assertEq(addr_2.balance, 1 ether);
        assertEq(crowdfund.getUserDeposit(addr_2), 2 ether);
        vm.stopPrank();
    }
    function testCancelCampaign() public {
        vm.startPrank(addr_1);
        crowdfund.cancelCampaign(camp1);
        vm.stopPrank();

        vm.deal(addr_2, 3 ether);
        vm.startPrank(addr_2);
        vm.expectRevert();
        crowdfund.cancelCampaign(camp1);
        vm.expectRevert();
        crowdfund.fundCampaign{value: 1 ether}(0);
        vm.stopPrank();
    }

    function testCampaignGoalReached() public {
        hoax(addr_1, 2 ether);
        crowdfund.fundCampaign{value: 1 ether}(camp1);
        crowdfund.fundCampaign{value: 1 ether}(camp1);
        
        assertEq(uint256(crowdfund.getCampaign(camp1).state), uint256(STATE.FULLY_FUNDED));

        vm.expectRevert();
        crowdfund.fundCampaign{value: 1 ether}(camp1);
    }

    function testExpiredCampaign() public {
        hoax(addr_1, 2 ether);
        crowdfund.fundCampaign{value: 1 ether}(camp1);
        vm.warp(1 + 11 days);
        vm.expectRevert();
        crowdfund.fundCampaign{value: 1 ether}(camp1);
        assertEq(uint256(crowdfund.getCampaign(camp1).state), uint256(STATE.PARTIALLY_FUNDED));
        assertEq(address(crowdfund).balance, 1 ether);
    }

    function testWithdrawFund() public {
        vm.startPrank(addr_2);
        vm.deal(addr_2, 2 ether);
        crowdfund.fundCampaign{value: 1 ether}(camp2);
        vm.expectRevert();
        crowdfund.withdrawFund(camp2);
        vm.warp(1 + 30 days+ 1 days);
        crowdfund.withdrawFund(camp2);
        assertEq(addr_2.balance, 2 ether);
    }
}