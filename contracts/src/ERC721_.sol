// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../lib/openzeppelin-contracts/contracts/interfaces/IERC721.sol";
import "../lib/openzeppelin-contracts/contracts/interfaces/IERC721Receiver.sol";
import "../lib/openzeppelin-contracts/contracts/interfaces/IERC721Metadata.sol";
import "../lib/openzeppelin-contracts/contracts/utils/Strings.sol"; 

contract ERC721_ is IERC165, IERC721, IERC721Metadata {

    /*//////////////////// CONFIG //////////////////*/
    using Strings for string;

    function supportsInterface(bytes4 _id) pure public override returns (bool) {
        return _id == type(IERC721).interfaceId
            || _id == type(IERC721Metadata).interfaceId
            || _id == type(IERC721Receiver).interfaceId;
    }

    /*//////////////////// EVENTS //////////////////*/
    
    event Mint(address indexed owner, uint256 indexed tokenId);

    /* 
        inherited from the interface:
            event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
            event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
            event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    */

    /*//////////////////// VARIABLES //////////////////*/

    uint256 private _tokenIds;
    uint256 private _circulatingsupply;
    uint256 private _totalSupply;
    uint256 private _price;
    uint256 private _maxPerTx;

    string private _name;
    string private _symbol;
    string private _baseURI;

    mapping(uint256 => address) _owner;
    mapping(address => uint256) _balance;
    mapping(uint256 => address) _approval;
    mapping(address => mapping(address => bool)) _operator;

    /*//////////////////// CONSTRUCTOR //////////////////*/

    constructor(string memory name_, string memory symbol_, uint256 totalSupply_, uint256 price_, uint256 maxPerTx_) {
        _tokenIds = 1;
        _name = name_;
        _symbol = symbol_;
        _circulatingsupply = 0;
        _totalSupply = totalSupply_;
        _price = price_;
        _maxPerTx = maxPerTx_;
    }

    /*//////////////////// GETTERS //////////////////*/

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function circulatingSupply() public view returns (uint256) {
        return _circulatingsupply;
    }

    function price() public view returns (uint256) {
        return _price;
    }

    function maxPerTx() public view returns (uint256) {
        return _maxPerTx;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_owner[tokenId] != address(0), "ERC721: token not minted");
        return string(abi.encodePacked(_baseURI, Strings.toString(tokenId)));
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _owner[tokenId];
    }

    function balanceOf(address _addr) public view override returns (uint256) {
        return _balance[_addr];
    }
    
    function getApproved(uint256 tokenId) public view override returns (address) {
        return _approval[tokenId];
    }

    function isApprovedForAll(address owner, address operator) external view override returns (bool) {
        return _operator[owner][operator];
    }

    /*//////////////////// LOGIC APPROVALS //////////////////*/

    function approve(address approvedAddr, uint256 tokenId) external {
        require(_owner[tokenId] != address(0), "ERC721: token not minted");
        require(ownerOf(tokenId) == msg.sender, "ERC721: only owner can approve");
        _approval[tokenId] = approvedAddr;
        emit Approval(msg.sender, approvedAddr, tokenId);
    }


    function setApprovalForAll(address operator, bool approved) public override {
        _operator[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /*//////////////////// LOGIC TRANSFERS //////////////////*/

    modifier isSafeToTransfer(address to, address from, uint256 tokenId, bytes calldata data) {
        bool success = false;
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                if (retval == IERC721Receiver.onERC721Received.selector)
                    success = true;

            } catch (bytes memory reason) {
                if (reason.length == 0)
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                else
                    assembly {revert(add(32, reason), mload(reason))}
            }
        }
        require(success == true, "ERC721: unsafe transfer");
       _;
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(ownerOf(tokenId) == msg.sender || getApproved(tokenId) == msg.sender, "ERC721: must own or be approved by owner to transfer");
        delete _approval[tokenId];
        _balance[to] += 1;
        _balance[from] -= 1;
        _owner[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        require(ownerOf(tokenId) == msg.sender || getApproved(tokenId) == msg.sender, "ERC721: must own or be approved by owner to transfer");
        transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public override isSafeToTransfer(to, from, tokenId, data) {
        require(ownerOf(tokenId) == msg.sender || getApproved(tokenId) == msg.sender, "ERC721: must own or be approved by owner to transfer");
        transferFrom(from, to, tokenId);
    }

    /*//////////////////// LOGIC MINT //////////////////*/

    function mint(uint256 quantity) payable external {
        require(quantity > 0, "ERC721: quantity must be greater than 0");
        require(quantity <= _maxPerTx, "ERC721: invalid amount of eth sent for set quantity");
        require(msg.value == _price * quantity, "ERC721: invalid amount of eth sent for set quantity");
        for (uint256 i = 0; i < quantity; i++) {
            _owner[_tokenIds] = msg.sender;
            _balance[msg.sender] += 1;

            emit Mint(msg.sender, _tokenIds);

            _tokenIds++;
            _circulatingsupply++;
        }
    }
    
}