// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// no constraint or cost on mint & burn function

contract ERC20_ {
    string public name;
    string public symbol;
    uint8 public decimals = 18;

    uint256 public supply;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance; 

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    constructor(string memory _name, string memory _symbol, uint256 _totalSupply) {
        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(balanceOf[msg.sender] >= amount, "ERC20_: not enough funds");
        balanceOf[msg.sender] -= amount;
        unchecked {balanceOf[to] += amount;}
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        if (allowed != type(uint256).max) {
            allowance[from][msg.sender] = allowed - amount;
        }
        allowance[from][msg.sender] = allowed - amount;
        balanceOf[from] -= amount;
        unchecked {balanceOf[to] += amount;}
        emit Transfer(from, to, amount);
        return true;
    }

    function _mint(address to, uint256 amount) external {
        require(amount + supply < totalSupply, "ERC20_: can't mint more than total supply");
        supply += amount;  // overflow checked
        unchecked {balanceOf[to] += amount;}
        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) external {
        balanceOf[from] -= amount;  // underflow checked
        unchecked {supply -= amount;}
        emit Transfer(from, address(0), amount);
    }
}
