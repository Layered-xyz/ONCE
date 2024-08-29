// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "../ERC20.sol";
import {AccessControlEnforcer} from "../../../Base/AccessControl/AccessControlEnforcer.sol";
import {ERC20Lib} from "../ERC20Lib.sol";
import {ERC20PausableStorage} from "./ERC20PausableStorage.sol";
import { IOncePluginMod } from '../../../../Interfaces/IOncePluginMod.sol';
import { IOncePlugin } from '../../../../Interfaces/IOncePlugin.sol';

/**
 * @title ERC20Pausable
 * @author Ketul 'Jay' Patel
 * @notice The ONCE Plugin for adding pausable functionality to a ONCE ERC20 Token.
 * @notice Dependent on the ERC20 ONCE Plugin
 * @dev When paused, all updates on the ERC20 token are paused (mints, burns, and transfers). 
 */
contract ERC20Pausable is AccessControlEnforcer, IOncePluginMod {
    bytes32 public constant ERC20_PAUSER_ROLE = keccak256("LAYERED_ERC20_PAUSER_ROLE");

    /**
     * @dev Emitted when the contract is paused by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the contract is unpaused by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev Thrown when a function is called while the contract is paused.
     */
    error ContractPaused();

  

    /**
     * @notice Returns the current paused state of the contract.
     * @return bool True if the contract is paused, false otherwise.
     */
    function paused() public view returns (bool) {
        return ERC20PausableStorage.store().paused;
    }

    /**
     * @notice pauses the contract.
     * @dev Can only be called by an account with the `ERC20_PAUSER_ROLE`.
     * Emits a {Paused} or {Unpaused} event.
     */
    function pause() public onlyRole(ERC20_PAUSER_ROLE) {
        ERC20PausableStorage.Store storage s = ERC20PausableStorage.store();
     
            s.paused = true;
            emit Paused(msg.sender);
        
    }

       /**
     * @notice unpauses the contract.
     * @dev Can only be called by an account with the `ERC20_PAUSER_ROLE`.
     * Emits a {Paused} or {Unpaused} event.
     */
    function unPause() public onlyRole(ERC20_PAUSER_ROLE) {
        ERC20PausableStorage.Store storage s = ERC20PausableStorage.store();
     
            s.paused = false;
            emit Paused(msg.sender);
        
    }

    /**
     * @notice Middleware function to enforce pause status on token transfers.
     * @dev This function should be called before executing transfer logic to ensure that
     * the contract is not paused.
     *
     * Requirements:
     * - The contract must not be paused.
     *
     * @param from Address sending the tokens (unused).
     * @param to Address receiving the tokens (unused).
     * @param value Amount of tokens being transferred (unused).
     */
    function _update(address from, address to, uint256 value) external view {
        from; // Unused parameter
        to; // Unused parameter
        value; // Unused parameter
        if (paused()) {
            revert ContractPaused();
        }
    }

    /**
     * @inheritdoc IOncePlugin
     */
    function getFunctionSelectors() public pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = this.paused.selector;
        selectors[1] = this.pause.selector;
        selectors[2] = this.unPause.selector;
        return selectors;
    }

    /**
     * @inheritdoc IOncePlugin
     */
    function getSingletonAddress() public view returns (address) {
        return address(this);
    } 

    
    function getModSelectors() public pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = this._update.selector;
        return selectors;
    }
}