// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ERC721Lib} from "../ERC721Lib.sol";
import {ERC721NonTransferable} from "./ERC721NonTransferable.sol";

contract ERC721NonTransferableInit {

    function init(address _contract) external {

        ERC721Lib.Store storage ls = ERC721Lib.store();
        ls.mods[ERC721NonTransferable._update.selector].push(_contract);
    }
}