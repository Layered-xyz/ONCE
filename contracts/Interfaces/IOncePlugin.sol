// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOncePlugin {
    function getFunctionSelectors() external view returns (bytes4[] memory);
    function getSingletonAddress() external view returns (address);
}