// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ERC20Pausable} from "./ERC20Pausable.sol";
import {ERC20Lib} from "../ERC20Lib.sol";

contract ERC20PausableInit {

    function init(address _contract) external {
        // Access the ERC20Lib storage structure.
        ERC20Lib.Store storage ls = ERC20Lib.store();
        
        // Register the provided contract as a mod for the _update ERC20 function.
        ls.mods[ERC20Pausable._update.selector].push(_contract);
    }
}