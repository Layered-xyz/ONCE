// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ISafe} from "./ISafe.sol";


contract SafeProxyInit {  

    function init(
        address masterCopy,
        address[] calldata _owners,
        uint256 _threshold,
        address to,
        bytes calldata data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address payable paymentReceiver
    ) external {
        // Safe Wallet and other UX tools use get_storage_at to retrieve the Safe singleton address (rather than function masterCopy())
        // Since the Once uses unstructured storage, sload(0) should be empty unless another plugin already uses it 
        // If this is overriden, the core safe functionality will be unharmed but it will affect compatibility with the Gnosis Safe Wallet Web Interface and Gnosis Safe Transaction Service tools
        assembly {
            sstore(0, masterCopy)
        }



        ISafe(address(this)).setup(
            _owners,
            _threshold,
            to,
            data,
            fallbackHandler,
            paymentToken,
            payment,
            paymentReceiver
        );


    }
}
