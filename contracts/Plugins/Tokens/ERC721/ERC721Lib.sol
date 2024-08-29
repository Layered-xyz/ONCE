// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;


import {IERC721Errors} from "../../../Utils/draft-IERC6093.sol";
import {Strings} from "../../../Utils/Strings.sol";
import {IERC721Receiver} from "./interfaces/IERC721Receiver.sol";
import {IERC4906} from "./interfaces/IERC4906.sol";

/**
 * @title ERC721Lib
 * @dev Library containing the core logic for ERC721 token functionality.
 */
library ERC721Lib {
   
    struct Store {
        // Modifiable Plugin
        mapping(bytes4 => address[]) mods; // Mapping of mod addresses by function selector
        // ERC721 Core
        mapping(address => uint256) balances; // Mapping of token balances by address
        string name; // Token name
        string symbol; // Token symbol
        string baseURI; // Base URI for token metadata
        uint8 decimals; // Number of decimals
        mapping(uint256 tokenId => address) owner;
        mapping(uint256 => address) tokenApprovals;
        mapping(address => mapping(address => bool)) operatorApprovals;
        mapping (uint256 tokenId => string) tokenURIs;
        // ERC721 Enumerable 
        mapping(address owner => mapping(uint256 index => uint256)) _ownedTokens;
        mapping(uint256 tokenId => uint256) _ownedTokensIndex;
        uint256[] _allTokens;
        mapping(uint256 tokenId => uint256) _allTokensIndex;
    }
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event ModRemoved(bytes4 indexed selector, address mod);

    /**
     * @dev This event emits when the metadata of a token is changed.
     * So that the third-party platforms such as NFT market could
     * timely update the images and related attributes of the NFT.
     */
    event MetadataUpdate(uint256 _tokenId);

    /**
     * @dev This event emits when the metadata of a range of tokens is changed.
     * So that the third-party platforms such as NFT market could
     * timely update the images and related attributes of the NFTs.
     */ 
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    /**
     * @dev An `owner`'s token query was out of bounds for `index`.
     *
     * NOTE: The owner being `address(0)` indicates a global out of bounds index.
     */
    error ERC721OutOfBoundsIndex(address owner, uint256 index);

    /**
     * @dev Batch mint is not allowed.
     */
    error ERC721EnumerableForbiddenBatchMint();


    bytes32 internal constant STORAGE_SLOT = keccak256("layered.contracts.lib.ERC721");

    /**
     * @dev Get the ERC20 token state variables.
     * @return s The ERC20 token state variables.
     */
    function store() internal pure returns (Store storage s) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }

    /**
     * @param tokenId The token ID to check ownership of.
     */
    function _ownerOf(uint256 tokenId) internal view returns (address) {
        address owner = store().owner[tokenId];
        return owner;
    }

    /**
     * @dev Updates the ownership of a token.
     * @param to The address to transfer ownership to.
     * @param tokenId The ID of the token to update.
     * @param auth The authorized address performing the update.
     * @return The previous owner of the token.
     */
    function _update(address to, uint256 tokenId, address auth) internal returns (address) {
        Store storage s = store();
        bytes4 modSelector = bytes4(keccak256(bytes("_update(address,uint256,address)")));

        for (uint i = 0; i < s.mods[modSelector].length; i++) {
            (bool success, bytes memory returndata) = s.mods[modSelector][i].delegatecall(
                abi.encodeWithSelector(modSelector, to, tokenId, auth)
            );
            if (!success) {
                if (returndata.length > 0) {
                    assembly {
                        let returndata_size := mload(returndata)
                        revert(add(32, returndata), returndata_size)
                    }
                } else {
                    revert("Function call reverted");
                }
            }
        }

        address from = _ownerOf(tokenId);

        // Perform (optional) operator check
        if (auth != address(0)) {
            _checkAuthorized(from, auth, tokenId);
        }
        // Execute the update
        if (from != address(0)) {
            // Clear approval. No need to re-authorize or emit the Approval event
            _approve(address(0), tokenId, address(0), false);

            unchecked {
                s.balances[from] -= 1;
            }
        }

        if (to != address(0)) {
            unchecked {
                s.balances[to] += 1;
            }
        }

        // ERC721 Enumerable
        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }

        s.owner[tokenId] = to;

        emit Transfer(from, to, tokenId);

        return from;
    }

    /**
     * @dev Checks if the spender is authorized to manage the token.
     * @param owner The owner of the token.
     * @param spender The address attempting to spend the token.
     * @param tokenId The ID of the token.
     */
    function _checkAuthorized(address owner, address spender, uint256 tokenId) internal view {
        if (!(spender != address(0) && (owner == spender || _isApprovedForAll(owner, spender) || _getApproved(tokenId) == spender))) {
            if (owner == address(0)) {
                revert IERC721Errors.ERC721NonexistentToken(tokenId);
            } else {
                revert IERC721Errors.ERC721InsufficientApproval(spender, tokenId);
            }
        }
    }

    /**
     * @dev Gets the address approved to manage the token.
     * @param tokenId The ID of the token.
     * @return The address approved to manage the token.
     */
    function _getApproved(uint256 tokenId) internal view returns (address) {
        return store().tokenApprovals[tokenId];
    }


    /**
     * @dev Checks if an address is approved to manage all tokens for another address.
     * @param owner The owner of the tokens.
     * @param operator The address to check approval for.
     * @return True if the address is approved to manage all tokens for another address, false otherwise.
     */
    function _isApprovedForAll(address owner, address operator) internal view returns (bool) {
        return store().operatorApprovals[owner][operator];
    }

    /**
     * @dev Approves an address to manage a token.
     * @param to The address to approve for managing the token.
     * @param tokenId The ID of the token.
     * @param auth The authorized address performing the approval.
     * @param emitEvent Boolean indicating whether to emit an Approval event.
     */
    function _approve(address to, uint256 tokenId, address auth, bool emitEvent) internal {
        // Avoid reading the owner unless necessary
        if (emitEvent || auth != address(0)) {
            address owner = _ownerOf(tokenId);

            if (auth != address(0) && owner != auth && !_isApprovedForAll(owner, auth)) {
                revert IERC721Errors.ERC721InvalidApprover(auth);
            }

            if (emitEvent) {
                emit Approval(owner, to, tokenId);
            }
        }

        store().tokenApprovals[tokenId] = to;
    }

    /**
     * @dev Gets the balance of a given address.
     * @param owner The address to get the balance for.
     * @return The balance of the given address.
     */
    function _balanceOf(address owner) internal view returns (uint256) {
        if (owner == address(0)) {
            revert IERC721Errors.ERC721InvalidOwner(address(0));
        }
        return store().balances[owner];
    }
    /**
     * @dev Transfers ownership of a token.
     * @param from The current owner of the token.
     * @param to The address to transfer ownership to.
     * @param tokenId The ID of the token to transfer.
     */
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        if (to == address(0)) {
            revert IERC721Errors.ERC721InvalidReceiver(address(0));
        }

        address previousOwner = _ownerOf(tokenId);
        if (previousOwner != from) {
            revert IERC721Errors.ERC721IncorrectOwner(from, tokenId, previousOwner);
        }
        _update(to, tokenId, from);
    }
    /**
     * @dev Safely transfers ownership of a token.
     * @param from The current owner of the token.
     * @param to The address to transfer ownership to.
     * @param tokenId The ID of the token to transfer.
     * @param data Additional data to send along with the transfer.
     */
    function _safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) internal {
        _transferFrom(from, to, tokenId);
        _checkOnERC721Received(msg.sender, from, to, tokenId, data);
    }
    /**
     * @dev Mints a new token and assigns it to an address.
     * @param to The address to assign the newly minted token to.
     * @param tokenId The ID of the token to mint.
     */
    function _mint(address to, uint256 tokenId) internal {
    if (to == address(0)) {
        revert IERC721Errors.ERC721InvalidReceiver(address(0));
    }

    
    if (store().owner[tokenId] != address(0)) {
        revert IERC721Errors.ERC721InvalidSender(address(0)); // Assuming there is a custom error for an already existing token
    }

    _update(to, tokenId, address(0));
}
    /**
     * @dev Safely mints a new token and assigns it to an address.
     * @param to The address to assign the newly minted token to.
     * @param tokenId The ID of the token to mint.
     * @param data Additional data to send along with the minting.
    */
    function _safeMint(address to, uint256 tokenId, bytes memory data) internal {
        _mint(to, tokenId);
        _checkOnERC721Received(msg.sender, address(0), to, tokenId, data);
    }
    /**
     * @dev Burns a token.
     * @param tokenId The ID of the token to burn.
     */
    function _burn(uint256 tokenId) internal {
        _ownerOf(tokenId);
        _update(address(0), tokenId, address(0));
    }

    /**
     * @dev Transfers a token.
     * @param from The current owner of the token.
     * @param to The address to transfer the token to.
     * @param tokenId The ID of the token to transfer.
     */
    function _transfer (address from, address to, uint256 tokenId) internal {
        if (to == address(0)) {
            revert IERC721Errors.ERC721InvalidReceiver(address(0));
        }

        address previousOwner = _ownerOf(tokenId);
        if (previousOwner != from) {
            revert IERC721Errors.ERC721IncorrectOwner(from, tokenId, previousOwner);
        }
        _update(to, tokenId, from);
    }
    /**
     * @dev Safely transfers a token.
     * @param from The current owner of the token.
     * @param to The address to transfer the token to.
     * @param tokenId The ID of the token to transfer.
     * @param data Additional data to send along with the transfer.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal {
        _transfer(from, to, tokenId);
        _checkOnERC721Received(msg.sender, from, to, tokenId, data);
    }
    /**
     * @dev Retrieves the token URI for a given token ID.
     * @param tokenId The ID of the token.
     * @return The URI of the token.
     */
    function _tokenURI(uint256 tokenId) internal view returns (string memory) {
        _ownerOf(tokenId);
        string memory _baseURI = store().baseURI;
        string memory _tokenURIForId = store().tokenURIs[tokenId];

        // If there is no base URI, return the token URI.
        if (bytes(_baseURI).length == 0) {
            return _tokenURIForId;
        }
        // If both are set, concatenate the _baseURI and tokenURI (via string.concat).
        if (bytes(_tokenURIForId).length > 0) {
            return string.concat(_baseURI, _tokenURIForId);
        }

        // if _baseURI is set but _tokenURIForId is not return _baseURI and tokenID (via string.concat)
        return string.concat(_baseURI, Strings.toString(tokenId));
    }
    
    function _setTokenURI(uint256 tokenId, string memory _tokenURIForId) internal {
        store().tokenURIs[tokenId] = _tokenURIForId;
        emit MetadataUpdate(tokenId);
    }

    function _setBaseURI(string memory _newBaseURI, uint256 from, uint256 to) internal {
        store().baseURI = _newBaseURI;
        emit BatchMetadataUpdate(from, to); // when using _setBaseURI it is important to set descriptive from and to values to illustrate that all tokenIds have been updated.
    }

     /**
     * @dev Sets or unsets the approval for all tokens for a given operator.
     * @param owner The owner of the tokens.
     * @param operator The operator to set the approval for.
     * @param approved The approval status to set.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal {
        if(operator == address(0)) {
            revert IERC721Errors.ERC721InvalidOperator(address(0));
        }
        store().operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Checks if the receiver contract implements ERC721Receiver.
     * @param sender The sender of the token.
     * @param from The previous owner of the token.
     * @param to The new owner of the token.
     * @param tokenId The ID of the token.
     * @param data Additional data sent with the transfer.
     */
     function _checkOnERC721Received (address sender, address from, address to, uint256 tokenId, bytes memory data) internal {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(sender, from, tokenId, data) returns (bytes4 retval) {
                if (retval != IERC721Receiver.onERC721Received.selector) {
                    revert IERC721Errors.ERC721InvalidReceiver(to);
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert IERC721Errors.ERC721InvalidReceiver(to);
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = _balanceOf(to) - 1;
        store()._ownedTokens[to][length] = tokenId;
        store()._ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        store()._allTokensIndex[tokenId] = store()._allTokens.length;
        store()._allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _balanceOf(from);
        uint256 tokenIndex = store()._ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = store()._ownedTokens[from][lastTokenIndex];

            store()._ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            store()._ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete store()._ownedTokensIndex[tokenId];
        delete store()._ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = store()._allTokens.length - 1;
        uint256 tokenIndex = store()._allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = store()._allTokens[lastTokenIndex];

        store()._allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        store()._allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete store()._allTokensIndex[tokenId];
        store()._allTokens.pop();
    }
    
}
