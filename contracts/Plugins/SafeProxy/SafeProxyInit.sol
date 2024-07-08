// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ISafe} from "./ISafe.sol";

contract SafeProxyInit {  

    function init(
        address[] calldata _owners,
        uint256 _threshold,
        address to,
        bytes calldata data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address payable paymentReceiver
    ) external {
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
