// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { OnceFactoryStorage } from "./OnceFactoryStorage.sol";
import { Once } from "../../Base/Once.sol";
import { OnceStorage } from "../../Base/OnceStorage.sol";
import {IOnceDeploymentCallback} from "./IOnceDeploymentCallback.sol";
import { IOncePlugin } from "../../Interfaces/IOncePlugin.sol";
import { IAccessControl } from "../AccessControl/IAccessControl.sol";
import { IPluginManager } from "../PluginManager/IPluginManager.sol";


/**
 * @title Once Factory 
 * @author Jay Patel
 * @notice A factory for deploying ONCE contracts with counterfactual addresses.
 */

contract OnceFactory is IOncePlugin {

    event onceDeployment(Once indexed once);

    function getPluginManagerAddress() public view virtual returns (address) {
        return OnceFactoryStorage.store().pluginManagerAddress;
    }

    function getPluginViewerAddress() public view virtual returns (address) {
        return OnceFactoryStorage.store().pluginViewerAddress;
    }

    function getAccessControlAddress() public view virtual returns (address) {
        return OnceFactoryStorage.store().accessControlAddress;
    }

    function _deployOnce(bytes32 _salt, OnceFactoryStorage.RoleInitializer[] calldata rolesToCreate, OnceFactoryStorage.PluginInitializer calldata pluginsToInstall) internal returns (Once once) {

        bytes memory deploymentData = abi.encodePacked(type(Once).creationCode, uint256(uint160(OnceFactoryStorage.store().pluginManagerAddress)), uint256(uint160(OnceFactoryStorage.store().pluginViewerAddress)), uint256(uint160(OnceFactoryStorage.store().accessControlAddress)));
        /* solhint-disable no-inline-assembly */
        /// @solidity memory-safe-assembly
        assembly {
            once := create2(0x0, add(0x20, deploymentData), mload(deploymentData), _salt)
        }
        /* solhint-enable no-inline-assembly */
        require(address(once) != address(0), "Create2 failed for once deployment"); 
        
        initializeOnce(address(once), rolesToCreate, pluginsToInstall);
        
        
    }

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

    function deployOnce(bytes32 _salt, OnceFactoryStorage.RoleInitializer[] calldata rolesToCreate, OnceFactoryStorage.PluginInitializer calldata pluginsToInstall, IOnceDeploymentCallback _callback) public returns (Once once) {
        bytes32 salt = keccak256(abi.encode(rolesToCreate, pluginsToInstall, _salt));
        once = _deployOnce(salt, rolesToCreate, pluginsToInstall);
        emit onceDeployment(once);
        if (address(_callback) != address(0)) {
            _callback.onceDeployed(once, _salt, rolesToCreate, pluginsToInstall);
        }
    }

    function getOnceAddress(address sender, bytes32 _salt, OnceFactoryStorage.RoleInitializer[] calldata rolesToCreate, OnceFactoryStorage.PluginInitializer calldata pluginsToInstall) public view returns (address) {
        bytes32 salt = keccak256(abi.encode(rolesToCreate, pluginsToInstall, _salt));
        bytes memory deploymentData = abi.encodePacked(type(Once).creationCode, uint256(uint160(OnceFactoryStorage.store().pluginManagerAddress)), uint256(uint160(OnceFactoryStorage.store().pluginViewerAddress)), uint256(uint160(OnceFactoryStorage.store().accessControlAddress)));

        bytes32 computedHash = keccak256(
            abi.encodePacked(
                bytes1(0xFF), sender, salt, keccak256(deploymentData)
            )
        );

        return address(uint160(uint256(computedHash)));

    }

    function getOnceSimpleAddressWithSimpleSalt(address sender, bytes32 _salt) public view returns (address) {
        bytes memory deploymentData = abi.encodePacked(type(Once).creationCode, uint256(uint160(OnceFactoryStorage.store().pluginManagerAddress)), uint256(uint160(OnceFactoryStorage.store().pluginViewerAddress)), uint256(uint160(OnceFactoryStorage.store().accessControlAddress)));

        bytes32 computedHash = keccak256(
            abi.encodePacked(
                bytes1(0xFF), sender, keccak256(abi.encode(sender, _salt)), keccak256(deploymentData)
            )
        );

        return address(uint160(uint256(computedHash)));

    }

    function deployOnceWithSimpleSalt(bytes32 _salt, OnceFactoryStorage.RoleInitializer[] calldata rolesToCreate, OnceFactoryStorage.PluginInitializer calldata pluginsToInstall, IOnceDeploymentCallback _callback) public returns (Once once) {
        once = _deployOnce(keccak256(abi.encode(msg.sender,_salt)), rolesToCreate, pluginsToInstall);
        emit onceDeployment(once);
        if (address(_callback) != address(0)) {
            _callback.onceDeployed(once, _salt, rolesToCreate, pluginsToInstall);
        }
    }

    function getFunctionSelectors() public pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](7);
        selectors[0] = this.deployOnce.selector;
        selectors[1] = this.deployOnceWithSimpleSalt.selector;
        selectors[2] = this.getPluginManagerAddress.selector;
        selectors[3] = this.getPluginViewerAddress.selector;
        selectors[4] = this.getAccessControlAddress.selector;
        selectors[5] = this.getOnceAddress.selector;
        selectors[6] = this.getOnceSimpleAddressWithSimpleSalt.selector;
        return selectors;
    }

    function getSingletonAddress() public view returns (address) {
        return address(this);
    }

}