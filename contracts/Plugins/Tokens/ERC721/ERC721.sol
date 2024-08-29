// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import {IERC721} from "./interfaces/IERC721.sol";
import {IERC721Metadata} from "./interfaces/IERC721Metadata.sol";
import {ERC721Lib} from "./ERC721Lib.sol";
import { IOncePlugin } from "../../../Interfaces/IOncePlugin.sol";


/**
 * @title ERC20
 * @author Ketul 'Jay' Patel
 * @notice The ONCE Plugin for building ERC20 tokens.
 * @dev Based on the OZ ERC20 implementation
 */
contract ERC721 is IERC721, IERC721Metadata, IOncePlugin {
    /**
     * @dev Returns the name of the token.
     * @return The name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return ERC721Lib.store().name;
    }

    /**
     * @dev Returns the symbol of the token.
     * @return The symbol of the token.
     */
    function symbol() public view virtual override returns (string memory) {
        return ERC721Lib.store().symbol;
    }

    /**
     * @dev Returns the token URI for a given token ID.
     * @param tokenId The token ID for which to retrieve the URI.
     * @return The token URI.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return ERC721Lib._tokenURI(tokenId);
    }

    /**
     * @dev Returns the owner of the given token ID.
     * @param tokenId The token ID for which to query the owner.
     * @return The address of the owner of the token.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return ERC721Lib._ownerOf(tokenId);
    }

    /**
     * @dev Returns whether the specified operator is approved to manage all of the caller's assets.
     * @param owner The address of the owner.
     * @param operator The address of the operator.
     * @return True if the operator is approved to manage all of the caller's assets, false otherwise.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return ERC721Lib._isApprovedForAll(owner, operator);
    }
    
    /**
     * @dev Returns the address of the approved account for a given token ID, or zero if no account is approved.
     * @param tokenId The token ID for which to query the approval.
     * @return The address of the approved account, or zero if no account is approved.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        return ERC721Lib._getApproved(tokenId);
    }

    /**
     * @dev Returns the number of tokens owned by the specified address.
     * @param owner The address of the token owner.
     * @return The number of tokens owned by the specified address.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        return ERC721Lib.store().balances[owner];
    }

    /**
     * @dev Transfers ownership of the given token ID to another address.
     * @param from The current owner of the token.
     * @param to The new owner of the token.
     * @param tokenId The token ID to transfer.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        ERC721Lib._transferFrom(from, to, tokenId);
    }

    /**
     * @dev Safely transfers ownership of the given token ID to another address.
     * @param from The current owner of the token.
     * @param to The new owner of the token.
     * @param tokenId The token ID to transfer.
     * @param data Additional data with no specified format, sent in call to `to`.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        ERC721Lib._safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev Sets or unsets the approval of a given operator.
     * @param operator The address of the operator to approve.
     * @param approved True if the operator is approved, false to revoke approval.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        ERC721Lib._setApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev Approves another address to manage the given token ID.
     * @param to The address to grant approval to.
     * @param tokenId The token ID to approve.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        ERC721Lib._approve(to, tokenId, msg.sender, true);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256) {
        if (index >= balanceOf(owner)) {
            revert ERC721Lib.ERC721OutOfBoundsIndex(owner, index);
        }
        return ERC721Lib.store()._ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return ERC721Lib.store()._allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual returns (uint256) {
        if (index >= totalSupply()) {
            revert ERC721Lib.ERC721OutOfBoundsIndex(address(0), index);
        }
        return ERC721Lib.store()._allTokens[index];
    }

    function getModsForSelector(bytes4 selector) public view returns (address[] memory modContracts) {
        modContracts = ERC721Lib.store().mods[selector];
        return modContracts;
    }


    /**
     * @inheritdoc IOncePlugin
     */
    function getFunctionSelectors() public pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](15);
        selectors[0] = this.name.selector;
        selectors[1] = this.symbol.selector;
        selectors[2] = this.tokenURI.selector;
        selectors[3] = this.ownerOf.selector;
        selectors[4] = this.isApprovedForAll.selector;
        selectors[5] = this.getApproved.selector;
        selectors[6] = this.balanceOf.selector;
        selectors[7] = this.transferFrom.selector;
        selectors[8] = this.safeTransferFrom.selector;
        selectors[9] = this.setApprovalForAll.selector;
        selectors[10] = this.approve.selector;
        selectors[11] = this.tokenOfOwnerByIndex.selector;
        selectors[12] = this.totalSupply.selector;
        selectors[13] = this.tokenByIndex.selector;
        selectors[14] = this.getModsForSelector.selector;
        return selectors;
    }

    /**
     * @inheritdoc IOncePlugin
     */
    function getSingletonAddress() public view returns (address) {
        return address(this);
    } 
}
