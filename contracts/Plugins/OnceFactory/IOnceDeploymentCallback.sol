// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import {Once} from "../../Base/Once.sol";
import {OnceFactoryStorage} from "./OnceFactoryStorage.sol";

interface IOnceDeploymentCallback {
    function onceDeployed(Once _once, bytes32 _salt, OnceFactoryStorage.RoleInitializer[] calldata rolesToCreate, OnceFactoryStorage.PluginInitializer calldata pluginsToInstall) external;
}