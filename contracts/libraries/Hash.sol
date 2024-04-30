// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Data} from "./Data.sol";

library Hash {
    bytes32 internal constant LEAF_DOMAIN_SEPARATOR =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE000000000000000000000000;

    function addressToBytes32(
        address _address
    ) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_address)));
    }

    function getHash(
        Data.OutgoingMessage memory message,
        bytes32 sequence
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    LEAF_DOMAIN_SEPARATOR,
                    sequence,
                    message.toChainId,
                    message.receiver,
                    message.payload,
                    message.tokens
                )
            );
    }
}
