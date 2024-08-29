// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20 } from "./IERC20.sol";
import { IERC20Metadata } from "./IERC20Metadata.sol";
import { IERC20Errors } from "../../../Utils/draft-IERC6093.sol";


/**
 * @title ERC20Lib -- A storage library for the ONCE ERC20 plugin
 * @author Ketul 'Jay' Patel
 * @notice Maintains all ERC20 internal functionality as well as storage
 * @dev ERC20Lib allows for other ONCE plugins to install mods that will add functionality to the ERC20Lib _update internal function 
 */
library ERC20Lib {


    struct Store {
        mapping(bytes4 => address[]) mods;
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
        uint256 totalSupply;
        string name;
        string symbol;
        uint8 decimals;
        bool initialized;
    }

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    bytes32 internal constant STORAGE_SLOT =
        keccak256('layered.contracts.lib.ERC20');

    function store() internal pure returns (Store storage s) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert IERC20Errors.ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert IERC20Errors.ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively mints (or burns) if `from`
     * (or `to`) is the zero address. All customizations to transfers, mints, and burns should be done by installing mods for
     * this function.
     *
     * Emits a {Transfer} event.
     */
    function _update(address from, address to, uint256 value) internal {
        bytes4 modSelector = bytes4(keccak256(bytes('_update(address,address,uint256)'))); // modSelector should be the same as the current function

        for(uint i = 0; i < ERC20Lib.store().mods[modSelector].length; i++) {
            (bool success, bytes memory returndata) = ERC20Lib.store().mods[modSelector][i].delegatecall(abi.encodeWithSelector(modSelector, from, to, value));
            // if the function call reverted
            if (!success) {
                // if there is a return reason string
                if (returndata.length > 0) {
                    // bubble up any reason for revert
                    assembly {
                        let returndata_size := mload(returndata)
                        revert(add(32, returndata), returndata_size)
                    }
                } else {
                    revert("Function call reverted");
                }
            }
        }

        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            ERC20Lib.store().totalSupply += value;
        } else {
            uint256 fromBalance = ERC20Lib.store().balances[from];
            if (fromBalance < value) {
                revert IERC20Errors.ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                ERC20Lib.store().balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                ERC20Lib.store().totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                ERC20Lib.store().balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    /**
     * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
     * Relies on the `_update` mechanism
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert IERC20Errors.ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, lowering the total supply.
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead
     */
    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert IERC20Errors.ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    /**
     * @dev Sets `value` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    /**
     * @dev Variant of {_approve} with an optional flag to enable or disable the {Approval} event.
     *
     * By default (when calling {_approve}) the flag is set to true. On the other hand, approval changes made by
     * `_spendAllowance` during the `transferFrom` operation set the flag to false. This saves gas by not emitting any
     * `Approval` event during `transferFrom` operations.
     *
     * Anyone who wishes to continue emitting `Approval` events on the`transferFrom` operation can force the flag to
     * true using the following override:
     * ```
     * function _approve(address owner, address spender, uint256 value, bool) internal virtual override {
     *     super._approve(owner, spender, value, true);
     * }
     * ```
     *
     * Requirements are the same as {_approve}.
     */
    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal {
        if (owner == address(0)) {
            revert IERC20Errors.ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert IERC20Errors.ERC20InvalidSpender(address(0));
        }
        ERC20Lib.store().allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function _allowance(address owner, address spender) internal view returns (uint256) {
        return ERC20Lib.store().allowances[owner][spender];
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `value`.
     *
     * Does not update the allowance value in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Does not emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 value) internal {
        uint256 currentAllowance = _allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert IERC20Errors.ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}