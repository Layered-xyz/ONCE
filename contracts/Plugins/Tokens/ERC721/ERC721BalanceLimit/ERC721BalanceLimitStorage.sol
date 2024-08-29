// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ERC721BalanceLimitStorage {
    struct Store {
        uint256 limit;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('layered.contracts.storage.ERC721BalanceLimit');

    function store() internal pure returns (Store storage s) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }
}