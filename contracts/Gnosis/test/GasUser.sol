// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

contract GasUser {
                
    uint256[] public data;

    constructor() payable {}

    function nested(uint256 level, uint256 count) external {
        if (level == 0) {
            for (uint256 i = 0; i < count; i++) {
                data.push(i);
            }
            return;
        }
        this.nested(level - 1, count);
    }

    function useGas(uint256 count) public {
        this.nested(6, count);
        this.nested(8, count);
    }
}