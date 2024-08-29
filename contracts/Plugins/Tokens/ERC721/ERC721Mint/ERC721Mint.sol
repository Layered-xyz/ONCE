// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ERC721} from "../ERC721.sol";
import {ERC721Lib} from "../ERC721Lib.sol";
import {ERC721MintStorage} from "./ERC721MintStorage.sol";
import { IOncePlugin } from '../../../../Interfaces/IOncePlugin.sol';

/**
 * @title ERC721Mint
 * @author Ketul 'Jay' Patel
 * @notice The ONCE Plugin for adding mint functionality to ERC721 tokens.
 * @notice Dependent on the ERC721 ONCE Plugin
 */
contract ERC721Mint is IOncePlugin {

    /**
     * @notice Mints an ERC721 token and assigns it to the specified account.
     * @param to The account to which the tokens will be minted.
     * @param tokenId The amount of tokens to mint.
     */
    function safeMint(address to, uint256 tokenId) external payable {
        uint256 price = ERC721MintStorage.store().price;
        string memory uniformURI = ERC721MintStorage.store().uniformURI;
        require(msg.value >= price, "Insufficient payment");
        ERC721Lib._safeMint(to, tokenId, "");
        if(bytes(uniformURI).length > 0) {
            ERC721Lib._setTokenURI(tokenId, uniformURI);
        }
    }

    /**
     * @inheritdoc IOncePlugin
     */
    function getFunctionSelectors() public pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = this.safeMint.selector;
        return selectors;
    }

    /**
     * @inheritdoc IOncePlugin
     */
    function getSingletonAddress() public view returns (address) {
        return address(this);
    } 
}
