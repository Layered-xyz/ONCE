// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ERC721Lib} from "../ERC721Lib.sol";
import {ERC721BalanceLimit} from "./ERC721BalanceLimit.sol";
import {ERC721BalanceLimitStorage} from "./ERC721BalanceLimitStorage.sol";

contract ERC721BalanceLimitInit {

    function init(uint256 _limit, address _contract) external {

        ERC721Lib.Store storage ls = ERC721Lib.store();
        ERC721BalanceLimitStorage.Store storage blls = ERC721BalanceLimitStorage.store();

        ls.mods[ERC721BalanceLimit._update.selector].push(_contract);
        blls.limit = _limit;
    }
}