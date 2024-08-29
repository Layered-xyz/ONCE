// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {UintUtils} from "./UintUtils.sol";
import {console} from "hardhat/console.sol";

/**
 * @title Checkpoints Library
 * @dev This library provides functionality to manage a series of checkpoints,
 *      where each checkpoint consists of a key-value pair. Checkpoints are stored
 *      in an ordered list, allowing for efficient lookup operations.
 */
library Checkpoints {
    /**
     * @dev A value was attempted to be inserted on a past checkpoint.
     */
    error CheckpointUnorderedInsertion();

    /**
     * @dev Represents a series of checkpoints.
     */
    struct Trace208 {
        Checkpoint208[] _checkpoints; // Array to store checkpoints
    }

    /**
     * @dev Represents a checkpoint containing a key-value pair.
     */
    struct Checkpoint208 {
        uint48 _key; // Key of the checkpoint
        uint208 _value; // Value associated with the key
    }

    /**
     * @dev Inserts a new checkpoint into the Trace208.
     * @param self The Trace208 structure to operate on.
     * @param key The key of the checkpoint.
     * @param value The value associated with the key.
     * @return The previous value and the new value inserted.
     * @notice Never accept `key` as a user input, as an arbitrary `type(uint48).max` key set will disable the library.
     */
    function push(Trace208 storage self, uint48 key, uint208 value) internal returns (uint208, uint208) {
 
        return _insert(self._checkpoints, key, value);
    }

    /**
     * @dev Returns the value in the oldest checkpoint with a key greater or equal to the given search key.
     * @param self The Trace208 structure to operate on.
     * @param key The search key.
     * @return The value associated with the found checkpoint, or zero if no checkpoint found.
     */
    function lowerLookup(Trace208 storage self, uint48 key) internal view returns (uint208) {
        uint256 len = self._checkpoints.length;
        uint256 pos = _lowerBinaryLookup(self._checkpoints, key, 0, len);
        return pos == len ? 0 : _unsafeAccess(self._checkpoints, pos)._value;
    }

    /**
     * @dev Returns the value in the most recent checkpoint with a key lower or equal to the given search key.
     * @param self The Trace208 structure to operate on.
     * @param key The search key.
     * @return The value associated with the found checkpoint, or zero if no checkpoint found.
     */
    function upperLookup(Trace208 storage self, uint48 key) internal view returns (uint208) {
        uint256 len = self._checkpoints.length;
        uint256 pos = _upperBinaryLookup(self._checkpoints, key, 0, len);
        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Returns the value in the most recent checkpoint with a key lower or equal to the given search key,
     *      optimized for recent checkpoints.
     * @param self The Trace208 structure to operate on.
     * @param key The search key.
     * @return The value associated with the found checkpoint, or zero if no checkpoint found.
     */
    function upperLookupRecent(Trace208 storage self, uint48 key) internal view returns (uint208) {
        uint256 len = self._checkpoints.length;
        uint256 low = 0;
        uint256 high = len;

        if (len > 5) {
            uint256 mid = len - UintUtils.sqrt(len);
            if (key < _unsafeAccess(self._checkpoints, mid)._key) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        uint256 pos = _upperBinaryLookup(self._checkpoints, key, low, high);

        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Returns the value in the most recent checkpoint, or zero if no checkpoints exist.
     * @param self The Trace208 structure to operate on.
     * @return The value in the most recent checkpoint, or zero if no checkpoints exist.
     */
    function latest(Trace208 storage self) internal view returns (uint208) {
        uint256 pos = self._checkpoints.length;
        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Returns whether there is a checkpoint in the structure (i.e., it is not empty),
     *      and if so, the key and value in the most recent checkpoint.
     * @param self The Trace208 structure to operate on.
     * @return exists Whether a checkpoint exists.
     * @return _key The key of the most recent checkpoint.
     * @return _value The value of the most recent checkpoint.
     */
    function latestCheckpoint(Trace208 storage self) internal view returns (bool exists, uint48 _key, uint208 _value) {
        uint256 pos = self._checkpoints.length;
        if (pos == 0) {
            return (false, 0, 0);
        } else {
            Checkpoint208 memory ckpt = _unsafeAccess(self._checkpoints, pos - 1);
            return (true, ckpt._key, ckpt._value);
        }
    }

    /**
     * @dev Returns the number of checkpoints.
     * @param self The Trace208 structure to operate on.
     * @return The number of checkpoints.
     */
    function length(Trace208 storage self) internal view returns (uint256) {
        return self._checkpoints.length;
    }

    /**
     * @dev Returns the checkpoint at the given position.
     * @param self The Trace208 structure to operate on.
     * @param pos The position of the checkpoint.
     * @return The checkpoint at the given position.
     */
    function at(Trace208 storage self, uint32 pos) internal view returns (Checkpoint208 memory) {
        return self._checkpoints[pos];
    }

    /**
     * @dev Inserts a new checkpoint into an ordered list of checkpoints, either by inserting a new checkpoint
     *      or by updating the last one.
     * @param self The array of checkpoints to operate on.
     * @param key The key of the checkpoint.
     * @param value The value associated with the key.
     * @return The previous value and the new value inserted.
     */
    function _insert(Checkpoint208[] storage self, uint48 key, uint208 value) private returns (uint208, uint208) {
        uint256 pos = self.length;

        if (pos > 0) {
            // Copying to memory is important here.
            Checkpoint208 memory last = _unsafeAccess(self, pos - 1);

            // Checkpoint keys must be non-decreasing.
            if (last._key > key) {
                revert CheckpointUnorderedInsertion();
            }
            // Update or push a new checkpoint.
            if (last._key == key) {
                _unsafeAccess(self, pos - 1)._value = value;
            } else {
                self.push(Checkpoint208({_key: key, _value: value}));
            }
            return (last._value, value);
        } else {
            self.push(Checkpoint208({_key: key, _value: value}));
            return (0, value);
        }
    }

    /**
     * @dev Returns the index of the last (most recent) checkpoint with a key lower or equal to the given search key.
     * @param self The array of checkpoints to operate on.
     * @param key The search key.
     * @param low The lower bound of the search range.
     * @param high The upper bound of the search range.
     * @return The index of the found checkpoint, or `high` if no checkpoint found.
     * @notice `high` should not be greater than the array's length.
     */
    function _upperBinaryLookup(Checkpoint208[] storage self, uint48 key, uint256 low, uint256 high) private view returns (uint256) {
        while (low < high) {
            uint256 mid = UintUtils.average(low, high);
            if (_unsafeAccess(self, mid)._key > key) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        return high;
    }

    /**
     * @dev Returns the index of the first (oldest) checkpoint with a key greater or equal to the given search key.
     * @param self The array of checkpoints to operate on.
     * @param key The search key.
     * @param low The lower bound of the search range.
     * @param high The upper bound of the search range.
     * @return The index of the found checkpoint, or `high` if no checkpoint found.
     * @notice `high` should not be greater than the array's length.
     */
    function _lowerBinaryLookup(Checkpoint208[] storage self, uint48 key, uint256 low, uint256 high) private view returns (uint256) {
        while (low < high) {
            uint256 mid = UintUtils.average(low, high);
            if (_unsafeAccess(self, mid)._key < key) {
                low = mid + 1;
            } else {
                high = mid;
            }
        }
        return high;
    }

    /**
 * @dev Accesses an element of the array without performing bounds check.
 *      The position is assumed to be within bounds.
 * @param self The array of checkpoints to operate on.
 * @param pos The position of the checkpoint.
 * @return result The checkpoint at the given position.
 */
function _unsafeAccess(Checkpoint208[] storage self, uint256 pos) private pure returns (Checkpoint208 storage result) {
    assembly {
        mstore(0, self.slot)
        result.slot := add(keccak256(0, 0x20), pos)
    }
}

}