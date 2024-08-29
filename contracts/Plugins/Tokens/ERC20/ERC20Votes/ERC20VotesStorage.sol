// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Checkpoints} from "../../../../Utils/Checkpoints.sol";
import {ECDSA} from "../../../../Utils/ECDSA.sol";
import {EIP712Lib} from "../../../../Utils/EIP712Lib.sol";
import {ERC20Lib} from "../ERC20Lib.sol";



/**
 * @title ERC20VotesStorage
 * @dev This library provides storage and utility functions for managing voting-related data in ERC20 contracts.
 */
library ERC20VotesStorage {
    // Struct containing storage variables related to voting
    struct Store {
        mapping(address => address) _delegatee; // Mapping of delegators to their respective delegates
        mapping(address => Checkpoints.Trace208) _delegateCheckpoints; // Mapping of addresses to their respective vote checkpoints
        Checkpoints.Trace208 _totalCheckpoints; // Checkpoints for total votes
        EIP712Lib.EIP712Domain eip712Domain; // EIP712 domain data
        mapping(address => uint256) _nonces; // Nonces for managing delegated voting
        bool timestamp;
        address verifyingContract;
    }

    // Error thrown when a signature for voting has expired
    error VotesExpiredSignature(uint256 expiry);
    // Error thrown when downcasting from uint256 to a smaller uint type results in overflow
    error OverflowedUintDowncast(uint8 bits, uint256 value);
    // Error thrown when the clock is inconsistent in the ERC6372 standard
    error ERC6372InconsistentClock();
    // Error thrown when looking up a future timepoint in ERC5805
    error ERC5805FutureLookup(uint256 timepoint, uint48 clock);

    error InvalidNonce(uint256 expected, uint256 provided);

    // Event emitted when a delegate is changed
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    // Event emitted when delegate votes are changed
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    // Keccak256 hash of the delegation type data
    bytes32 private constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");
    // Storage slot for the ERC20VotesStorage
    bytes32 internal constant STORAGE_SLOT = keccak256("layered.contracts.storage.votes");

    /**
     * @dev Retrieves the storage slot for ERC20VotesStorage.
     * @return s The storage struct containing voting-related data.
     */
    function store() internal pure returns (Store storage s) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }

    /**
     * @dev Initializes the EIP712 domain with the provided name and version.
     * @param s The storage struct containing voting-related data.
     * @param name The name of the voting system.
     * @param version The version of the voting system.
     */
    function initializeEIP712(Store storage s, string memory name, string memory version, address verifyingContract) internal {
        EIP712Lib.initialize(s.eip712Domain, name, version, verifyingContract);
    }

    /**
     * @dev Retrieves the current block number as a uint48.
     * @return uint48 The current block number.
     */
    function clock() internal view returns (uint48) {
        Store storage s = store();
        if (s.timestamp) {
            return toUint48(block.timestamp);
        } else {
            return toUint48(block.number);
        }
    }

    /**
     * @dev Checks if the clock mode is consistent, according to ERC6372.
     * @return string The clock mode.
     */
    function CLOCK_MODE() internal view returns (string memory) {
        Store storage s = store();
        if (s.timestamp) {
            return "mode=timestamp";
        } else {
            if (clock() != toUint48(block.number)) {
                revert ERC6372InconsistentClock();
            }
            return "mode=blocknumber&from=default";
        }
    }

    /**
     * @dev Retrieves the current votes for the given account.
     * @param account The address of the account.
     * @return uint256 The current votes for the account.
     */
    function getVotes(address account) internal view returns (uint256) {
        Checkpoints.Trace208 storage s = store()._delegateCheckpoints[account];
        return Checkpoints.latest(s);
    }

    /**
     * @dev Retrieves the past votes for the given account at a specific timepoint.
     * @param account The address of the account.
     * @param timepoint The specific timepoint.
     * @return uint256 The past votes for the account at the specified timepoint.
     */
    function getPastVotes(address account, uint256 timepoint) internal view returns (uint256) {
        uint48 currentTimepoint = clock();
        if (timepoint >= currentTimepoint) {
            revert ERC5805FutureLookup(timepoint, currentTimepoint);
        }
        Checkpoints.Trace208 storage s = store()._delegateCheckpoints[account];
        return Checkpoints.upperLookupRecent(s, toUint48(timepoint));
    }

    /**
     * @dev Retrieves the past total supply at a specific timepoint.
     * @param timepoint The specific timepoint.
     * @return uint256 The past total supply at the specified timepoint.
     */
    function getPastTotalSupply(uint256 timepoint) internal view returns (uint256) {
        uint48 currentTimepoint = clock();
        if (timepoint >= currentTimepoint) {
            revert ERC5805FutureLookup(timepoint, currentTimepoint);
        }
        Checkpoints.Trace208 storage s = store()._totalCheckpoints;
        return Checkpoints.upperLookupRecent(s, toUint48(timepoint));
    }

    /**
     * @dev Retrieves the total supply of tokens.
     * @return uint256 The total supply of tokens.
     */
    function getTotalSupply() internal view returns (uint256) {
        Checkpoints.Trace208 storage s = store()._totalCheckpoints;
        return Checkpoints.latest(s);
    }

    /**
     * @dev Retrieves the delegate for the given account.
     * @param account The address of the account.
     * @return address The delegate address.
     */
    function delegates(address account) internal view returns (address) {
        return store()._delegatee[account];
    }

    /**
     * @dev Delegates votes from one account to another.
     * @param account The address of the account delegating the votes.
     * @param delegatee The address of the delegate receiving the votes.
     */
    function _delegate(address account, address delegatee) internal {
        Store storage votesStore = store();
        address oldDelegate = votesStore._delegatee[account];
        votesStore._delegatee[account] = delegatee;

        emit DelegateChanged(account, oldDelegate, delegatee);
        _moveDelegateVotes(oldDelegate, delegatee, _getVotingUnits(account));
    }

    /**
     * @dev Moves votes from one delegate to another.
     * @param from The address of the delegate losing the votes.
     * @param to The address of the delegate receiving the votes.
     * @param amount The amount of votes being moved.
     */
    function _moveDelegateVotes(address from, address to, uint256 amount) internal {
        if (from != to && amount > 0) {
        
            Store storage s = store();            
            if (from != address(0)) {
                (uint256 oldValue, uint256 newValue) = _push(s._delegateCheckpoints[from], _subtract, toUint208(amount));
                emit DelegateVotesChanged(from, oldValue, newValue);
            }
            if (to != address(0)) {
                (uint256 oldValue, uint256 newValue) = _push(s._delegateCheckpoints[to], _add, toUint208(amount));
                emit DelegateVotesChanged(to, oldValue, newValue);
            }
        }
    }

    /**
     * @dev Retrieves the number of checkpoints for the given account.
     * @param account The address of the account.
     * @return uint32 The number of checkpoints.
     */
    function _numCheckpoints(address account) internal view returns (uint32) {
        Checkpoints.Trace208 storage s = store()._delegateCheckpoints[account];
        uint length = Checkpoints.length(s);
        if (length > type(uint32).max) {
            revert OverflowedUintDowncast(32, length);
        }
        return uint32(length);
    }

    /**
     * @dev Retrieves the checkpoint at a specific position for the given account.
     * @param account The address of the account.
     * @param pos The position of the checkpoint.
     * @return Checkpoints.Checkpoint208 The checkpoint at the specified position.
     */
    function _checkpoints(address account, uint32 pos) internal view returns (Checkpoints.Checkpoint208 memory) {
        Checkpoints.Trace208 storage s = store()._delegateCheckpoints[account];
        uint length = Checkpoints.length(s);
        require(pos < length, "Index out of bounds");
        return Checkpoints.at(s, pos);
    }

    /**
     * @dev Pushes a new checkpoint onto the checkpoint store.
     * @param checkpointStore The checkpoint store to push onto.
     * @param op The operation to perform (add or subtract).
     * @param delta The value to add or subtract.
     * @return (uint208, uint208) The old and new values after pushing the checkpoint.
     */
    function _push(
        Checkpoints.Trace208 storage checkpointStore,
        function(uint208, uint208) pure returns (uint208) op,
        uint208 delta
    ) private returns (uint208, uint208) {
       
        uint208 oldValue = Checkpoints.latest(checkpointStore);
      
        uint208 newValue = op(oldValue, delta);
      
        uint48 timepoint = clock();
    
        Checkpoints.push(checkpointStore, timepoint, newValue);
        return (oldValue, newValue);
    }

    /**
     * @dev Transfers voting units from one address to another.
     * @param from The address transferring the voting units.
     * @param to The address receiving the voting units.
     * @param amount The amount of voting units being transferred.
     */
    function _transferVotingUnits(address from, address to, uint256 amount) internal {
        Store storage s = store();
        if (from == address(0)) {
            // Minting new tokens
            (uint256 oldValue, uint256 newValue) = _push(s._totalCheckpoints, _add, toUint208(amount));
            emit DelegateVotesChanged(address(0), oldValue, newValue);
        } else if (to == address(0)) {
            // Burning tokens
            (uint256 oldValue, uint256 newValue) = _push(s._totalCheckpoints, _subtract, toUint208(amount));
            emit DelegateVotesChanged(address(0), oldValue, newValue);
        }
        _moveDelegateVotes(delegates(from), delegates(to), amount);
    }

    /**
     * @dev Converts a uint256 value to a uint48 value.
     * @param value The value to convert.
     * @return uint48 The converted value.
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        if (value > type(uint48).max) {
            revert OverflowedUintDowncast(48, value);
        }
        return uint48(value);
    }

    /**
     * @dev Converts a uint256 value to a uint208 value.
     * @param value The value to convert.
     * @return uint208 The converted value.
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        if (value > type(uint208).max) {
            revert OverflowedUintDowncast(208, value);
        }
        return uint208(value);
    }

    /**
     * @dev Subtracts two uint208 values.
     * @param a The first value.
     * @param amount The second value to subtract.
     * @return uint208 The result of the subtraction.
     */
    function _subtract(uint208 a, uint208 amount) internal pure returns (uint208) {
        require(amount <= a, "ERC20VotesStorage: subtraction underflow");
        return a - amount;
    }

    /**
     * @dev Adds two uint208 values.
     * @param a The first value.
     * @param amount The second value to add.
     * @return uint208 The result of the addition.
     */
    function _add(uint208 a, uint208 amount) internal pure returns (uint208) {
        return a + amount;
    }

    /**
     * @dev Retrieves the voting units for the given account.
     * @param account The address of the account.
     * @return uint256 The voting units for the account.
     */
    function _getVotingUnits(address account) internal view returns (uint256) {
        return ERC20Lib.store().balances[account];
    }

    /**
     * @dev Delegates votes using an EIP712 signature.
     * @param delegatee The address of the delegate receiving the votes.
     * @param nonce The nonce for the delegation.
     * @param expiry The expiry timestamp for the delegation.
     * @param v The recovery id.
     * @param r The r component of the signature.
     * @param s The s component of the signature.
     */
    function delegateBySig(address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) internal {
        if (block.timestamp > expiry) {
            revert VotesExpiredSignature(expiry);
        }
        Store storage votesStore = store();
        bytes32 structHash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                EIP712Lib._domainSeparatorV4(votesStore.eip712Domain, votesStore.verifyingContract),
                keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry))
            )
        );
        bytes32 hash = EIP712Lib._hashTypedDataV4(votesStore.eip712Domain, structHash, votesStore.verifyingContract);
        address signer = ECDSA.recover(hash, v, r, s);
        _useCheckedNonce(votesStore, signer, nonce);
        _delegate(signer, delegatee);
    }

    /**
     * @dev Checks and updates the nonce for delegated voting.
     * @param s The storage struct containing voting-related data.
     * @param owner The owner of the nonce.
     * @param nonce The nonce value.
     */
    function _useCheckedNonce(Store storage s, address owner, uint256 nonce) private {
        if (s._nonces[owner] != nonce) {
            revert InvalidNonce(s._nonces[owner], nonce);
        }
        s._nonces[owner]++;
    }

    function _eip712Domain()
        internal
        view
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract_,
            bytes32 salt,
            uint256[] memory extensions
        )
    {
        Store storage s = store();

        return (
            hex"0f", // Field selector indicating all fields are present
            s.eip712Domain.name,
            s.eip712Domain.version,
            s.eip712Domain.cachedChainId,
            s.eip712Domain.cachedThis,
            bytes32(0), // Salt value is always 0
            new uint256[](0)
        );
    }

    function domainSeparator() internal view returns (bytes32) {
        Store storage s = store();
        return EIP712Lib._domainSeparatorV4(s.eip712Domain, s.verifyingContract);
    }
}