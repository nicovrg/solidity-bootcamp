// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Ownership {
    string private name;
    address public owner;
    address[] private ownerHistory;

    event NameChanged(string newName);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor(address _owner) {
        require(_owner != address(0));
        owner = _owner;
    }

    function getName() external view returns (string memory) {
        return name;
    }

    function historicalOwner(uint256 index) external view returns (address) {
        require(index < ownerHistory.length, "Index invalid");
        return ownerHistory[index];
    }

    function ownerHistorySlice(uint256 start, uint256 end) external view returns (address[] memory) {
        require(start < ownerHistory.length);
        require(end < ownerHistory.length);
        require(start < end);
        address[] memory slice;
        for (uint i = start; i < end; i++) {
            slice[i - start] = ownerHistory[i];
        }
        return slice;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0));
        ownerHistory.push(owner);
        owner = newOwner;
        emit OwnershipTransferred(ownerHistory[ownerHistory.length-1], newOwner);
    }

    function changeName(string calldata newName) external onlyOwner {
        name = newName;
        emit NameChanged(newName);
    }
}
