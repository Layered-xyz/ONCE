// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

contract StorageSetter {
    function setStorage(bytes3 data) public {
        bytes32 slot = 0x4242424242424242424242424242424242424242424242424242424242424242;
        /* solhint-disable no-inline-assembly */
        /// @solidity memory-safe-assembly
        assembly {
            sstore(slot, data)
        }
        /* solhint-enable no-inline-assembly */
    }
}