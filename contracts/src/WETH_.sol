// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract WETH_ {
    string public name = "Wrapped Ether";
    string public symbol = "WETH";
    uint8 public decimals = 8;

    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Deposit(address indexed from, uint amount);
    event Withdraw(address indexed to, uint amount);

    receive() external payable {
        deposit();
    }

    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint amount) external {
        require(balanceOf[msg.sender] >= amount, "WETH: not enough fund to withdraw");
        balanceOf[msg.sender] -= amount;
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success);
        
        emit Withdraw(msg.sender, amount);
    }

    function totalSupply() public view returns (uint) {
        return address(this).balance;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(balanceOf[msg.sender] >= amount, "WETH: Not enough funds");

        balanceOf[msg.sender] -= amount;
        unchecked {balanceOf[to] += amount;}
        emit Transfer(msg.sender, to, amount);
        
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(balanceOf[from] >= amount, "WETH: Not enough funds");
        require(allowance[from][msg.sender] >= amount, "WETH: Not allowed to transfer this amount");

        balanceOf[from] -= amount;
        allowance[from][msg.sender] = allowance[from][msg.sender] - amount;

        unchecked {balanceOf[to] += amount;}
        emit Transfer(from, to, amount);
        
        return true;
    }
}
