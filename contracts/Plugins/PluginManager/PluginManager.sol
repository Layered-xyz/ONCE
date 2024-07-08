// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import { IPluginManager } from "./IPluginManager.sol";
import { IOncePlugin } from "../../Interfaces/IOncePlugin.sol";
import { PluginManagerStorage } from "./PluginManagerStorage.sol";
import { OnceStorage } from "../../Base/OnceStorage.sol";


contract PluginManager is IPluginManager, IOncePlugin {

    bytes32 internal constant ONCE_UPDATE_ROLE = keccak256("LAYERED_ONCE_UPDATE_ROLE");
   
    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param updateInstructions Contains the plugin addresses and function selectors
    /// @param init The address of the contract or plugin to execute _calldata upon update
    /// @param initCalldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init address  
    function update(
        UpdateInstruction[] calldata updateInstructions,
        address init,
        bytes calldata initCalldata
    ) external override {
        OnceStorage._checkRole(ONCE_UPDATE_ROLE);
        PluginManagerStorage.update(updateInstructions, init, initCalldata);
    }

    function getFunctionSelectors() public pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = this.update.selector;
        return selectors;
    }
    function getSingletonAddress() public view returns (address) {
        return address(this);
    }
}
