// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { OnceStorage } from "./OnceStorage.sol";
import { PluginManagerStorage } from "../Plugins/PluginManager/PluginManagerStorage.sol";
import { IPluginManager } from "../Plugins/PluginManager/IPluginManager.sol";
import { IOncePlugin } from "../Interfaces/IOncePlugin.sol";

contract Once { 

    constructor(address _pluginManager, address _pluginViewer, address _accessControl) payable {        
        OnceStorage._grantRole(OnceStorage.ONCE_UPDATE_ROLE, msg.sender);
        OnceStorage._grantRole(OnceStorage.DEFAULT_ADMIN_ROLE, msg.sender);

        // Every Once by default comes with the following plugins which can be uninstalled or upgraded as needed:
        // -- PluginManager (uninstalling the PluginManager will make the Once immutable)
        // -- PluginViewer
        // -- AccessControl 

        // PluginManager
        IPluginManager.UpdateInstruction[] memory pluginManagerInstallation = new IPluginManager.UpdateInstruction[](1);
        pluginManagerInstallation[0] = IPluginManager.UpdateInstruction({
            pluginAddress: _pluginManager, 
            action: IPluginManager.UpdateActionType.Add, 
            functionSelectors: IOncePlugin(_pluginManager).getFunctionSelectors()
        });
        PluginManagerStorage.update(pluginManagerInstallation, address(0), "");

        // PluginViewer
        IPluginManager.UpdateInstruction[] memory pluginViewerInstallation = new IPluginManager.UpdateInstruction[](1);
        pluginViewerInstallation[0] = IPluginManager.UpdateInstruction({
            pluginAddress: _pluginViewer, 
            action: IPluginManager.UpdateActionType.Add, 
            functionSelectors: IOncePlugin(_pluginViewer).getFunctionSelectors()
        });
        PluginManagerStorage.update(pluginViewerInstallation, address(0), "");

        // AccessControl
        IPluginManager.UpdateInstruction[] memory accessControlInstallation = new IPluginManager.UpdateInstruction[](1);
        accessControlInstallation[0] = IPluginManager.UpdateInstruction({
            pluginAddress: _accessControl, 
            action: IPluginManager.UpdateActionType.Add, 
            functionSelectors: IOncePlugin(_accessControl).getFunctionSelectors()
        });
        PluginManagerStorage.update(accessControlInstallation, address(0), "");

        
    }

    // Find plugin for function that is called and execute the
    // function if a plugin is found and return any value.
    fallback() external payable {
        OnceStorage.Store storage ds;
        bytes32 position = OnceStorage.STORAGE_SLOT;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get plugin from function selector
        address plugin = ds.selectorToPluginAndPosition[msg.sig].pluginAddress;
        require(plugin != address(0), "Once: Function does not exist");
        // Execute external function from plugin using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the plugin
            let result := delegatecall(gas(), plugin, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
    }

    receive() external payable {}
}
