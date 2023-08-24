// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Whitelist {
    uint32 private _whitelistMax;
    uint32 private _whitelistCounter;
    address[] private _whitelistArray;
    mapping(address => bool) private _whitelistMapping;

    event AddedToWhitelist(address indexed whitelisted);

    constructor(uint32 _maxSize) {
        _whitelistCounter = 0;
        _whitelistMax = _maxSize;
    }

    function getWhitelistMax() view external returns (uint256) {
        return _whitelistMax;
    }

    function getWhitelistAtIndex(uint8 index) view external returns (address) {
        return _whitelistArray[index];
    }

    function getWhitelistArray() view external returns (address[] memory) {
        return _whitelistArray;
    }
    
    function isAddressWhitelisted(address _addr) external view returns (bool) {
        return _whitelistMapping[_addr];
    }
    
    function addToWhitelist() external {
        require(_whitelistMapping[msg.sender] == false, "address already in the whitelist");
        require(_whitelistCounter < _whitelistMax, "whitelist is full");
        _whitelistCounter++;
        _whitelistMapping[msg.sender] = true;
        _whitelistArray.push(msg.sender);
        emit AddedToWhitelist(msg.sender);
    }
}
