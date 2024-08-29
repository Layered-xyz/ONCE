// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ERC20VotesStorage} from "./ERC20VotesStorage.sol";
import {ERC20Lib} from "../ERC20Lib.sol";
import {Checkpoints} from "../../../../Utils/Checkpoints.sol";
import { IOncePluginMod } from '../../../../Interfaces/IOncePluginMod.sol';
import { IOncePlugin } from '../../../../Interfaces/IOncePlugin.sol';

/**
 * @title ERC20Votes
 * @author Ketul 'Jay' Patel
 * @notice The ONCE Plugin for adding voting functionality to a ONCE ERC20 Token.
 * @notice Dependent on the ERC20 ONCE Plugin
 */
contract ERC20Votes is IOncePluginMod {
    /**
     * @dev Error emitted when attempting to exceed the safe supply limit.
     * @param increasedSupply The amount by which the supply would increase.
     * @param cap The maximum supply limit.
     */
    error ERC20ExceededSafeSupply(uint256 increasedSupply, uint256 cap);

    /**
     * @dev Returns the maximum supply of the token as uint208.
     * @return The maximum supply of the token.
     */
    function _maxSupply() internal pure returns (uint256) {
        return type(uint208).max;
    }

    /**
     * @dev _update Mod to handle voting unit transfer and check safe supply.
     * @param from The address from which voting units are transferred.
     * @param to The address to which voting units are transferred.
     * @param value The amount of voting units being transferred.
     */
    function _update(address from, address to, uint256 value) external {
        if (from == address(0)) {
            uint256 maxSupply = _maxSupply();
            uint256 supply = ERC20Lib.store().totalSupply;
            if (supply >= maxSupply) {
                revert ERC20ExceededSafeSupply(supply, maxSupply);
            }
        }
        ERC20VotesStorage._transferVotingUnits(from, to, value);
    }

    /**
     * @dev Returns the number of checkpoints for the given account.
     * @param account The address of the account to query.
     * @return The number of checkpoints for the account.
     */
    function numCheckpoints(address account) public view returns (uint32) {
        return ERC20VotesStorage._numCheckpoints(account);
    }

    /**
     * @dev Returns the checkpoint at a specific position for the given account.
     * @param account The address of the account to query.
     * @param pos The position of the checkpoint to retrieve.
     * @return The checkpoint at the specified position.
     */
    function checkpoints(address account, uint32 pos) public view returns (Checkpoints.Checkpoint208 memory) {
        return ERC20VotesStorage._checkpoints(account, pos);
    }

    /**
     * @dev Delegates votes to the specified account.
     * @param account The address to which votes are delegated.
     */
    function delegate(address account) public {
        ERC20VotesStorage._delegate(msg.sender, account);
    }

    /**
     * @dev Delegates votes using an EIP712 signature.
     * @param delegatee The address to which votes are delegated.
     * @param nonce The nonce associated with the signature.
     * @param expiry The expiration timestamp of the signature.
     * @param v The recovery byte of the signature.
     * @param r The R component of the signature.
     * @param s The S component of the signature.
     */
    function delegateBySignature(address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) public {
        ERC20VotesStorage.delegateBySig( delegatee, nonce, expiry, v, r, s);
    }

    /**
     * @dev Returns the total votes for the given account at a specific timepoint.
     * @param account The address of the account to query.
     * @param timepoint The timepoint at which to retrieve the votes.
     * @return The total votes for the account at the specified timepoint.
     */
    function getPastVotes(address account, uint256 timepoint) public view returns (uint256) {
        return ERC20VotesStorage.getPastVotes(account, timepoint);
    }

    /**
     * @dev Returns the total supply of votes at a specific timepoint.
     * @param timepoint The timepoint at which to retrieve the total supply.
     * @return The total supply of votes at the specified timepoint.
     */
    function getPastTotalSupply(uint256 timepoint) public view returns (uint256) {
        return ERC20VotesStorage.getPastTotalSupply(timepoint);
    }

    /**
     * @dev Returns the current votes for the given account.
     * @param account The address of the account to query.
     * @return The current votes for the account.
     */
    function getVotes(address account) public view returns (uint256) {
        return ERC20VotesStorage.getVotes(account);
    }

    /**
     * @dev Returns the nonce for a given address.
     * @param account The address to query the nonce for.
     * @return The nonce for the given address.
     */
    function nonces(address account) public view returns (uint256) {
        return ERC20VotesStorage.store()._nonces[account];
    }

    /**
     * @dev Returns the EIP712 domain.
     * @return fields The fields of the EIP712 domain.
     * @return name The name of the EIP712 domain.
     * @return version The version of the EIP712 domain.
     * @return chainId The chain ID of the EIP712 domain.
     * @return verifyingContract_ The address of the verifying contract.
     * @return salt The salt of the EIP712 domain.
     * @return extensions The extensions of the EIP712 domain.
     */
    function eip712Domain() public view returns (bytes1 fields, string memory name, string memory version, uint256 chainId, address verifyingContract_, bytes32 salt, uint256[] memory extensions) {
        return ERC20VotesStorage._eip712Domain();
    }

    /**
     * @dev Returns the DOMAIN_SEPARATOR.
     * @return The DOMAIN_SEPARATOR.
     */
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return ERC20VotesStorage.domainSeparator();
    }

    /**
     * @dev Returns the clock time.
     * @return The current clock time.
     */
    function clock() public view returns (uint256) {
        return ERC20VotesStorage.clock();
    }

    /**
     * @dev Returns the clock mode.
     * @return The current clock mode.
     */
    function CLOCK_MODE() public view returns (string memory) {
        return ERC20VotesStorage.CLOCK_MODE();
    }

  /**
     * @dev Retrieves the delegate for the given account.
     * @param account The address of the account.
     * @return address The delegate address.
     */
    function delegates(address account) public view returns (address) {
        return ERC20VotesStorage.delegates(account);
    }

    /**
     * @inheritdoc IOncePlugin
     */
    function getFunctionSelectors() public pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](13);
        selectors[0] = this.numCheckpoints.selector;
        selectors[1] = this.checkpoints.selector;
        selectors[2] = this.delegate.selector;
        selectors[3] = this.delegateBySignature.selector;
        selectors[4] = this.getPastVotes.selector;
        selectors[5] = this.getPastTotalSupply.selector;
        selectors[6] = this.getVotes.selector;
        selectors[7] = this.nonces.selector;
        selectors[8] = this.eip712Domain.selector;
        selectors[9] = this.DOMAIN_SEPARATOR.selector;
        selectors[10] = this.clock.selector;
        selectors[11] = this.CLOCK_MODE.selector;
        selectors[12] = this.delegates.selector;
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