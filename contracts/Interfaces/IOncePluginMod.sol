// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IOncePlugin } from "./IOncePlugin.sol";
/**
 * @title IOncePlugin -- The interface for a ONCE Plugin Modifier
 * @author Ketul 'Jay' Patel
 */
interface IOncePluginMod is IOncePlugin {
    /**
     * @notice getModSelectors returns all function selectors that are installed as modifiers for a dependency plugin
     * @dev Mods should not be installed directly by the user, rather they should be installed by the plugin's initialization contract
     * @dev these selectors should be different from the selectors returned by getFunctionSelectors since mods should only be callable by another plugins function (using the mod delegate pattern) rather than directly by a user
     */
    function getModSelectors() external view returns (bytes4[] memory);
}