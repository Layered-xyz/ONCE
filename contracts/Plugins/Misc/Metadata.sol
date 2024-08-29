// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IOncePlugin } from '../../Interfaces/IOncePlugin.sol';
import {AccessControlEnforcer} from "../Base/AccessControl/AccessControlEnforcer.sol";
import { MetadataStorage } from './MetadataStorage.sol';

/**
 * @title Metadata -- a plugin for adding metadata to a ONCE contract
 * @author Ketul 'Jay' Patel
 * @notice The Metadata plugin adds storage to a ONCE with a getter and permissioned setter for a entityURI field. 
 */
contract Metadata is IOncePlugin, AccessControlEnforcer {

    function setEntityURI(string calldata uri) public onlyRole(MetadataStorage.ONCE_METADATA_UPDATE_ROLE) {
        string memory oldURI = MetadataStorage.store().entityURI;
        MetadataStorage.store().entityURI = uri;

        emit MetadataStorage.MetadataUpdated(uri, oldURI);
    }

    function entityURI() public view returns(string memory) {
        return MetadataStorage.store().entityURI;
    }

    /**
     * @inheritdoc IOncePlugin
    */
    function getFunctionSelectors() public pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = this.setEntityURI.selector;
        selectors[1] = this.entityURI.selector;
        return selectors;
    }

    /**
     * @inheritdoc IOncePlugin
    */
    function getSingletonAddress() public view returns (address) {
        return address(this);
    }

}