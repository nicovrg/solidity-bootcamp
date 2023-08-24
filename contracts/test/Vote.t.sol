// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console2.sol";
import "../src/Vote.sol";

contract Vote_Test is Test {
    //contracts
    ERC721_ nftContract; 
    Vote internal voteContract; 

    //nft contract params
    string name = "nftname";
    string symbol = "nftsymbol";
    uint256 supply = 100;
    uint256 price = 0.1 ether;
    uint256 maxPerTx = 10;

    //vote contract params
    uint256 notice = 2 days;
    uint256 period = 5 days;
    uint256 quorum = supply * 20 / 100;
    uint8 maxOptions = 5;

    //test addresses
    address internal addr_1 = address(1); 
    address internal addr_2 = address(2); 
    address internal addr_3 = address(3); 
    address internal addr_4 = address(4); 
    address internal addr_5 = address(5); 

    // proposals var
    bytes32 internal proposal_1_name = "proposal - 1";
    uint256 internal proposalId1;
    string[] internal optionContentArray = [
        "vote for 1",
        "vote for 2",
        "vote for 3",
        "vote for 4",
        "vote for 5"
    ];

    function setUp() public {
        vm.startPrank(addr_1);
        nftContract = new ERC721_(name, symbol, supply , price, maxPerTx);
        voteContract = new Vote(quorum, notice, period, maxOptions, address(nftContract));
        proposalId1 = voteContract.createProposal(proposal_1_name, optionContentArray);
        vm.deal(addr_1, 0.1 ether);
        nftContract.mint{value: 0.1 ether}(1);
        vm.stopPrank();
    }

    /* TEST INITIAL STATE */

    function testVoteContractState() public {
        assertEq(voteContract.getQuorum(), quorum);
        assertEq(voteContract.getNotice(), notice);
        assertEq(voteContract.getPeriod(), period);
        assertEq(voteContract.getMaxOptions(), maxOptions);
        assertEq(voteContract.getNftContractAddr(), address(nftContract));
    }

    /* TEST CREATE & CANCEL PROPOSALS */

    function testCreateProposal() public {
        assertEq(voteContract.getProposalName(proposalId1), proposal_1_name);
        assertEq(voteContract.getProposalOwner(proposalId1), addr_1);
        assertEq(uint256(voteContract.getProposalState(proposalId1)), 0);
        assertEq(voteContract.getProposalStart(proposalId1), block.timestamp + notice);
        assertEq(voteContract.getProposalEnd(proposalId1), voteContract.getProposalStart(proposalId1) + period);
        assertEq(voteContract.getProposalNbVotes(proposalId1), 0);

        for (uint256 i = 0; i < optionContentArray.length; i++) {
            assertEq(voteContract.getProposalOptionsContent(proposalId1)[i], optionContentArray[i]);
            assertEq(voteContract.getProposalOptionsResult(proposalId1)[i], 0);
        }

        assertEq(voteContract.getWinningProposalIndex(proposalId1), 0);
        assertEq(voteContract.getEquality(proposalId1), false);
    }

    function testCancelProposal() public {
        vm.startPrank(addr_4);
        vm.expectRevert();
        voteContract.cancelProposal(1);
        vm.stopPrank();
        vm.startPrank(addr_1);
        voteContract.cancelProposal(1);
        vm.stopPrank();
        assertEq(uint256(voteContract.getProposalState(proposalId1)), 4);
    }

    /* TEST VOTE ON PROPOSALS */

    function testVotePendingProposal() public {
        vm.startPrank(addr_1);
        vm.expectRevert();
        voteContract.voteOnProposal(proposalId1, 0);
        vm.stopPrank();
    }

    function testVoteNotAnHolder() public {
        vm.startPrank(addr_2);
        // vm.expectRevert(voteContract.NotAnHolder.selector); // doesn't work?
        vm.expectRevert();
        voteContract.voteOnProposal(proposalId1, 0);
        vm.stopPrank();
    }

    function testVoteHoldingOneNft() public {
        vm.startPrank(addr_1);
        vm.warp(voteContract.getProposalStart(proposalId1));
        voteContract.voteOnProposal(proposalId1, 0);
        assertEq(voteContract.getProposalOptionsResult(proposalId1)[0], 1);
        vm.stopPrank();
    }

    function testVoteHoldingMultipleNft() public {
        vm.startPrank(addr_2);
        vm.deal(addr_2, 1 ether);
        nftContract.mint{value: 0.5 ether}(5);
        vm.warp(voteContract.getProposalStart(proposalId1));
        voteContract.voteOnProposal(proposalId1, 1);
        assertEq(voteContract.getProposalOptionsResult(proposalId1)[1], 5);
        vm.stopPrank();
    }

    function testVoteCancelProposal() public {
        vm.startPrank(addr_1);
        voteContract.cancelProposal(1);
        vm.expectRevert();
        voteContract.voteOnProposal(proposalId1, 1);
        vm.stopPrank();
    }
    function testVoteEndedProposal() public {
        vm.startPrank(addr_1);
        vm.warp(voteContract.getProposalEnd(proposalId1) + 1);
        vm.expectRevert();
        voteContract.voteOnProposal(proposalId1, 1);
        vm.stopPrank();
    }

    /* TEST PROPOSAL OUTCOME */


    function testProposalNoQuorum() public {
        vm.warp(voteContract.getProposalStart(proposalId1));
        vm.startPrank(addr_1);
        vm.deal(addr_1, 1 ether);
        nftContract.mint{value: 0.3 ether}(3);
        voteContract.voteOnProposal(proposalId1, 1);
        vm.stopPrank();
        vm.warp(voteContract.getProposalStart(proposalId1) + voteContract.getPeriod() + 1);
        voteContract.updateProposalState(proposalId1);
        assertEq(uint256(voteContract.getProposalState(proposalId1)), 3);
    }

    function testProposalPass() public {
        vm.warp(voteContract.getProposalStart(proposalId1));
        vm.startPrank(addr_1);
        vm.deal(addr_1, 1 ether);
        nftContract.mint{value: 1 ether}(10);
        voteContract.voteOnProposal(proposalId1, 1);
        vm.stopPrank();

        vm.startPrank(addr_2);
        vm.deal(addr_2, 1 ether);
        nftContract.mint{value: 1 ether}(10);
        voteContract.voteOnProposal(proposalId1, 1);
        vm.stopPrank();

        vm.startPrank(addr_3);
        vm.deal(addr_3, 1 ether);
        nftContract.mint{value: 1 ether}(10);
        voteContract.voteOnProposal(proposalId1, 2);
        vm.stopPrank();
        
        assertEq(voteContract.getProposalOptionsResultFromId(proposalId1, 0), 0);
        assertEq(voteContract.getProposalOptionsResultFromId(proposalId1, 1), 21);
        assertEq(voteContract.getProposalOptionsResultFromId(proposalId1, 2), 10);
        
        vm.warp(voteContract.getProposalStart(proposalId1) + voteContract.getPeriod() + 1);
        voteContract.updateProposalState(proposalId1);
        assertEq(uint256(voteContract.getProposalState(proposalId1)), 2);
        assertEq(voteContract.getWinningProposalIndex(proposalId1), 1);
        assertEq(voteContract.getEquality(proposalId1), false);
    }

    function testProposalFail() public {
        vm.warp(voteContract.getProposalStart(proposalId1));
        vm.startPrank(addr_1);
        vm.deal(addr_1, 1 ether);
        nftContract.mint{value: 0.3 ether}(3);
        voteContract.voteOnProposal(proposalId1, 1);
        vm.stopPrank();
        vm.startPrank(addr_2);
        vm.deal(addr_2, 1 ether);
        nftContract.mint{value: 0.2 ether}(2);
        voteContract.voteOnProposal(proposalId1, 1);
        vm.stopPrank();
        vm.startPrank(addr_3);
        vm.deal(addr_3, 1 ether);
        nftContract.mint{value: 0.5 ether}(5);
        voteContract.voteOnProposal(proposalId1, 2);
        vm.stopPrank();
        vm.warp(voteContract.getProposalStart(proposalId1) + voteContract.getPeriod() + 1);
        voteContract.updateProposalState(proposalId1);
        assertEq(uint256(voteContract.getProposalState(proposalId1)), 3);
    }

    function testProposalEquality() public {
        vm.warp(voteContract.getProposalStart(proposalId1));
        
        vm.startPrank(addr_2);
        vm.deal(addr_2, 1 ether);
        nftContract.mint{value: 1 ether}(10);
        voteContract.voteOnProposal(proposalId1, 1);
        vm.stopPrank();

        vm.startPrank(addr_3);
        vm.deal(addr_3, 1 ether);
        nftContract.mint{value: 1 ether}(10);
        voteContract.voteOnProposal(proposalId1, 2);
        vm.stopPrank();
        
        assertEq(voteContract.getProposalOptionsResultFromId(proposalId1, 0), 0);
        assertEq(voteContract.getProposalOptionsResultFromId(proposalId1, 1), 10);
        assertEq(voteContract.getProposalOptionsResultFromId(proposalId1, 2), 10);
        
        vm.warp(voteContract.getProposalStart(proposalId1) + voteContract.getPeriod() + 1);
        voteContract.updateProposalState(proposalId1);
        // assertEq(uint256(voteContract.getProposalState(proposalId1)), 3);
        assertEq(voteContract.getEquality(proposalId1), true);
    }

}
