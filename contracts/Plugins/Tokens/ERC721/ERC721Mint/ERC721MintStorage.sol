// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import {ERC721Lib} from "../ERC721Lib.sol";

/**
 * @title ERC721MintStorage
*/
library ERC721MintStorage {
    struct Store {
        uint256 price;
        string uniformURI;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("layered.contracts.storage.ERC721Mint");

    /**
     * @dev Provides access to the storage struct for the library.
     * @return s Storage struct for ERC721 minting data.
     */
    function store() internal pure returns (Store storage s) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }
}
