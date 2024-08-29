// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ERC721} from "../ERC721.sol";
import {ERC721AutoIncrementMintStorage} from "./ERC721AutoIncrementMintStorage.sol";
import { IOncePlugin } from '../../../../Interfaces/IOncePlugin.sol';

/**
 * @title ERC721AutoIncrementMint
 * @author Ketul 'Jay' Patel
 * @notice The ONCE Plugin for adding auto incrementing mint functionality to ERC721 tokens.
 * @notice Dependent on the ERC721 ONCE Plugin
 */
contract ERC721AutoIncrementMint is IOncePlugin {

    /**
     * @dev Mints an ERC721 token and assigns it to the specified account.
     * @param to The account to which the tokens will be minted.
     */
    function safeMint(address to) payable external {
        uint256 price = ERC721AutoIncrementMintStorage.store().price;
        require(msg.value >= price, "ERC721MintableFacet: Insufficient payment");
        ERC721AutoIncrementMintStorage.autoIncrementSafeMint(to);
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
