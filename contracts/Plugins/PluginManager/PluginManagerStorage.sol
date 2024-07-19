// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IPluginManager } from "./IPluginManager.sol";
import { OnceStorage } from "../../Base/OnceStorage.sol";


error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);
/**
 * @title PluginManagerStorage -- A storage/utility library for the Plugin Manager Once plugin
 * @author Ketul 'Jay' Patel
 * @notice This library contains the core functionality used for processing updates via the Plugin Manager "update" function
 * @dev The logic in this contract takes inspiration from Diamond Proxy Pattern implementations shared by Nick Mudge @mudgen
 */
library PluginManagerStorage {

    event OnceUpdate(IPluginManager.UpdateInstruction[] _updateInstructions, address _init, bytes _calldata);
    event OnceUpdateDefault(address newDefaultFallback, address oldDefaultFallback);

    function update(
        IPluginManager.UpdateInstruction[] memory _updateInstructions,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 pluginIndex; pluginIndex < _updateInstructions.length; pluginIndex++) {
            IPluginManager.UpdateActionType action = _updateInstructions[pluginIndex].action;
            if (action == IPluginManager.UpdateActionType.Add) {
                addFunctions(_updateInstructions[pluginIndex].pluginAddress, _updateInstructions[pluginIndex].functionSelectors);
            } else if (action == IPluginManager.UpdateActionType.Replace) {
                replaceFunctions(_updateInstructions[pluginIndex].pluginAddress, _updateInstructions[pluginIndex].functionSelectors);
            } else if (action == IPluginManager.UpdateActionType.Remove) {
                removeFunctions(_updateInstructions[pluginIndex].pluginAddress, _updateInstructions[pluginIndex].functionSelectors);
            } else {
                revert("PluginManager: Incorrect Update Action Type");
            }
        }
        emit OnceUpdate(_updateInstructions, _init, _calldata);
        initializeUpdate(_init, _calldata);
    }

    function updateDefaultFallback(
        address newDefault
    ) internal {
        OnceStorage.Store storage ds = OnceStorage.store();
        address oldDefault = ds.defaultFallback;
        ds.defaultFallback = newDefault;
        emit OnceUpdateDefault(newDefault, oldDefault);
    }

    function addFunctions(address _pluginAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "PluginManager: No selectors in plugin to update");
        OnceStorage.Store storage ds = OnceStorage.store();        
        require(_pluginAddress != address(0), "PluginManager: Add plugin can't be address(0)");
        uint96 selectorPosition = uint96(ds.pluginFunctionSelectors[_pluginAddress].functionSelectors.length);
        if (selectorPosition == 0) {
            addPlugin(ds, _pluginAddress);            
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldPluginAddress = ds.selectorToPluginAndPosition[selector].pluginAddress;
            require(oldPluginAddress == address(0), "PluginManager: Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _pluginAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _pluginAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "PluginManager: No selectors in plugin to update");
        OnceStorage.Store storage ds = OnceStorage.store(); 
        require(_pluginAddress != address(0), "PluginManager: Add plugin can't be address(0)");
        uint96 selectorPosition = uint96(ds.pluginFunctionSelectors[_pluginAddress].functionSelectors.length);
        if (selectorPosition == 0) {
            addPlugin(ds, _pluginAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldPluginAddress = ds.selectorToPluginAndPosition[selector].pluginAddress;
            require(oldPluginAddress != _pluginAddress, "PluginManager: Can't replace function with same function");
            removeFunction(ds, oldPluginAddress, selector);
            addFunction(ds, selector, selectorPosition, _pluginAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address _pluginAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "PluginManager: No selectors in plugin to update");
        OnceStorage.Store storage ds = OnceStorage.store(); 
        require(_pluginAddress == address(0), "PluginManager: Remove plugin address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldPluginAddress = ds.selectorToPluginAndPosition[selector].pluginAddress;
            removeFunction(ds, oldPluginAddress, selector);
        }
    }

    function addPlugin(OnceStorage.Store storage ds, address _pluginAddress) internal {
        enforceHasContractCode(_pluginAddress, "PluginManager: New plugin has no code");
        ds.pluginFunctionSelectors[_pluginAddress].pluginAddressPosition = ds.pluginAddresses.length;
        ds.pluginAddresses.push(_pluginAddress);
    }    


    function addFunction(OnceStorage.Store storage ds, bytes4 _selector, uint96 _selectorPosition, address _pluginAddress) internal {
        ds.selectorToPluginAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.pluginFunctionSelectors[_pluginAddress].functionSelectors.push(_selector);
        ds.selectorToPluginAndPosition[_selector].pluginAddress = _pluginAddress;
    }

    function removeFunction(OnceStorage.Store storage ds, address _pluginAddress, bytes4 _selector) internal {        
        require(_pluginAddress != address(0), "PluginManager: Can't remove function that doesn't exist");
        require(_pluginAddress != address(this), "PluginManager: Can't remove immutable function"); 
        uint256 selectorPosition = ds.selectorToPluginAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.pluginFunctionSelectors[_pluginAddress].functionSelectors.length - 1;
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.pluginFunctionSelectors[_pluginAddress].functionSelectors[lastSelectorPosition];
            ds.pluginFunctionSelectors[_pluginAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToPluginAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        ds.pluginFunctionSelectors[_pluginAddress].functionSelectors.pop();
        delete ds.selectorToPluginAndPosition[_selector];

        if (lastSelectorPosition == 0) {
            uint256 lastPluginAddressPosition = ds.pluginAddresses.length - 1;
            uint256 pluginAddressPosition = ds.pluginFunctionSelectors[_pluginAddress].pluginAddressPosition;
            if (pluginAddressPosition != lastPluginAddressPosition) {
                address lastPluginAddress = ds.pluginAddresses[lastPluginAddressPosition];
                ds.pluginAddresses[pluginAddressPosition] = lastPluginAddress;
                ds.pluginFunctionSelectors[lastPluginAddress].pluginAddressPosition = pluginAddressPosition;
            }
            ds.pluginAddresses.pop();
            delete ds.pluginFunctionSelectors[_pluginAddress].pluginAddressPosition;
        }
    }

    function initializeUpdate(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            return;
        }
        enforceHasContractCode(_init, "PluginManagerStorage: _init address has no code");        
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                // bubble up error
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert InitializationFunctionReverted(_init, _calldata);
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}
