// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

abstract contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: only owner can call this function");
        _;
    }

    modifier isValidAddress(address addr) {
        require(addr != address(0), "Ownable: address cannot be zero");
        _;
    }

    constructor() {
        _transferOwnership(msg.sender);
    }

    function transferOwnership(address newOwner) external onlyOwner isValidAddress(newOwner) {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) private {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}