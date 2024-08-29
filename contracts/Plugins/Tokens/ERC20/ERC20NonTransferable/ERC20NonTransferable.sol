// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "../ERC20.sol";
import { IOncePluginMod } from '../../../../Interfaces/IOncePluginMod.sol';
import { IOncePlugin } from '../../../../Interfaces/IOncePlugin.sol';

/**
 * @title ERC20Nontransferable
 * @author Ketul 'Jay' Patel
 * @notice The ONCE Plugin for adding non-transferable (soulbound) functionality to a ONCE ERC20 Token.
 * @notice Dependent on the ERC20 ONCE Plugin
 */
contract ERC20NonTransferable is IOncePluginMod {

    // ONCE plugins are required to have at least one external function that can be added to the function selector mapping when installing a plugin
    // Current ONCE convention when a plugin is used only as a mod is to have a single external pure function.
    function nonTransferable() external pure returns(bool) {
        return true;
    }

    function _update(address from, address to, uint256 value) external pure {
        from;
        to;
        value;
        if(from != address(0) && to != address(0)) {
            revert("Token is not transferable");
        }
    }

    /**
     * @inheritdoc IOncePlugin
     */
    function getFunctionSelectors() public pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = this.nonTransferable.selector;
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