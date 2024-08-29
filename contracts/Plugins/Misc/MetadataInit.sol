// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MetadataStorage} from './MetadataStorage.sol';

contract MetadataInit {  

    function init(string calldata _entityURI) external {
        MetadataStorage.Store storage s = MetadataStorage.store();
        s.entityURI = _entityURI;
    }
}
