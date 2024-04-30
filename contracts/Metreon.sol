// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Hash} from "./libraries/Hash.sol";
import {Data} from "./libraries/Data.sol";
import {IPool} from "./interfaces/Ipool.sol";
import {IMetreon} from "./interfaces/IMetreon.sol";
import {IMessageReceiver} from "./interfaces/IMessageReceiver.sol";
import {IMetreonConfig} from "./interfaces/IMetreonConfig.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Metreon is IMetreon, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address private _defaultTokenPool;

    address private _nativeId = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    uint256 private _sequence;
    IMetreonConfig private _config;

    mapping(bytes32 => bool) private _executed;

    constructor(address config_, address defaultTokenPool_) Ownable() {
        _defaultTokenPool = defaultTokenPool_;
        _config = IMetreonConfig(config_);
    }

    function estimateFee(uint256 toChainId) external view returns (uint256) {
        return _config.getFee(toChainId);
    }

    function sendMessage(
        Data.OutgoingMessage calldata message,
        address tokenPool
    ) external payable nonReentrant returns (bytes32) {
        if (!_isChainSupported(message.toChainId)) {
            revert UnsupportedChain(message.toChainId);
        }

        bytes32 combinedMsgIndex = (Hash.addressToBytes32(_msgSender()) << 96) |
            bytes32(_sequence);

        bytes32 messageId = Hash.getHash(message, combinedMsgIndex);

        uint256 estimatedFee = _config.getFee(message.toChainId);

        if (msg.value < estimatedFee) revert InsufficientGasFee();

        for (uint256 index = 0; index < message.tokens.length; index++) {
            Data.Token memory token = message.tokens[index];

            if (token.tokenId == _nativeId) {
                payable(tokenPool).transfer(msg.value);
            } else {
                IERC20 tokenContract = IERC20(token.tokenId);
                tokenContract.safeTransferFrom(
                    _msgSender(),
                    tokenPool,
                    token.amount
                );
            }
        }

        emit Dispatch(
            messageId,
            estimatedFee,
            _nativeId,
            _sequence,
            message.toChainId,
            _msgSender(),
            message.receiver,
            message.tokens,
            message.payload
        );

        _sequence++;

        return messageId;
    }

    function postMessage(
        address receiver,
        Data.IncomingMessage calldata message,
        address tokenPool
    ) external override onlyOwner {
        if (_executed[message.messageId]) {
            revert AlreadyExecuted(message.messageId);
        }

        if (message.tokens.length > 0) {
            IPool pool = IPool(tokenPool);
            pool.withdrawTo(receiver, message);
        }

        IMessageReceiver messageReceiver = IMessageReceiver(receiver);

        messageReceiver.metreonReceive(message);

        emit PostMessage(message.messageId);

        _executed[message.messageId] = true;
    }

    function getDefaultTokenPool() external view override returns (address) {
        return _defaultTokenPool;
    }

    function defaultNativeId() external view override returns (address) {
        return _nativeId;
    }

    function _isChainSupported(uint256 chainId) internal view returns (bool) {
        uint256[] memory chainIds = _config.supportedChains();

        for (uint256 index = 0; index < chainIds.length; index++) {
            if (chainIds[index] == chainId) return true;
        }

        return false;
    }

    function _isTokenSupported(address tokenId) internal view returns (bool) {
        address[] memory tokenIds = _config.supportedTokens();

        for (uint256 index = 0; index < tokenIds.length; index++) {
            if (tokenIds[index] == tokenId) return true;
        }

        return false;
    }
}
