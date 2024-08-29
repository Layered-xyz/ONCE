// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OnceStorage} from "./OnceStorage.sol";
import { IPluginViewer } from "../Plugins/Base/PluginViewer/IPluginViewer.sol";
import { IPluginManager } from "../Plugins/Base/PluginManager/IPluginManager.sol";
import { IERC173 } from "./interfaces/IERC173.sol";
import { IERC165 } from "./interfaces/IERC165.sol";
import { EnumerableSet } from '../Utils/EnumerableSet.sol';

contract OnceInit {  
    using EnumerableSet for EnumerableSet.AddressSet;  

    function init() external {
        // adding ERC165 data
        OnceStorage.Store storage ds = OnceStorage.store();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IPluginManager).interfaceId] = true;
        ds.supportedInterfaces[type(IPluginViewer).interfaceId] = true;
    }
}
