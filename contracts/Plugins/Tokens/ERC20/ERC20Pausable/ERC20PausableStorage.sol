// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC20PausableStorage
 * @dev Library to manage the storage of the paused state for an ERC20 token.
 * This library is used to encapsulate the storage layout and provide utility functions
 * for accessing and modifying the paused state of an ERC20 token contract.
 */
library ERC20PausableStorage {
    /**
     * @dev Struct to store the paused state.
     * The `paused` boolean indicates whether the ERC20 token contract is paused.
     */
    struct Store {
        bool paused;
    }

    /**
     * @dev Storage slot for the paused state.
     * This is a unique identifier for the storage location of the paused state within the contract.
     */
    bytes32 internal constant STORAGE_SLOT =
        keccak256('layered.contracts.storage.pausable');

    /**
     * @notice Retrieves the storage location for the paused state.
     * @dev Uses inline assembly to set the storage slot for the `Store` struct.
     * @return s The storage reference to the `Store` struct.
     */
    function store() internal pure returns (Store storage s) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }
}