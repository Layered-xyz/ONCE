// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/**
 * @title IOncePlugin -- The interface for a ONCE Plugin
 * @author Ketul 'Jay' Patel
 */
interface IOncePlugin {
    /**
     * @notice getFunctionSelectors returns all function selectors to be installed for the plugin
     * @dev this function allows plugins to only expose the functions that should be called, avoiding conflicts for common interfaces like access control
     */
    function getFunctionSelectors() external view returns (bytes4[] memory);

    /**
     * @notice getSingletonAddress returns the address of the contract the function selectors should be called on
     * @dev getSingletonAddress should return the address of the deployed plugin unless the plugin is a wrapper for functionality that already uses a proxy/singleton pattern in which case it should return the address of the singleton to avoid an unnecessary double fallback
     */
    function getSingletonAddress() external view returns (address);
}