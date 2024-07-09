// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { OnceStorage } from "./OnceStorage.sol";
import { PluginManagerStorage } from "../Plugins/PluginManager/PluginManagerStorage.sol";
import { IPluginManager } from "../Plugins/PluginManager/IPluginManager.sol";
import { IOncePlugin } from "../Interfaces/IOncePlugin.sol";

/**
 * @title ONCE -- A base layer for on-chain entities
 * @dev Key concepts
 *  - ONCE takes inspiration from the diamond proxy pattern
 *  - The core contract (along with the default plugins) effectively form a permissioned proxy
 *  - The original vision of ONCE is to create a base layer upon which you can build your organization to evolve over time
 *  - From a technical perspective this means plugins that install the functionality of current popular on-chain entity solutions
 *  
 *  - In the base ONCE storage we keep track of installed plugins and their associated function selectors that can be called
 *  - We then use the fallback function to find and call the plugin. This leverages the same system as the Diamond Proxy Pattern (EIP-2535)
 * 
 *  - By default every ONCE comes with the following plugins which can be uninstalled or upgraded as needed:
 *  -   * PluginManager (uninstalling the PluginManager will make the ONCE immutable)
 *  -   * PluginViewer
 *  -   * AccessControl
 *  - The addresses of these plugins should be passed when constructing a ONCE
 * @author Ketul 'Jay' Patel
**/ 

contract Once { 

    /**
     * @notice Constructor function takes in the addresses of default plugins
     * @param _pluginManager PluginManager address
     * @param _pluginViewer PluginViewer address
     * @param _accessControl AccessControl address
     */
    constructor(address _pluginManager, address _pluginViewer, address _accessControl) payable {        
        OnceStorage._grantRole(OnceStorage.ONCE_UPDATE_ROLE, msg.sender);
        OnceStorage._grantRole(OnceStorage.DEFAULT_ADMIN_ROLE, msg.sender);

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

    /**
     * @dev fallback function finds the appropriate plugin to forward the transaction to and returns result
     */
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
