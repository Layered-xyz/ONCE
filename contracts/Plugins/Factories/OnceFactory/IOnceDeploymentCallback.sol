// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import {Once} from "../../../Base/Once.sol";
import {OnceFactoryStorage} from "./OnceFactoryStorage.sol";

/**
 * @title IOnceDeploymentCallback interface
 * @author Ketul 'Jay' Patel
 * @notice an interface for defining a contract that can be used as a callback when deploying a new Once
 */
interface IOnceDeploymentCallback {
    function onceDeployed(Once _once, bytes32 _salt, OnceFactoryStorage.RoleInitializer[] calldata rolesToCreate, OnceFactoryStorage.PluginInitializer calldata pluginsToInstall) external;
}