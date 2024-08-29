// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title MetadataStorage -- A storage library for the Metadata plugin
 * @author Ketul 'Jay' Patel
 * @notice MetadataStorage maintains the entityURI
 */
library MetadataStorage {

    bytes32 internal constant ONCE_METADATA_UPDATE_ROLE = keccak256("LAYERED_ONCE_METADATA_UPDATE_ROLE");

    event MetadataUpdated(string newURI, string oldURI);

    /**
     * @dev stores the entityURI
     */
    struct Store {
        string entityURI;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('layered.contracts.storage.MetadataStorage');

    function store() internal pure returns (Store storage s) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }
}