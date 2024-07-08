// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { OnceStorage } from '../../Base/OnceStorage.sol';


/**
 * @title Role-based access control system enforcer
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
contract AccessControlEnforcer {

    function hasRole(
        bytes32 role,
        address account
    ) external view returns (bool) {
        return OnceStorage._hasRole(role, account);
    }

    modifier onlyRole(bytes32 role) {
        OnceStorage._checkRole(role);
        _;
    }
}