// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ERC721AccessControlMint} from "./ERC721AccessControlMint.sol";
import {ERC721AccessControlMintStorage} from "./ERC721AccessControlMintStorage.sol";

contract ERC721AccessControlMintInit {

    function init(uint256 _price, string memory _uniformURI) external {
        ERC721AccessControlMintStorage.Store storage s = ERC721AccessControlMintStorage.store();

        s.price = _price;
        s.uniformURI = _uniformURI;
    }
}