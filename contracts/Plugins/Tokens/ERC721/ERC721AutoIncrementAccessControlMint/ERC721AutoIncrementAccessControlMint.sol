// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ERC721} from "../ERC721.sol";
import {AccessControlEnforcer} from "../../../Base/AccessControl/AccessControlEnforcer.sol";
import {ERC721AutoIncrementAccessControlMintStorage} from "./ERC721AutoIncrementAccessControlMintStorage.sol";
import { IOncePlugin } from '../../../../Interfaces/IOncePlugin.sol';

/**
 * @title ERC721AutoIncrementAccessControlMint
 * @author Ketul 'Jay' Patel
 * @notice The ONCE Plugin for adding access controlled auto incrementing mint functionality to ERC721 tokens.
 * @notice Dependent on the ERC721 ONCE Plugin
 * @dev Access control minting can also be paired with the AutomaTD system for automatically minting tokens to recipient addresses for specified actions
 */
contract ERC721AutoIncrementAccessControlMint is AccessControlEnforcer, IOncePlugin {
    bytes32 public constant ERC721_MINTER_ROLE = keccak256("LAYERED_ERC721_MINTER_ROLE");

    /**
     * @dev Mints an ERC721 token and assigns it to the specified account.
     * @param to The account to which the tokens will be minted.
     */
    function safeMint(address to) payable external onlyRole(ERC721_MINTER_ROLE) {
        uint256 price = ERC721AutoIncrementAccessControlMintStorage.store().price;
        require(msg.value >= price, "ERC721MintableFacet: Insufficient payment");
        ERC721AutoIncrementAccessControlMintStorage.autoIncrementSafeMint(to);
    }

    /**
     * @inheritdoc IOncePlugin
     */
    function getFunctionSelectors() public pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = this.safeMint.selector;
        return selectors;
    }

    /**
     * @inheritdoc IOncePlugin
     */
    function getSingletonAddress() public view returns (address) {
        return address(this);
    } 
}
