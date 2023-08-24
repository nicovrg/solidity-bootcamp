// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Ownable.sol";

contract Social_Network is Ownable {
    
    struct User {
        bytes32 name;
        uint16 age;
        uint256 creationTimestamp;
    }

    enum STATE {
        NULL,
        PENDING,
        CANCELED
    }

    struct FriendRequest {
        STATE state;
        address userAddr;
        uint256 requestTimestamp;
    }

    uint256 public userNb;
    mapping(address => User) public users;

    mapping(address => address[]) public userFriends;
    mapping(address => FriendRequest[]) public userPendingRequests;

    event UserCreated(address addr, bytes32 name, uint16 age, uint256 creationTimestamp);
    event FriendRequestSent(address from, address to);
    event FriendRequestAccepted(address from, address to);
    event FriendRequestDeclined(address from, address to);

    modifier userExists(address addr) {
        require(users[addr].creationTimestamp != 0, "Social_Network: user does not exist");
        _;
    }   
    function getUserName(address userAddr) public view returns (bytes32) {
        return users[userAddr].name;
    }
    function getUserAge(address userAddr) public view returns (uint16) {
        return users[userAddr].age;
    }
    function getUserCreationTimestamp(address userAddr) public view returns (uint256) {
        return users[userAddr].creationTimestamp;
    }

    function getUserFriendRequests(address userAddr) public view returns (FriendRequest[] memory) {
        return userPendingRequests[userAddr];
    }

    function createUser(bytes32 name, uint16 age) external {
        require(name != "", "Social_Network: name cannot be empty");
        require(age >= 10, "Social_Network: user needs to be above 10 yo");
        require(users[msg.sender].creationTimestamp == 0, "Social_Network: user already created");

        users[msg.sender].name = name;
        users[msg.sender].age = age;
        users[msg.sender].creationTimestamp = block.timestamp;
        userNb += 1;

        emit UserCreated(msg.sender, name, age, block.timestamp);
    }

    function sendFriendRequest(address friend) external userExists(msg.sender) userExists(friend) {
        require(msg.sender != friend, "Social_Network: you cannot be your own friend");
        FriendRequest memory request = FriendRequest({
            state: STATE.PENDING,
            userAddr: msg.sender,
            requestTimestamp: block.timestamp
        });
        userPendingRequests[friend].push(request);

        emit FriendRequestSent(msg.sender, friend);
    }

    function acceptFriendRequest(uint index) external userExists(msg.sender) {
        uint numRequests = userPendingRequests[msg.sender].length;
        require(index < numRequests, "Social_Network: friend request does not exist");

        FriendRequest memory request = userPendingRequests[msg.sender][index];
        FriendRequest storage lastRequest = userPendingRequests[msg.sender][numRequests-1];

        require(request.state == STATE.PENDING, "Social_Network: friend request already accepted");
        userFriends[msg.sender].push(msg.sender);

        request = lastRequest;
        delete userPendingRequests[msg.sender][numRequests-1];
    
        emit FriendRequestAccepted(msg.sender, userPendingRequests[msg.sender][index].userAddr);
    }

    function declineFriendRequest(uint index) external userExists(msg.sender) {
        uint numRequests = userPendingRequests[msg.sender].length;
        require(index < numRequests, "Social_Network: friend request does not exist");

        FriendRequest memory request = userPendingRequests[msg.sender][index];
        FriendRequest storage lastRequest = userPendingRequests[msg.sender][numRequests-1];

        require(request.state == STATE.PENDING, "Social_Network: friend request already declined");

        request = lastRequest;
        delete userPendingRequests[msg.sender][numRequests-1];
    
        emit FriendRequestDeclined(msg.sender, userPendingRequests[msg.sender][index].userAddr);
    }
}