// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20Lib} from "../ERC20Lib.sol";
import {ERC20} from "../ERC20.sol";
import {IOncePlugin} from "../../../../Interfaces/IOncePlugin.sol";

/**
 * @title ERC20Burnable
 * @author Ketul 'Jay' Patel
 * @notice The ONCE Plugin for adding burnable functionality to a ONCE ERC20 Token.
 * @notice Dependent on the ERC20 ONCE Plugin
 */
contract ERC20Burnable is IOncePlugin {
    /**
     * @notice Burns a specific amount of tokens from the caller's account.
     * @dev Reduces the total supply of tokens. The value must be greater than 0.
     * @param value The amount of tokens to be burned.
     */
    function burn(uint256 value) public {
        ERC20Lib._burn(msg.sender, value);
    }

    /**
     * @notice Burns a specific amount of tokens from a specified account, deducting from the caller's allowance.
     * @dev Reduces the total supply of tokens. The value must be greater than 0. Requires allowance to be set.
     * @param account The account whose tokens will be burned.
     * @param value The amount of tokens to be burned.
     * @return A boolean value indicating whether the operation succeeded.
     */
    function burnFrom(address account, uint256 value) public returns (bool) {
        address spender = msg.sender;
        ERC20Lib._spendAllowance(account, spender, value);
        ERC20Lib._burn(account, value);

        return true;
    }

    /**
     * @inheritdoc IOncePlugin
     */
    function getFunctionSelectors() public pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = this.burn.selector;
        selectors[1] = this.burnFrom.selector;
        return selectors;
    }

    /**
     * @inheritdoc IOncePlugin
     */
    function getSingletonAddress() public view returns (address) {
        return address(this);
    } 
}