// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ERC721Mint} from "./ERC721Mint.sol";
import {ERC721MintStorage} from "./ERC721MintStorage.sol";

contract ERC721MintInit {

    function init(uint256 _price, string memory _uniformURI) external {
        ERC721MintStorage.Store storage s = ERC721MintStorage.store();

        s.price = _price;
        s.uniformURI = _uniformURI;
    }
}