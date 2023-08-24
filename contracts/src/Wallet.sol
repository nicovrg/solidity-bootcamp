import "./Ownable.sol";
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Wallet is Ownable {
    uint256 private _balance;
    
    constructor() payable {
        _balance = msg.value;
    }

    event receiveEvent(uint256 _value, address _from);
    event transferEvent(uint256 _value, address _to);
    event widthdrawEvent(uint256 _value, address _to);

    function getOwner() view external returns (address) {
        return owner;
    }

    function getBalance() view external returns (uint256) {
        return _balance;
    }

    function receivedFunds() external payable {
        _balance += msg.value;
        emit receiveEvent(msg.value, msg.sender);
    }

    function transferToAddress(uint256 _value, address payable _addr) public onlyOwner {
        require(_value <= _balance, "Wallet: not enough funds to transfer");
        (bool result , ) = _addr.call{value: _value}("");
        require(result == true, "Wallet: transfer failed");
        _balance -= _value;
        emit transferEvent(_value, _addr);
    }

    function withdrawToAddress(uint256 _value, address payable _addr) public onlyOwner {
        require(_value <= _balance, "Wallet: not enough funds to withdraw");
        (bool result , ) = _addr.call{value: _value}("");
        require(result == true, "Wallet: withdraw failed");
        _balance -= _value;
        emit widthdrawEvent(_value, _addr);
    }
}