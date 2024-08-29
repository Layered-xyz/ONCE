// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ERC721AutoIncrementAccessControlMint} from "./ERC721AutoIncrementAccessControlMint.sol";
import {ERC721AutoIncrementAccessControlMintStorage} from "./ERC721AutoIncrementAccessControlMintStorage.sol";

contract ERC721AutoIncrementAccessControlMintInit {

    function init(uint256 _price, uint256 _previousTokenId, string memory _uniformURI) external {
        ERC721AutoIncrementAccessControlMintStorage.Store storage s = ERC721AutoIncrementAccessControlMintStorage.store();

        s.price = _price;
        s.nextTokenId = _previousTokenId;
        s.uniformURI = _uniformURI;
    }
}