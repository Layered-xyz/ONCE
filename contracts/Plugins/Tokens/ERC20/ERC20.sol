// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "./IERC20.sol";
import { IERC20Metadata } from "./IERC20Metadata.sol";
import { IERC20Errors } from "../../../Utils/draft-IERC6093.sol";
import { ERC20Lib } from "./ERC20Lib.sol";
import { IOncePlugin } from "../../../Interfaces/IOncePlugin.sol";

/**
 * @title ERC20
 * @author Ketul 'Jay' Patel
 * @notice The ONCE Plugin for building ERC20 tokens.
 * @dev Based on the OZ ERC20 implementation
 */
contract ERC20 is IERC20, IERC20Metadata, IOncePlugin {
    
    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return ERC20Lib.store().name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return ERC20Lib.store().symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        if (ERC20Lib.store().decimals == 0) {
            return 18;
        }
        return ERC20Lib.store().decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return ERC20Lib.store().totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return ERC20Lib.store().balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `value`.
     */
    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = msg.sender;
        ERC20Lib._transfer(owner, to, value);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return ERC20Lib._allowance(owner, spender);
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public virtual returns (bool) {
        address owner = msg.sender;
        ERC20Lib._approve(owner, spender, value);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `value`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `value`.
     */
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = msg.sender;
        ERC20Lib._spendAllowance(from, spender, value);
        ERC20Lib._transfer(from, to, value);
        return true;
    }

    /**
     * @inheritdoc IOncePlugin
     */
    function getFunctionSelectors() public pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](9);
        selectors[0] = this.name.selector;
        selectors[1] = this.symbol.selector;
        selectors[2] = this.decimals.selector;
        selectors[3] = this.totalSupply.selector;
        selectors[4] = this.balanceOf.selector;
        selectors[5] = this.transfer.selector;
        selectors[6] = this.allowance.selector;
        selectors[7] = this.approve.selector;
        selectors[8] = this.transferFrom.selector;
        return selectors;
    }

    /**
     * @inheritdoc IOncePlugin
     */
    function getSingletonAddress() public view returns (address) {
        return address(this);
    } 
}
