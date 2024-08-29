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
 * @title CallbackExample
 * @author Ketul 'Jay' Patel
 * @notice An example/starter for building a custom deployment callback used by the OnceFactory
 * @dev When using the OnceFactory this callback will be granted both the ONCE_UPDATE_ROLE and the DEFAULT_ADMIN_ROLE
 *      which means you can grant roles and install plugins via this callback *that will not be factored into the ONCE counterfactual address*
 * 
 * 
 *      This functionality allows for interesting use cases where a ONCE deployed across multiple chains can have behavior & capabilities 
 *      unique to each chain. See docs for example use cases of this functionality. 
 */
contract CallbackExample is IOnceDeploymentCallback {
    
    /**
     * @inheritdoc IOnceDeploymentCallback
     */
    function onceDeployed(Once _once, bytes32 _salt, OnceFactoryStorage.RoleInitializer[] calldata rolesToCreate, OnceFactoryStorage.PluginInitializer calldata pluginsToInstall) external {
        _once;
        _salt;
        rolesToCreate;
        pluginsToInstall;

        /* We recommend creating callback contracts as single use contracts -- hence data such as plugin addresses & roles
           can and should be hardcoded into the onceDeployed function for use on the onceDeployment
        */ 

        
        // Grant roles 
        IAccessControl(address(_once)).grantRole(keccak256("THE_CHOSEN_ONE"), 0x0000000000000000000000000000000000000000);

        // Install Plugins
        // ie. install the metadata plugin
        // PluginManager

        address _pluginAddress = 0x18F7bafa8898C844Ea1Fb9df1D451f0B8Ba61dc1;
        address _initAddress = 0x7395A9C4DDed2bce32E514B08D013EDa57df4d5E;
        IOncePlugin(_pluginAddress).getFunctionSelectors();
        IPluginManager.UpdateInstruction[] memory _updateInstruction = new IPluginManager.UpdateInstruction[](1);
        _updateInstruction[0] = IPluginManager.UpdateInstruction({
            pluginAddress: _pluginAddress, 
            action: IPluginManager.UpdateActionType.Add, 
            functionSelectors: IOncePlugin(_pluginAddress).getFunctionSelectors()
        });
        IPluginManager(address(_once)).update(_updateInstruction, _initAddress, abi.encodeWithSelector(MetadataInit.init.selector, 'ipfs://SomeExampleHash'));
    }
}