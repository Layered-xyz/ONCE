// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { EnumerableSet } from '../../../Utils/EnumerableSet.sol';
import { AddressUtils } from '../../../Utils/AddressUtils.sol';
import { UintUtils } from '../../../Utils/UintUtils.sol';
import { OnceStorage } from '../../../Base/OnceStorage.sol';
import { IOncePlugin } from '../../../Interfaces/IOncePlugin.sol';


/**
 * @title Role-based access control system
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
contract AccessControl is IOncePlugin {
    using AddressUtils for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    using UintUtils for uint256;

    function grantRole(
        bytes32 role,
        address account
    ) external onlyRole(OnceStorage._getRoleAdmin(role)) {
        OnceStorage._grantRole(role, account);
    }

    function setRoleAdmin(
        bytes32 role,
        bytes32 adminRole
    ) external onlyRole(OnceStorage._getRoleAdmin(role)) {
        OnceStorage._setRoleAdmin(role, adminRole);
    }

    
    function hasRole(
        bytes32 role,
        address account
    ) external view returns (bool) {
        return OnceStorage._hasRole(role, account);
    }

    
    function getRoleAdmin(bytes32 role) external view returns (bytes32) {
        return OnceStorage._getRoleAdmin(role);
    }

    
    function revokeRole(
        bytes32 role,
        address account
    ) external onlyRole(OnceStorage._getRoleAdmin(role)) {
        OnceStorage._revokeRole(role, account);
    }

    
    function renounceRole(bytes32 role) external {
        OnceStorage._renounceRole(role);
    }

    
    function getRoleMember(
        bytes32 role,
        uint256 index
    ) external view returns (address) {
        return OnceStorage._getRoleMember(role, index);
    }

    
    function getRoleMemberCount(bytes32 role) external view returns (uint256) {
        return OnceStorage._getRoleMemberCount(role);
    }

    modifier onlyRole(bytes32 role) {
        OnceStorage._checkRole(role);
        _;
    }

    function getFunctionSelectors() public pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](8);
        selectors[0] = this.grantRole.selector;
        selectors[1] = this.setRoleAdmin.selector;
        selectors[2] = this.hasRole.selector;
        selectors[3] = this.getRoleAdmin.selector;
        selectors[4] = this.revokeRole.selector;
        selectors[5] = this.renounceRole.selector;
        selectors[6] = this.getRoleMember.selector;
        selectors[7] = this.getRoleMemberCount.selector;
        return selectors;
    }

    function getSingletonAddress() public view returns (address) {
        return address(this);
    }
}