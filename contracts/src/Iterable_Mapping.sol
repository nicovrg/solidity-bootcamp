// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Iterable_Mapping {
    IterableMap private _map;

    struct IterableMap {
        uint256 counter;
        mapping (uint256 => address) indexToAddr;
        mapping (address => uint256) addrToIndex;
        mapping (address => uint256) value;
    }

    constructor() {
        _map.counter = 0;
    }

    function addToMapping(address _addr, uint256 _value) public {
        _map.indexToAddr[_map.counter] = _addr;
        _map.addrToIndex[_addr] = _map.counter;
        _map.value[_addr] = _value;
        _map.counter++;
    }

    function getAddressFromIndex(uint256 _index) view public returns (address) {
        return _map.indexToAddr[_index];
    }
    
    function getIndexFromAddress(address _addr) view public returns (uint256) {
        return _map.addrToIndex[_addr];
    }

    function getValueFromAddress(address _addr) view public returns (uint256) {
        return _map.value[_addr];
    }

    function getValueFromIndex(uint256 _index) view public returns (uint256) {
        return _map.value[_map.indexToAddr[_index]];
    }

    function removeFromMappingWithKey(address _addr) public {
        delete _map.indexToAddr[_map.addrToIndex[_addr]];
        delete _map.addrToIndex[_addr];
        delete _map.value[_addr];
    }

    function removeFromMappingWithIndex(uint256 _index) public {
        delete _map.addrToIndex[_map.indexToAddr[_index]];
        delete _map.value[_map.indexToAddr[_index]];
        delete _map.indexToAddr[_index];
    }
}
