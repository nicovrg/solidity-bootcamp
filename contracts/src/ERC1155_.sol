// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../src/ERC1155TokenReceiver.sol";
import "../lib/openzeppelin-contracts/contracts/interfaces/IERC1155.sol";
import "../lib/openzeppelin-contracts/contracts/interfaces/IERC1155Receiver.sol";
import "../lib/openzeppelin-contracts/contracts/interfaces/IERC1155MetadataURI.sol";
import "../lib/openzeppelin-contracts/contracts/utils/Strings.sol"; 

// https://eips.ethereum.org/EIPS/eip-1155

contract ERC1155_ is IERC165, IERC1155, IERC1155MetadataURI {

    /*//////////////////// CONFIG //////////////////*/
    using Strings for string;
    
    function supportsInterface(bytes4 _id) pure public override returns (bool) {
        return _id == type(IERC1155).interfaceId 
            || _id == type(IERC1155Receiver).interfaceId
            || _id == type(IERC1155MetadataURI).interfaceId;
    }

    /*//////////////////// EVENTS //////////////////*/

    event Mint();

    /* 
        inherited from the interface:
        
            event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 amount);
            event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] amounts);
            event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    */ 


    /*//////////////////// VARIABLES //////////////////*/

    string baseURI;
    
    mapping(address => mapping(uint256 => uint256)) public balance;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////// CONSTRUCTOR //////////////////*/

    constructor(string memory _baseURI) {
        baseURI = _baseURI;
    }

    /*//////////////////// TRANSFER //////////////////*/
    
    function uri(uint256 id) public view virtual returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(id)));
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "ERC1155: transfer is not authorized");
        require(to.code.length == 0, "ERC1155: recipient can't be a contract");
        require(to != address(0), "ERC1155: receipient can't be address(0)");
        // require(ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) == ERC1155TokenReceiver.onERC1155Received.selector, "ERC1155: receipient don't implement onERC1155Received properly"); 
        
        balance[from][id] -= amount;
        balance[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);
    }

    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) public virtual {
        require(ids.length == amounts.length, "ERC1155: ids array and amounts array input size provide don't match");
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "ERC1155: transfer isn't from owner or operator approved by owner");
        require(to.code.length == 0, "ERC1155: recipient can't be a contract");
        require(to != address(0), "ERC1155: receipient can't be address(0)");
        // require(ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) == ERC1155TokenReceiver.onERC1155BatchReceived.selector, "ERC1155: receipient don't implement onERC1155BatchReceived properly"); 

        uint256 id;
        uint256 amount;
        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];
            balance[from][id] -= amount;
            balance[to][id] += amount;
            ++i;
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);
    }

    /*//////////////////// BALANCES //////////////////*/

    function balanceOf(address owner, uint256 id) external view returns (uint256) {
        return balance[owner][id];
    }


    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) public view virtual returns (uint256[] memory) {
        require(owners.length == ids.length, "ERC1155: LENGTH_MISMATCH");

        uint256[] memory balances = new uint256[](owners.length);

        for (uint256 i = 0; i < owners.length; ++i) {
            balances[i] = balance[owners[i]][ids[i]];
        }

        return balances;
    }

    /*//////////////////// MINT & BURN //////////////////*/

    function _mint(address to, uint256 id, uint256 amount, bytes memory data) public {
        require(to.code.length == 0, "ERC1155: recipient can't be a contract");
        require(to != address(0), "ERC1155: receipient can't be address(0)");
        // require(ERC1155TokenReceiver(to).onERC1155Received(msg.sender, to, id, amount, data) == ERC1155TokenReceiver.onERC1155Received.selector, "ERC1155: receipient don't implement onERC1155Received properly"); 

        balance[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);
    }

    function _batchMint(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public virtual {
        require(ids.length == amounts.length, "ERC1155: LENGTH_MISMATCH");
        require(to.code.length == 0, "ERC1155: recipient can't be a contract");
        require(to != address(0), "ERC1155: receipient can't be address(0)");
        // require(ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, to, ids, amounts, data) == ERC1155TokenReceiver.onERC1155BatchReceived.selector, "ERC1155: receipient don't implement onERC1155BatchReceived properly "); 

        uint256 idsLength = ids.length;
        for (uint256 i = 0; i < idsLength; ) {
            balance[to][ids[i]] += amounts[i];
            ++i;
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

    }

    function _burn(address from, uint256 id, uint256 amount) public virtual {
        balance[from][id] -= amount;
        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }

    function _batchBurn(address from, uint256[] memory ids, uint256[] memory amounts) public virtual {
        require(ids.length == amounts.length, "ERC1155: LENGTH_MISMATCH");

        uint256 idsLength = ids.length;
        for (uint256 i = 0; i < idsLength; ) {
            balance[from][ids[i]] -= amounts[i];
            ++i;
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }
}