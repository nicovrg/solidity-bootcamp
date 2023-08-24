// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/SpellStrikers.sol";

contract SpellStrikersTest is Test {
    SpellStrikers strikers;

    function setUp() public {
        strikers = new SpellStrikers();
    }
}