// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721Lib} from "./ERC721Lib.sol";

/**
 * @title ERC721Init
 * @dev The initializer for the ERC721 token.
 */

contract ERC721Init {
    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the ERC721 token.
     * @param name_ The name of the token.
     * @param symbol_ The symbol of the token.
     */
    function init(string memory name_, string memory symbol_, string memory baseUri_) external {
        ERC721Lib.Store storage s = ERC721Lib.store();
        s.name = name_;
        s.symbol = symbol_;
        s.baseURI = baseUri_;
    }

}