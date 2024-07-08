// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { OnceFactoryStorage } from "./OnceFactoryStorage.sol";

contract OnceFactoryInit {   

    function init(address _pluginManagerAddress, address _pluginViewerAddress, address _accessControlAddress) external {
        OnceFactoryStorage.Store storage s = OnceFactoryStorage.store();
        s.pluginManagerAddress = _pluginManagerAddress;
        s.pluginViewerAddress = _pluginViewerAddress;
        s.accessControlAddress = _accessControlAddress;
    }

}
