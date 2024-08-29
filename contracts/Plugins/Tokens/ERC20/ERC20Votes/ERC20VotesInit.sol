// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC20VotesStorage } from "./ERC20VotesStorage.sol";
import { ERC20Votes } from "./ERC20Votes.sol";
import { ERC20Lib } from "../ERC20Lib.sol";

/**
 * @title ERC20VotesInit
 * @dev This contract is responsible for initializing the ERC20 voting system.
 */
contract ERC20VotesInit {

    // Error thrown when an empty string is provided for name or version during initialization
    error EmptyString();

    /**
     * @dev Initializes the ERC20 voting system with the provided name, version, and contract address.
     * @param _name The name of the voting system.
     * @param _version The version of the voting system.
     * @param _contract The address of the ERC20 contract implementing the voting system.
     */
    function init(string memory _name, string memory _version, address _contract, bool timestamp, address _diamond) external {
        // Ensure that neither the name nor the version is empty
        if (bytes(_name).length == 0 || bytes(_version).length == 0) {
            revert EmptyString();
        }
        
        // Initialize the EIP712 domain with the provided name and version
        ERC20VotesStorage.Store storage s = ERC20VotesStorage.store();
        s.timestamp = timestamp;
        s.verifyingContract = _diamond;
        ERC20VotesStorage.initializeEIP712(s, _name, _version,_diamond);

        // Add the ERC20Votes contract address to the mods mapping
        ERC20Lib.Store storage ls = ERC20Lib.store();
        ls.mods[ERC20Votes._update.selector].push(_contract);
    }

    function uninstall(address _contract) external {
        ERC20Lib.Store storage ls = ERC20Lib.store();
        bytes4 selector = ERC20Votes._update.selector;
        address[] storage modsArray = ls.mods[selector];

        // Find and remove the contract address from the mods array
        for (uint256 i = 0; i < modsArray.length; i++) {
            if (modsArray[i] == _contract) {
                modsArray[i] = modsArray[modsArray.length - 1];
                modsArray.pop();
                break;
            }
        }
    }
}