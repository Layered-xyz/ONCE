// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { OnceStorage } from  "../../Base/OnceStorage.sol";
import { IPluginViewer } from "./IPluginViewer.sol";
import { IERC165 } from "../../Base/interfaces/IERC165.sol";
import { IOncePlugin } from "../../Interfaces/IOncePlugin.sol";

/**
 * @title PluginViewer -- a plugin for examining the functions and plugins installed on the Once
 * @author Ketul 'Jay' Patel
 * @notice PluginViewer is a Once plugin installed by default for viewing the installed plugins and their corresponding function selectors
 */
contract PluginViewer is IPluginViewer, IERC165, IOncePlugin {

    /// @notice Gets all plugins and their selectors.
    /// @return plugins_ Plugin
    function plugins() external override view returns (Plugin[] memory plugins_) {
        OnceStorage.Store storage ds = OnceStorage.store();
        uint256 numPlugins = ds.pluginAddresses.length;
        plugins_ = new Plugin[](numPlugins);
        for (uint256 i; i < numPlugins; i++) {
            address pluginAddress_ = ds.pluginAddresses[i];
            plugins_[i].pluginAddress = pluginAddress_;
            plugins_[i].functionSelectors = ds.pluginFunctionSelectors[pluginAddress_].functionSelectors;
        }
    }

    /// @notice Gets all the function selectors provided by a plugin.
    /// @param _plugin The plugin address.
    /// @return pluginFunctionSelectors_
    function pluginFunctionSelectors(address _plugin) external override view returns (bytes4[] memory pluginFunctionSelectors_) {
        OnceStorage.Store storage ds = OnceStorage.store();
        pluginFunctionSelectors_ = ds.pluginFunctionSelectors[_plugin].functionSelectors;
    }

    /// @notice Get all the plugin addresses used by a Once.
    /// @return pluginAddresses_
    function pluginAddresses() external override view returns (address[] memory pluginAddresses_) {
        OnceStorage.Store storage ds = OnceStorage.store();
        pluginAddresses_ = ds.pluginAddresses;
    }

    /// @notice Gets the plugin that supports the given selector.
    /// @dev If plugin is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return pluginAddress_ The plugin address.
    function pluginAddress(bytes4 _functionSelector) external override view returns (address pluginAddress_) {
        OnceStorage.Store storage ds = OnceStorage.store();
        pluginAddress_ = ds.selectorToPluginAndPosition[_functionSelector].pluginAddress;
    }

    /// @notice Gets the default plugin
    /// @dev default plugin will be used when no function selector matches a plugin address.
    /// @return defaultPluginAddress the address for default fallback
    function getDefaultPlugin() external override view returns (address defaultPluginAddress) {
        OnceStorage.Store storage ds = OnceStorage.store();
        defaultPluginAddress = ds.defaultFallback;
    }

    function supportsInterface(bytes4 _interfaceId) external override view returns (bool) {
        OnceStorage.Store storage ds = OnceStorage.store();
        return ds.supportedInterfaces[_interfaceId];
    }
    /**
     * @inheritdoc IOncePlugin
    */
    function getFunctionSelectors() public pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](5);
        selectors[0] = this.plugins.selector;
        selectors[1] = this.pluginFunctionSelectors.selector;
        selectors[2] = this.pluginAddresses.selector;
        selectors[3] = this.pluginAddress.selector;
        selectors[4] = this.getDefaultPlugin.selector;
        return selectors;
    }
    /**
     * @inheritdoc IOncePlugin
    */
    function getSingletonAddress() public view returns (address) {
        return address(this);
    }
}
