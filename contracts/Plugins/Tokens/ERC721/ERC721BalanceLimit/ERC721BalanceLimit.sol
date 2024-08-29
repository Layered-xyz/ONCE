// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721} from "../ERC721.sol";
import {ERC721Lib} from "../ERC721Lib.sol";
import {ERC721BalanceLimitStorage} from "./ERC721BalanceLimitStorage.sol";
import { IOncePluginMod } from '../../../../Interfaces/IOncePluginMod.sol';
import { IOncePlugin } from '../../../../Interfaces/IOncePlugin.sol';

/**
 * @title ERC721BalanceLimit
 * @author Ketul 'Jay' Patel
 * @notice The ONCE Plugin for adding a balance limit to a ONCE ERC721 Token.
 * @notice Dependent on the ERC721 ONCE Plugin
 */
contract ERC721BalanceLimit is IOncePluginMod {

    // ONCE plugins are required to have at least one external function that can be added to the function selector mapping when installing a plugin
    // Current ONCE convention when a plugin is used only as a mod is to have a single external pure function.
    function balanceLimit() external view returns(uint256) {
        return ERC721BalanceLimitStorage.store().limit;
    }

    function _update(address to, uint256 tokenId, address auth) external view {
        to;
        tokenId;
        auth;
        if(ERC721Lib._balanceOf(to) >= ERC721BalanceLimitStorage.store().limit) {
            revert("Balance limit reached");
        }
    }

    /**
     * @inheritdoc IOncePlugin
     */
    function getFunctionSelectors() public pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = this.balanceLimit.selector;
        return selectors;
    }

    /**
     * @inheritdoc IOncePlugin
     */
    function getSingletonAddress() public view returns (address) {
        return address(this);
    } 

    function getModSelectors() public pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = this._update.selector;
        return selectors;
    }

}