// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPluginViewer {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Plugin {
        address pluginAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all plugin addresses and their four byte function selectors.
    /// @return plugins_ plugin
    function plugins() external view returns (Plugin[] memory plugins_);

    /// @notice Gets all the function selectors supported by a specific plugin.
    /// @param _plugin The plugin address.
    /// @return pluginFunctionSelectors_
    function pluginFunctionSelectors(address _plugin) external view returns (bytes4[] memory pluginFunctionSelectors_);

    /// @notice Get all the plugin addresses used by a diamond.
    /// @return pluginAddresses_
    function pluginAddresses() external view returns (address[] memory pluginAddresses_);

    /// @notice Gets the plugin that supports the given selector.
    /// @dev If plugin is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return pluginAddress_ The plugin address.
    function pluginAddress(bytes4 _functionSelector) external view returns (address pluginAddress_);
}
