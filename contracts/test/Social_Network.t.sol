// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../lib/forge-std/src/console2.sol";
import "../lib/forge-std/src/Test.sol";
import "../src/Social_Network.sol";

contract Social_NetworkTest is Test {
    Social_Network internal socialContract;

    address internal alice = address(1);
    bytes32 internal aliceName = "alice";
    uint16 internal aliceAge = 30;

    address internal bob = address(2);
    bytes32 internal bobName = "bob";
    uint16 internal bobAge = 30;

    uint256 timestamp = 0;

    function setUp() public {
        socialContract = new Social_Network();
        
        vm.startPrank(alice);
        socialContract.createUser(aliceName, aliceAge);
        vm.stopPrank();
        
        vm.startPrank(bob);
        socialContract.createUser(bobName, bobAge);
        vm.stopPrank();

        vm.startPrank(alice);
        socialContract.sendFriendRequest(bob);
        vm.stopPrank();

        timestamp = block.timestamp;
    }

    function testCreateUser() public {
        assertEq(socialContract.getUserName(alice), aliceName);
        assertEq(socialContract.getUserAge(alice), aliceAge);
        assertEq(socialContract.getUserCreationTimestamp(alice), timestamp);
        assertEq(socialContract.getUserName(bob), bobName);
        assertEq(socialContract.getUserAge(bob), bobAge);
        assertEq(socialContract.getUserCreationTimestamp(bob), timestamp);
    }

    function testSendFriendRequests() public {
        vm.startPrank(alice);
        
        vm.expectRevert("Social_Network: you cannot be your own friend");
        socialContract.sendFriendRequest(alice);
        
        socialContract.sendFriendRequest(bob);
        assertEq(socialContract.getUserFriendRequests(bob)[0].userAddr, alice);


        vm.expectRevert("Social_Network: user does not exist");
        socialContract.sendFriendRequest(address(3));
        vm.stopPrank();
    }

    function testAcceptFriendRequests() public {
        vm.startPrank(bob);
        socialContract.acceptFriendRequest(0);
        vm.expectRevert("Social_Network: friend request already accepted");
        socialContract.acceptFriendRequest(0);


        vm.expectRevert("Social_Network: friend request does not exist");
        socialContract.acceptFriendRequest(2);
        
        vm.stopPrank();
    }

    function testDeclineFriendRequests() public {
        vm.startPrank(bob);

        socialContract.declineFriendRequest(0);
        vm.expectRevert("Social_Network: friend request already declined");
        socialContract.declineFriendRequest(0);
        
        vm.expectRevert("Social_Network: friend request does not exist");
        socialContract.declineFriendRequest(2);

        vm.stopPrank();
    }
}