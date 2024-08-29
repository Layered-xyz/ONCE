// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ERC721AutoIncrementMint} from "./ERC721AutoIncrementMint.sol";
import {ERC721AutoIncrementMintStorage} from "./ERC721AutoIncrementMintStorage.sol";

contract ERC721AutoIncrementMintInit {

    function init(uint256 _price, uint256 _previousTokenId, string memory _uniformURI) external {
        ERC721AutoIncrementMintStorage.Store storage s = ERC721AutoIncrementMintStorage.store();

        s.price = _price;
        s.nextTokenId = _previousTokenId;
        s.uniformURI = _uniformURI;
    }
}