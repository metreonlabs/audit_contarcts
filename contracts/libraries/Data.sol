// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Data {
    struct Token {
        address tokenId;
        uint256 amount;
    }

    struct IncomingMessage {
        bytes32 messageId;
        uint256 fromChainId;
        address sender;
        bytes payload;
        Token[] tokens;
    }

    struct OutgoingMessage {
        uint256 toChainId;
        address receiver;
        bytes payload;
        Token[] tokens;
    }
}
