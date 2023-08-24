// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../src/ERC1155_.sol";
import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console2.sol";
import "../lib/openzeppelin-contracts/contracts/utils/Strings.sol"; 

contract ERC1155_Test is Test {
    using Strings for string;

    ERC1155_ internal nftContract; 

    string baseURI = ".../";


    address internal alice = address(1); 
    address internal bob = address(2); 

    function setUp() public {
        nftContract = new ERC1155_(baseURI);
        nftContract._mint(alice, 1, 3, "");
        nftContract._mint(alice, 2, 1, "");
    }

    function testSetUp() public {
        assertEq(nftContract.balance(alice, 1), 3);
    }

    function testUri() public {
        assertEq(nftContract.uri(1), string(abi.encodePacked(baseURI, Strings.toString(1))));
    }

    function testApprovalForALl() public {
        vm.startPrank(alice);
        nftContract.setApprovalForAll(bob, true);
        assertEq(nftContract.isApprovedForAll(alice, bob), true);
        vm.stopPrank();
    }

    function testSafeTransferFrom() public {
        vm.startPrank(alice);
        nftContract.safeTransferFrom(alice, bob, 1, 1, "");
        assertEq(nftContract.balance(alice, 1), 2);
        assertEq(nftContract.balance(bob, 1), 1);
        vm.stopPrank();
    }

    function testSafeBatchTransferFrom() public {
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        
        ids[0] = 1;
        ids[1] = 2;
        amounts[0] = 3;
        amounts[1] = 1;

        vm.startPrank(alice);
        nftContract.safeBatchTransferFrom(alice, bob, ids, amounts, "");
        assertEq(nftContract.balance(alice, 1), 0);
        assertEq(nftContract.balance(bob, 1), 3);
        vm.stopPrank();
    }

    function testBalanceOf() public {
        assertEq(nftContract.balanceOf(alice, 1), 3);
    }

    function testBalanceOfBatch() public {
        address[] memory owners = new address[](2);
        uint256[] memory ids = new uint256[](2);
        
        owners[0] = alice;
        owners[1] = alice;

        ids[0] = 1;
        ids[1] = 2;

        assertEq(nftContract.balanceOf(alice, 1), 3);
        assertEq(nftContract.balanceOf(alice, 2), 1);
    }

    function testMint() public {
        vm.startPrank(alice);
        nftContract._mint(alice, 5, 3, "");
        assertEq(nftContract.balance(alice, 5), 3);
        vm.stopPrank();
    }

    function testBatchMint() public {
        uint256[] memory ids = new uint256[](3);
        ids[0] = 10;
        ids[1] = 11;
        ids[2] = 12;

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 1;
        amounts[1] = 2;
        amounts[2] = 3;

        vm.startPrank(alice);
        nftContract._batchMint(alice, ids, amounts, "");
        assertEq(nftContract.balance(alice, 10), 1);
        assertEq(nftContract.balance(alice, 11), 2);
        assertEq(nftContract.balance(alice, 12), 3);
        vm.stopPrank();
    }

    function testBurn() public {
        vm.startPrank(alice);
        nftContract._burn(alice, 1, 3);
        assertEq(nftContract.balance(alice, 1), 0);
        vm.stopPrank();
    }

    function testBatchBurn() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 3;
        amounts[1] = 1;
        
        vm.startPrank(alice);
        nftContract._batchBurn(alice, ids, amounts);
        assertEq(nftContract.balance(alice, 1), 0);
        assertEq(nftContract.balance(alice, 2), 0);
        vm.stopPrank();
    }
}