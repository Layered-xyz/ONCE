// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

contract Reverter {
    function revert() public pure {
        require(false, "Shit happens");
    }
}