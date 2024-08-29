// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ERC20CappedStorage} from "./ERC20CappedStorage.sol";
import {ERC20Capped} from "./ERC20Capped.sol";
import {ERC20Lib} from "../ERC20Lib.sol";

contract ERC20CappedInit {

    error ERC20InvalidCap(uint256 cap);

    function init(uint256 _cap, address _contract) external {

        if(_cap == 0){
            revert ERC20InvalidCap(0);
        }

        ERC20CappedStorage.Store storage s = ERC20CappedStorage.store();
        s.cap = _cap;

        ERC20Lib.Store storage ls = ERC20Lib.store();
        ls.mods[ERC20Capped._update.selector].push(_contract);
    }
}