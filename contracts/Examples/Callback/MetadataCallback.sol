// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import {Once} from "../../Base/Once.sol";
import {OnceFactoryStorage} from "../../Plugins/Factories/OnceFactory/OnceFactoryStorage.sol";
import {IOnceDeploymentCallback} from "../../Plugins/Factories/OnceFactory/IOnceDeploymentCallback.sol";
import {IOncePlugin} from "../../Interfaces/IOncePlugin.sol";
import {IAccessControl} from "../../Plugins/Base/AccessControl/IAccessControl.sol";
import {IPluginManager} from "../../Plugins/Base/PluginManager/IPluginManager.sol";
import {MetadataInit} from "../../Plugins/Misc/MetadataInit.sol";

/**
 * @title MetadataCallback
 * @author Ketul 'Jay' Patel
 * @notice Install Metadata via Callback
 */
contract MetadataCallback is IOnceDeploymentCallback {

    address metadataAddress;
    address metadataInitAddress;
    string ipfsHash;

    constructor(address _metadataAddress, address _metadataInitAddress, string memory _ipfsHash) {
        metadataAddress = _metadataAddress;
        metadataInitAddress = _metadataInitAddress;
        ipfsHash = _ipfsHash;
    }
    
    /**
     * @inheritdoc IOnceDeploymentCallback
     */
    function onceDeployed(Once _once, bytes32 _salt, OnceFactoryStorage.RoleInitializer[] calldata rolesToCreate, OnceFactoryStorage.PluginInitializer calldata pluginsToInstall) external {
        _once;
        _salt;
        rolesToCreate;
        pluginsToInstall;

        IOncePlugin(metadataAddress).getFunctionSelectors();
        IPluginManager.UpdateInstruction[] memory _updateInstruction = new IPluginManager.UpdateInstruction[](1);
        _updateInstruction[0] = IPluginManager.UpdateInstruction({
            pluginAddress: metadataAddress, 
            action: IPluginManager.UpdateActionType.Add, 
            functionSelectors: IOncePlugin(metadataAddress).getFunctionSelectors()
        });
        IPluginManager(address(_once)).update(_updateInstruction, metadataInitAddress, abi.encodeWithSelector(MetadataInit.init.selector, ipfsHash));
    }
}