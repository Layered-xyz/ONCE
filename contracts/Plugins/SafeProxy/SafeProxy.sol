// SPDX-License-Identifier: LGPL-3.0-only
/* solhint-disable one-contract-per-file */
pragma solidity >=0.7.0 <0.9.0;

import {IProxy} from './IProxy.sol';
import {IOncePlugin} from '../../Interfaces/IOncePlugin.sol';

/**
 * @title SafeProxy - Safe Proxy Plugin compatible with the ONCE system
 * @dev based on the official Safe Proxy contract found in the safe-smart-account repo https://github.com/safe-global/safe-smart-account
 * @author Ketul "Jay" Patel
 */
contract SafeProxy is IOncePlugin {
    // Singleton always needs to be first declared variable, to ensure that it is at the same location in the contracts to which calls are delegated.
    // To reduce deployment costs this variable is internal and needs to be retrieved via `getStorageAt`
    address internal singleton;
    bytes4[] internal functionSelectors;

    /**
     * @notice Constructor function sets address of singleton contract.
     * @param _singleton Singleton address.
     * @param _functionSelectors The function selectors from the singleton that should be installed on plugin installation
     */
    constructor(address _singleton, bytes4[] memory _functionSelectors) {
        require(_singleton != address(0), "Invalid singleton address provided");
        singleton = _singleton;
        functionSelectors = _functionSelectors;
    }

    /**
     * @inheritdoc IOncePlugin
     */
    function getFunctionSelectors() public view returns (bytes4[] memory) {
        return functionSelectors;
    }

    /**
     * @inheritdoc IOncePlugin
     */
    function getSingletonAddress() public view returns (address) {
        return singleton;
    }
}