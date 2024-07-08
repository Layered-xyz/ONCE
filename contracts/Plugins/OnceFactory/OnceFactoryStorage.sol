// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IPluginManager } from "../PluginManager/IPluginManager.sol";

library OnceFactoryStorage {
    struct Store {
        address pluginManagerAddress;
        address pluginViewerAddress;
        address accessControlAddress;
    }

    struct RoleInitializer {
        bytes32 roleToCreate;
        address[] membersToAdd;
        bytes32 roleAdmin;
    }

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