// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console.sol";
import "../src/String_Length.sol";


contract String_Length_Test is Test {
    String_Length public stringLength;
    string empty = "";
    string tenChar = "0123456789";

    function setUp() public {
        stringLength = new String_Length();
    }

    function testEmptyString() public {
        assertEq(stringLength.strLength(empty), 0);
    }

    function testString() view public {
        stringLength.strLength(tenChar);
    }
}
