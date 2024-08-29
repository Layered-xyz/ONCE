// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20 } from '../ERC20.sol';
import { ERC20CappedStorage } from "./ERC20CappedStorage.sol";
import { ERC20Lib } from '../ERC20Lib.sol';
import { IOncePluginMod } from '../../../../Interfaces/IOncePluginMod.sol';
import { IOncePlugin } from '../../../../Interfaces/IOncePlugin.sol';

/**
 * @title ERC20Capped
 * @author Ketul 'Jay' Patel
 * @notice The ONCE Plugin for adding capped functionality to a ONCE ERC20 Token.
 * @notice Dependent on the ERC20 ONCE Plugin
 * @dev modifies the ERC20 _update internal function
 */
contract ERC20Capped is IOncePluginMod {

    error ERC20ExceededCap(uint256 increasedSupply, uint256 cap);


    function cap() public view virtual returns (uint256) {
        return ERC20CappedStorage.store().cap;
    }

    function _update(address from, address to, uint256 value) external view {
        to;
        if(from == address(0)) {
            uint256 maxSupply = cap();
            uint256 supply = ERC20Lib.store().totalSupply + value;
            if(supply > maxSupply){
                revert ERC20ExceededCap(supply, maxSupply);
            }
        }
    }

    /**
     * @inheritdoc IOncePlugin
     */
    function getFunctionSelectors() public pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = this.cap.selector;
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