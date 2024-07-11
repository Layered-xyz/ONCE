// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { EnumerableSet } from '../Utils/EnumerableSet.sol';
import { AddressUtils } from '../Utils/AddressUtils.sol';
import { UintUtils } from '../Utils/UintUtils.sol';
import { IPluginManager } from '../Plugins/PluginManager/IPluginManager.sol';


error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);


/**
 * @title OnceStorage -- A storage library for the ONCE base contract
 * @author Ketul 'Jay' Patel
 * @notice OnceStorage allows the ONCE base contract to store access control and plugin information via the diamond storage pattern
 */
library OnceStorage {
    using AddressUtils for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    using UintUtils for uint256;
    
    /**
     * @notice This event is emited when the admin role changes
     * @param role the role for which the admin role changed
     * @param previousAdminRole the previous admin role
     * @param newAdminRole the new admin role
     */
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    /**
     * @notice This event is emitted when a role is granted
     * @param role the role that was granted
     * @param account the address that the role was granted to
     * @param sender the transaction sender (msg.sender)
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @notice This event is emitted when a role is revoked
     * @param role the role that was revoked
     * @param account the address from which the role was revoked
     * @param sender the transaction sender (msg.sender)
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    bytes32 constant STORAGE_SLOT = keccak256("layered.contracts.lib.once");

    /**
     * @dev there are 2 roles defined by default
     * ONCE_UPDATE_ROLE is used for access control on plugin management
     * DEFAULT_ADMIN_ROLE provides an internal constant for referring to the default admin role (0x00)
     */
    bytes32 public constant ONCE_UPDATE_ROLE = keccak256("LAYERED_ONCE_UPDATE_ROLE");
    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;

    struct PluginAddressAndPosition {
        address pluginAddress;
        uint96 functionSelectorPosition; // position in pluginFunctionSelectors.functionSelectors array
    }

    struct PluginFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 pluginAddressPosition; // position of pluginAddress in facetAddresses array
    }

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    } 

    struct Store {
        // maps function selector to the plugin address and
        // the position of the selector in the pluginFunctionSelectors.selectors array
        mapping(bytes4 => PluginAddressAndPosition) selectorToPluginAndPosition;
        // maps plugin addresses to function selectors
        mapping(address => PluginFunctionSelectors) pluginFunctionSelectors;
        // plugin addresses
        address[] pluginAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // Access control roles
        mapping(bytes32 => RoleData) roles;
    }

    function store() internal pure returns (Store storage s) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }

    /**
     * @notice query whether role is assigned to account
     * @param role role to query
     * @param account account to query
     * @return whether role is assigned to account
     */
    function _hasRole(
        bytes32 role,
        address account
    ) internal view returns (bool) {
            Store storage ds = store();
            return ds.roles[role].members.contains(account);
    }

    /**
     * @notice revert if sender does not have given role
     * @param role role to query
     */
    function _checkRole(
        bytes32 role
    ) internal view {
        _checkRole(role, msg.sender);
    }

    /**
     * @notice revert if given account does not have given role
     * @param role role to query
     * @param account to query
     */
    function _checkRole(
        bytes32 role, 
        address account
    ) internal view {
        if (!_hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        'AccessControl: account ',
                        account.toString(),
                        ' is missing role ',
                        uint256(role).toHexString(32)
                    )
                )
            );
        }
    }

    /**
     * @notice query admin role for given role
     * @param role role to query
     * @return admin role
     */
    function _getRoleAdmin(
        bytes32 role
    ) internal view returns (bytes32) {
        Store storage ds = store();
        return ds.roles[role].adminRole;
    }

    /**
     * @notice set role as admin role
     * @param role role to set
     * @param adminRole admin role to set
     */
    function _setRoleAdmin(
        bytes32 role, 
        bytes32 adminRole
    ) internal {
        bytes32 previousAdminRole = _getRoleAdmin(role);
        Store storage ds = store();
        ds.roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @notice assign role to given account
     * @param role role to assign
     * @param account recipient of role assignment
     */
    function _grantRole(
        bytes32 role, 
        address account
    ) internal {
        Store storage ds = store();
        ds.roles[role].members.add(account);
        emit RoleGranted(role, account, msg.sender);
    }

    /**
     * @notice unassign role from given account
     * @param role role to unassign
     * @param account address to unassign role from
     */
    function _revokeRole(
        bytes32 role, 
        address account
    ) internal {
        Store storage ds = store();
        ds.roles[role].members.remove(account);
        emit RoleRevoked(role, account, msg.sender);
    }

    /**
     * @notice relinquish role
     * @param role role to relinquish
     */
    function _renounceRole(
        bytes32 role
    ) internal {
        _revokeRole(role, msg.sender);
    }

    /**
     * @notice query role for member at given index
     * @param role role to query
     * @param index index to query
     */
    function _getRoleMember(
        bytes32 role,
        uint256 index
    ) internal view returns (address) {
        Store storage ds = store();
        return ds.roles[role].members.at(index);
    }

    /**
     * @notice query role for member count
     * @param role role to query
     */
    function _getRoleMemberCount(
        bytes32 role
    ) internal view returns (uint256) {
        Store storage ds = store();
        return ds.roles[role].members.length();
    }

}
