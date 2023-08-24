// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/token/ERC721/ERC721.sol";
import "forge-std/console2.sol";
import "./Errors.sol";

contract SpellStrikers is ERC721 {
    struct SpellStriker {
        uint256 id;
        bytes32 name;
        uint8 resistance;
        uint8 power;
        uint8 level;
    }

    uint8 private immutable MAX_STAT_VAL = 9;
    mapping(uint256 => SpellStriker) spellStrikerByToken;

    modifier ensureStrikerExists(uint256 tokenId) {
        if (!_exists(tokenId)) {
            revert SpellStrikerNotFound();
        }
        _;
    }

    constructor() ERC721("SpellStrikers", "STRKRS") {}

    function create(bytes32 _name) external {
        uint256 id = uint256(keccak256(abi.encodePacked(_name, msg.sender)));
        _mint(msg.sender, id);

        uint8 power = _generateRandomPower(id);
        SpellStriker storage spellStriker = spellStrikerByToken[id];
        spellStriker.name = _name;
        spellStriker.power = power;
        spellStriker.resistance = MAX_STAT_VAL - power; // Power and resistance between 0 and 9
    }

    function get(uint256 tokenId)
        external
        view
        ensureStrikerExists(tokenId)
        returns (SpellStriker memory)
    {
        return spellStrikerByToken[tokenId];
    }

    function _generateRandomPower(uint256 _nonce)
        internal
        view
        returns (uint8)
    {
        return
            uint8(
                uint256(keccak256(abi.encodePacked(block.timestamp, _nonce))) %
                    10
            );
    }
}