// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/**
 * @title Role-based access control system
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
interface IAccessControl {

    function grantRole(bytes32 role, address account) external;
    
    function hasRole(bytes32 role, address account) external view returns (bool);
    
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function setRoleAdmin(bytes32 role, bytes32 adminRole) external;
    
    function revokeRole(bytes32 role, address account) external;
    
    function renounceRole(bytes32 role) external;
    
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);
    
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}