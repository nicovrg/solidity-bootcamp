// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../src/ERC721_.sol";
import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console2.sol";

contract ERC721_Test is Test {
    
    ERC721_ internal nftContract; 

    string name = "nftname";
    string symbol = "nftsymbol";

    uint256 totalSupply = 100;
    uint256 price = 0.1 ether;
    uint256 maxPerTx = 10;

    address internal owner1 = address(1); 
    address internal owner2 = address(2); 
    address internal owner3 = address(3); 
    address internal owner4 = address(4); 

    function setUp() public {
        nftContract = new ERC721_(name, symbol, totalSupply , price, maxPerTx);
        vm.deal(owner1, 0.1 ether);
        vm.deal(owner2, 0.5 ether);
        vm.deal(owner3, 1 ether);

        vm.startPrank(owner1);
        nftContract.mint{value: 0.1 ether}(1);
        vm.stopPrank();
        
        vm.startPrank(owner2);
        nftContract.mint{value: 0.5 ether}(5);
        vm.stopPrank();
        
        vm.startPrank(owner3);
        nftContract.mint{value: 1 ether}(10);
        vm.stopPrank();
    }

    function testContractState() public {
        assertEq(nftContract.name(), name);        
        assertEq(nftContract.symbol(), symbol);        
        assertEq(nftContract.totalSupply(), totalSupply);        
        assertEq(nftContract.price(), price);        
        assertEq(nftContract.maxPerTx(), maxPerTx);        
    }

    function testMintOne() public {
        assertEq(nftContract.balanceOf(owner1), 1);
    }

    function testMintMultiple() public {
        assertEq(nftContract.balanceOf(owner2), 5);
        assertEq(nftContract.balanceOf(owner3), 10);
    }

    function testMintFail() public {
        vm.deal(owner4, 10 ether);
        vm.startPrank(owner4);
        vm.expectRevert("ERC721: invalid amount of eth sent for set quantity");
        nftContract.mint{value: 0.1 ether}(2);

        vm.expectRevert("ERC721: quantity must be greater than 0");
        nftContract.mint{value: 0.1 ether}(0);

        vm.expectRevert("ERC721: invalid amount of eth sent for set quantity");
        nftContract.mint{value: 0.1 ether}(100);

        vm.stopPrank();
    }

    function testApprove() public {
        vm.startPrank(owner1);
        nftContract.approve(owner2, 1);
        vm.expectRevert("ERC721: token not minted");
        nftContract.approve(owner1, 0);
        vm.expectRevert("ERC721: only owner can approve");
        nftContract.approve(owner1, 2);
        vm.expectRevert("ERC721: token not minted");
        nftContract.approve(owner1, 10000);
        vm.stopPrank();

        vm.startPrank(owner2);
        nftContract.transferFrom(owner1, owner3, 1);
        vm.stopPrank();
    }

    function testApproveForAll() public {
        vm.startPrank(owner2);
        nftContract.setApprovalForAll(owner1, true);
        nftContract.transferFrom(owner2, owner3, 2);
        nftContract.transferFrom(owner2, owner3, 3);
        nftContract.transferFrom(owner2, owner3, 4);
        nftContract.transferFrom(owner2, owner3, 5);
        nftContract.transferFrom(owner2, owner3, 6);
        vm.stopPrank();
        vm.startPrank(owner3);
        nftContract.transferFrom(owner3, owner1, 3);
        vm.stopPrank();
    }
    function testIsApproveForAll() public {
        vm.startPrank(owner2);
        nftContract.setApprovalForAll(owner1, true);
        assertEq(nftContract.isApprovedForAll(owner2, owner1), true);
        assertEq(nftContract.isApprovedForAll(owner2, owner3), false);
        vm.stopPrank();
    }

    function testTransferFrom() public {
        vm.startPrank(owner1);
        nftContract.transferFrom(owner1, owner3, 1);
        vm.stopPrank();
        vm.startPrank(owner3);
        nftContract.transferFrom(owner3, owner1, 1);
        vm.stopPrank();
    }
    function testSafeTransferFrom() public {
        vm.startPrank(owner1);
        nftContract.safeTransferFrom(owner1, owner3, 1);
        vm.stopPrank();
        vm.startPrank(owner3);
        nftContract.safeTransferFrom(owner3, owner1, 1);
        vm.stopPrank();
    }
 
    function testSafeTransferFromWithData() public {
        vm.startPrank(owner1);
        nftContract.safeTransferFrom(owner1, owner3, 1);
        vm.stopPrank();
        vm.startPrank(owner3);
        nftContract.safeTransferFrom(owner3, owner1, 1);
        vm.stopPrank();
    }

}
