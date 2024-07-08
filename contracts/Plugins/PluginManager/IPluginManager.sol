// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPluginManager {
    enum UpdateActionType {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct UpdateInstruction {
        address pluginAddress;
        UpdateActionType action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _updateInstructions Contains the plugin addresses and function selectors
    /// @param _init The address of the contract or plugin to execute _calldata upon update
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init address
    function update(
        UpdateInstruction[] calldata _updateInstructions,
        address _init,
        bytes calldata _calldata
    ) external;
}
