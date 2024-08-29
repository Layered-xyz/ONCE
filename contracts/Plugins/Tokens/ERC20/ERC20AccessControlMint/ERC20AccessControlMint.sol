// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20 } from '../ERC20.sol';
import { AccessControlEnforcer } from '../../../Base/AccessControl/AccessControlEnforcer.sol';
import { ERC20Lib } from "../ERC20Lib.sol";
import { IOncePlugin } from "../../../../Interfaces/IOncePlugin.sol";

/**
 * @title ERC20AccessControlMint
 * @author Ketul 'Jay' Patel
 * @notice The ONCE Plugin for adding access control based mint functionality to a ONCE ERC20 Token.
 * @notice Dependent on the ERC20 ONCE Plugin
 * @dev Access control based minting is useful for cases where tokens are not purchased but are earned or distributed. 
 * @dev Access control minting can also be paired with the AutomaTD system for automatically minting tokens to recipient addresses for specified actions
 */
contract ERC20AccessControlMint is AccessControlEnforcer, IOncePlugin {

    bytes32 public constant ERC20_MINTER_ROLE = keccak256("LAYERED_ONCE_ERC20_MINTER_ROLE");

    function mint(address account, uint256 amount) external onlyRole(ERC20_MINTER_ROLE) {
        ERC20Lib._mint(account, amount);
    }

    /**
     * @inheritdoc IOncePlugin
     */
    function getFunctionSelectors() public pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = this.mint.selector;
        return selectors;
    }

    /**
     * @inheritdoc IOncePlugin
     */
    function getSingletonAddress() public view returns (address) {
        return address(this);
    } 

}