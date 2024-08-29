// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import {ERC721Lib} from "../ERC721Lib.sol";

/**
 * @title ERC721AutoIncrementAccessControlMintStorage
 */
library ERC721AutoIncrementAccessControlMintStorage {
   

    struct Store {
        uint256 nextTokenId;
        uint256 price;
        string uniformURI;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("layered.contracts.storage.ERC721AutoIncrementAccessControlMint");

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

    /**
     * @notice Mints a new ERC721 token and assigns it to `to`.
     * @dev Increments the token ID and uses ERC721Lib to mint the token.
     * @param to Address to which the new token will be minted.
     */
    function autoIncrementSafeMint(address to) internal {
        Store storage s = store();
        s.nextTokenId++;
        ERC721Lib._safeMint(to, s.nextTokenId, "");
        if(bytes(store().uniformURI).length > 0) {
            ERC721Lib._setTokenURI(s.nextTokenId, store().uniformURI);
        }
    }


}
