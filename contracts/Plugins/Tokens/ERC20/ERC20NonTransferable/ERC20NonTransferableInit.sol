// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ERC20Lib} from "../ERC20Lib.sol";
import {ERC20NonTransferable} from "./ERC20NonTransferable.sol";

contract ERC20NonTransferableInit {

    function init(address _contract) external {

        ERC20Lib.Store storage ls = ERC20Lib.store();
        ls.mods[ERC20NonTransferable._update.selector].push(_contract);
    }
}