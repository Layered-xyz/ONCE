// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import { ERC20Lib } from "./ERC20Lib.sol";


contract ERC20Init {    

    function init(string memory _name, string memory _symbol, uint8 _decimals, address[] memory initialAddresses, uint256[] memory initialBalances) external {

        require(initialAddresses.length == initialBalances.length);

        ERC20Lib.Store storage s = ERC20Lib.store();
        s.name = _name;
        s.symbol = _symbol;
        s.decimals = _decimals;

        for (uint i = 0; i < initialAddresses.length; i++) {
            s.totalSupply += initialBalances[i];
            s.balances[initialAddresses[i]] += initialBalances[i];
        }
    }


}
