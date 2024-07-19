// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { OnceFactoryStorage } from "./OnceFactoryStorage.sol";
import { Once } from "../../Base/Once.sol";
import { OnceStorage } from "../../Base/OnceStorage.sol";
import {IOnceDeploymentCallback} from "./IOnceDeploymentCallback.sol";
import { IOncePlugin } from "../../Interfaces/IOncePlugin.sol";
import { IAccessControl } from "../AccessControl/IAccessControl.sol";
import { IPluginManager } from "../PluginManager/IPluginManager.sol";
import { AccessControlEnforcer } from "../AccessControl/AccessControlEnforcer.sol";


/**
 * @title Once Factory 
 * @author Ketul 'Jay' Patel
 * @notice A factory for deploying ONCE contracts with counterfactual addresses.
 * @dev We recommend deploying all ONCE contracts using the factory to leverage the Create2 opcode factoring in initialization instructions for your ONCE
 * @dev Since the primary mechanism for deploying a new ONCE is this factory, the ONCE upon which this factory plugin is installed should also be deployed using the Create2 opcode. 
 * @dev Please reach out to info@layered.xyz to request a deployment on a new chain to ensure that ONCE factories can maintain consistent addresses.
 */

contract OnceFactory is IOncePlugin, AccessControlEnforcer {

    /**
     * @notice Event for a new ONCE deployment
     * @param once the deployed ONCE
     */
    event onceDeployment(Once indexed once);
    event updateDefaultPlugin(address newDefaultPluginAddress, address oldDefaultPluginAddress, bytes4 setterCalled);

    /**
     * @notice a function for getting the PluginManager address that is installed by default
     * @return address the PluginManager address
     */
    function getPluginManagerAddress() public view virtual returns (address) {
        return OnceFactoryStorage.store().pluginManagerAddress;
    }

    /**
     * @notice a function for getting the PluginViewer address that is installed by default
     * @return address the PluginViewer address
     */
    function getPluginViewerAddress() public view virtual returns (address) {
        return OnceFactoryStorage.store().pluginViewerAddress;
    }

    /**
     * @notice a function for getting the AccessControl address that is installed by default
     * @return address the AccessControl address
     */
    function getAccessControlAddress() public view virtual returns (address) {
        return OnceFactoryStorage.store().accessControlAddress;
    }

    /**
     * @notice a function for setting the PluginManager address that is installed by default
     * @notice access control is enforced to the ONCE_FACTORY_UPDATE_ROLE
     * @param newPluginManager the address of the new PluginManager
     */
    function setPluginManagerAddress(address newPluginManager) public onlyRole(OnceFactoryStorage.ONCE_FACTORY_UPDATE_ROLE) {
        address oldPluginManager = OnceFactoryStorage.store().pluginManagerAddress;
        OnceFactoryStorage.store().pluginManagerAddress = newPluginManager;
        emit updateDefaultPlugin(newPluginManager, oldPluginManager, this.setPluginManagerAddress.selector);
    }

    /**
     * @notice a function for setting the PluginViewer address that is installed by default
     * @notice access control is enforced to the ONCE_FACTORY_UPDATE_ROLE
     * @param newPluginViewer the address of the new PluginViewer
     */
    function setPluginViewerAddress(address newPluginViewer) public onlyRole(OnceFactoryStorage.ONCE_FACTORY_UPDATE_ROLE) {
        address oldPluginViewer = OnceFactoryStorage.store().pluginViewerAddress;
        OnceFactoryStorage.store().pluginViewerAddress = newPluginViewer;
        emit updateDefaultPlugin(newPluginViewer, oldPluginViewer, this.setPluginViewerAddress.selector);
    }

    /**
     * @notice a function for setting the AccessControl address that is installed by default
     * @notice access control is enforced to the ONCE_FACTORY_UPDATE_ROLE
     * @param newAccessControl the address of the new AccessControl
     */
    function setAccessControlAddress(address newAccessControl) public onlyRole(OnceFactoryStorage.ONCE_FACTORY_UPDATE_ROLE) {
        address oldAccessControl = OnceFactoryStorage.store().accessControlAddress;
        OnceFactoryStorage.store().accessControlAddress = newAccessControl;
        emit updateDefaultPlugin(newAccessControl, oldAccessControl, this.setAccessControlAddress.selector);
    }

    /**
     * @notice Internal function for deploying ONCE
     * @param _salt salt for create2 deployment
     * @param rolesToCreate a list of roles to create during initialization
     * @param pluginsToInstall a list of plugins to install during initialization
     * @dev When deploying the Once, the sender is set to the OnceFactory to facilitate initialization.
     */
    function _deployOnce(bytes32 _salt, OnceFactoryStorage.RoleInitializer[] calldata rolesToCreate, OnceFactoryStorage.PluginInitializer calldata pluginsToInstall) internal returns (Once once) {

        bytes memory deploymentData = abi.encodePacked(type(Once).creationCode, uint256(uint160(address(this))), uint256(uint160(OnceFactoryStorage.store().pluginManagerAddress)), uint256(uint160(OnceFactoryStorage.store().pluginViewerAddress)), uint256(uint160(OnceFactoryStorage.store().accessControlAddress)));
        /* solhint-disable no-inline-assembly */
        /// @solidity memory-safe-assembly
        assembly {
            once := create2(0x0, add(0x20, deploymentData), mload(deploymentData), _salt)
        }
        /* solhint-enable no-inline-assembly */
        require(address(once) != address(0), "Create2 failed for once deployment"); 
        
        initializeOnce(address(once), rolesToCreate, pluginsToInstall);
        
        
    }

    /**
     * @notice Internal function for initializing ONCE
     * @param once new ONCE to initialize
     * @param rolesToCreate a list of roles to assign
     * @param pluginsToInstall a list of plugins to install
     * @dev as part of initialization the ONCE factory will renounce its access control roles
     */
    function initializeOnce(address once, OnceFactoryStorage.RoleInitializer[] calldata rolesToCreate, OnceFactoryStorage.PluginInitializer calldata pluginsToInstall) internal {
        require(rolesToCreate.length > 0, "Access control roles must be supplied");
        


        for(uint i = 0; i < rolesToCreate.length; i++) {
            for(uint j = 0; j < rolesToCreate[i].membersToAdd.length; j++) {
                IAccessControl(once).grantRole(rolesToCreate[i].roleToCreate, rolesToCreate[i].membersToAdd[j]);
            }
            IAccessControl(once).setRoleAdmin(rolesToCreate[i].roleToCreate, rolesToCreate[i].roleAdmin);
        }

        IPluginManager(once).update(pluginsToInstall.initialUpdateInstructions, pluginsToInstall.pluginInitializer, pluginsToInstall.pluginInitializerCallData);

        IAccessControl(once).renounceRole(OnceStorage.ONCE_UPDATE_ROLE);
        IAccessControl(once).renounceRole(OnceStorage.DEFAULT_ADMIN_ROLE);
    }

    /**
     * @notice A function for deploying a new ONCE using initialization data to generate the salt used during deployment 
     * @param _salt the base salt used in deployment
     * @param rolesToCreate a list of roles to create during initialization 
     * @param pluginsToInstall a list of plugins to install during initialization
     * @param _callback an optional callback contract that can be used to perform operations post initialization. Must support the IOnceDeploymentCallback interface.
     * @dev While the rolesToCreate and the pluginsToInstall are factored into the salt used in the create2 deployment, the callback is not. This allows for potentially different callbacks to be used across different chains for the same ONCE address. 
     */
    function deployOnce(bytes32 _salt, OnceFactoryStorage.RoleInitializer[] calldata rolesToCreate, OnceFactoryStorage.PluginInitializer calldata pluginsToInstall, IOnceDeploymentCallback _callback) public returns (Once once) {
        bytes32 salt = keccak256(abi.encode(rolesToCreate, pluginsToInstall, _salt));
        once = _deployOnce(salt, rolesToCreate, pluginsToInstall);
        emit onceDeployment(once);
        if (address(_callback) != address(0)) {
            _callback.onceDeployed(once, _salt, rolesToCreate, pluginsToInstall);
        }
    }

    /**
     * @notice Counterfactually generate an address for a ONCE prior to deployment
     * @param sender the deployer, when using a factory this should be the OnceFactory address
     * @param _salt the salt to be used in deployment
     * @param rolesToCreate the list of roles to create during initialization 
     * @param pluginsToInstall the list of plugins to install during initialization
     */
    function getOnceAddress(address sender, bytes32 _salt, OnceFactoryStorage.RoleInitializer[] calldata rolesToCreate, OnceFactoryStorage.PluginInitializer calldata pluginsToInstall) public view returns (address) {
        bytes32 salt = keccak256(abi.encode(rolesToCreate, pluginsToInstall, _salt));
        bytes memory deploymentData = abi.encodePacked(type(Once).creationCode, uint256(uint160(address(this))), uint256(uint160(OnceFactoryStorage.store().pluginManagerAddress)), uint256(uint160(OnceFactoryStorage.store().pluginViewerAddress)), uint256(uint160(OnceFactoryStorage.store().accessControlAddress)));

        bytes32 computedHash = keccak256(
            abi.encodePacked(
                bytes1(0xFF), sender, salt, keccak256(deploymentData)
            )
        );

        return address(uint160(uint256(computedHash)));

    }

    /**
     * @notice Counterfactually generate an address for a ONCE deployed using a simple salt (not including initializatin data)
     * @param sender the deployer, when using a factory this should be the OnceFactory address
     * @param _salt the salt to be used in deployment
     */
    function getOnceSimpleAddressWithSimpleSalt(address sender, bytes32 _salt) public view returns (address) {
        bytes memory deploymentData = abi.encodePacked(type(Once).creationCode, uint256(uint160(address(this))), uint256(uint160(OnceFactoryStorage.store().pluginManagerAddress)), uint256(uint160(OnceFactoryStorage.store().pluginViewerAddress)), uint256(uint160(OnceFactoryStorage.store().accessControlAddress)));

        bytes32 computedHash = keccak256(
            abi.encodePacked(
                bytes1(0xFF), sender, keccak256(abi.encode(sender, _salt)), keccak256(deploymentData)
            )
        );

        return address(uint160(uint256(computedHash)));

    }

    /**
     * @notice A function for deploying a new ONCE using just the provided salt during deployment 
     * @param _salt the salt used in deployment
     * @param rolesToCreate a list of roles to create during initialization 
     * @param pluginsToInstall a list of plugins to install during initialization
     * @param _callback an optional callback contract that can be used to perform operations post initialization. Must support the IOnceDeploymentCallback interface.
     * @dev Since the rolesToCreate and the pluginsToInstall are not factored into the salt, deploying with a simple salt is potentially more vulnerable than using the preferred deployOnce function.
     */
    function deployOnceWithSimpleSalt(bytes32 _salt, OnceFactoryStorage.RoleInitializer[] calldata rolesToCreate, OnceFactoryStorage.PluginInitializer calldata pluginsToInstall, IOnceDeploymentCallback _callback) public returns (Once once) {
        once = _deployOnce(keccak256(abi.encode(msg.sender,_salt)), rolesToCreate, pluginsToInstall);
        emit onceDeployment(once);
        if (address(_callback) != address(0)) {
            _callback.onceDeployed(once, _salt, rolesToCreate, pluginsToInstall);
        }
    }

    /**
     * @inheritdoc IOncePlugin
     */
    function getFunctionSelectors() public pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](10);
        selectors[0] = this.deployOnce.selector;
        selectors[1] = this.deployOnceWithSimpleSalt.selector;
        selectors[2] = this.getPluginManagerAddress.selector;
        selectors[3] = this.getPluginViewerAddress.selector;
        selectors[4] = this.getAccessControlAddress.selector;
        selectors[5] = this.setPluginManagerAddress.selector;
        selectors[6] = this.setPluginViewerAddress.selector;
        selectors[7] = this.setAccessControlAddress.selector;
        selectors[8] = this.getOnceAddress.selector;
        selectors[9] = this.getOnceSimpleAddressWithSimpleSalt.selector;
        return selectors;
    }

    /**
     * @inheritdoc IOncePlugin
     */
    function getSingletonAddress() public view returns (address) {
        return address(this);
    }

}