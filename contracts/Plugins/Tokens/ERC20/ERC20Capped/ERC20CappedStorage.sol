// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ERC20CappedStorage {
    struct Store {
        uint256 cap;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('layered.contracts.storage.capped');

    function store() internal pure returns (Store storage s) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }
}