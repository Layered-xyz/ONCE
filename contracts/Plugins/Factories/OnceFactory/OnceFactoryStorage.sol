// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IPluginManager } from "../../Base/PluginManager/IPluginManager.sol";

/**
 * @title OnceFactoryStorage -- A storage library for the ONCE factory plugin
 * @author Ketul 'Jay' Patel
 * @notice OnceFactoryStorage maintains the associated default plugin addresses used when deploying via the OnceFactory
 */
library OnceFactoryStorage {

    bytes32 internal constant ONCE_FACTORY_UPDATE_ROLE = keccak256("LAYERED_ONCE_FACTORY_UPDATE_ROLE");

    /**
     * @dev stores the 3 default plugin addresses -- PluginManager, PluginViewer, AccessControl
     */
    struct Store {
        address pluginManagerAddress;
        address pluginViewerAddress;
        address accessControlAddress;
    }

    /**
     * @dev the struct used by the OnceFactory when initializing roles during the deployment process
     */
    struct RoleInitializer {
        bytes32 roleToCreate;
        address[] membersToAdd;
        bytes32 roleAdmin;
    }

    /**
     * @dev the struct used by the OnceFactory when initializing plugins during the deployment process
     */
    struct PluginInitializer {
        IPluginManager.UpdateInstruction[] initialUpdateInstructions;
        address pluginInitializer;
        bytes pluginInitializerCallData;
    }  

    bytes32 internal constant STORAGE_SLOT =
        keccak256('layered.contracts.storage.OnceFactory');

    function store() internal pure returns (Store storage s) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }
}