// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Data} from "../libraries/Data.sol";
import {IMetreon} from "../interfaces/IMetreon.sol";
import {MetreonReceiver} from "../MetreonReceiver.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Beamre is MetreonReceiver, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IMetreon private _metreon;

    mapping(address => bytes32[]) public _actions;
    mapping(uint256 => address) public _contracts;

    constructor(
        address config_,
        address metreon_
    ) MetreonReceiver(config_, metreon_) {
        _metreon = IMetreon(getMetreon());
    }

    function setContract(uint256 chainId, address contractId) external {
        _contracts[chainId] = contractId;
    }

    function bridgeToken(
        uint256 toChainId,
        Data.Token[] memory tokens
    ) external payable nonReentrant {
        Data.OutgoingMessage memory message = Data.OutgoingMessage({
            toChainId: toChainId,
            receiver: _contracts[toChainId],
            payload: abi.encode(_msgSender()),
            tokens: tokens
        });

        for (uint256 index = 0; index < tokens.length; index++) {
            Data.Token memory token = tokens[index];

            IERC20 tokenContract = IERC20(token.tokenId);

            tokenContract.safeTransferFrom(
                _msgSender(),
                address(this),
                token.amount
            );

            tokenContract.safeApprove(address(_metreon), token.amount);
        }

        address tokenPool = _metreon.getDefaultTokenPool();

        uint256 fee = _metreon.estimateFee(toChainId);

        require(msg.value >= fee, "INSUFICCIENT GAS");

        bytes32 messageId = _metreon.sendMessage{value: fee}(
            message,
            tokenPool
        );

        _actions[_msgSender()].push(messageId);
    }

    function _metreonReceive(
        Data.IncomingMessage memory message
    ) internal override {
        address receiver = abi.decode(message.payload, (address));

        for (uint256 index = 0; index < message.tokens.length; index++) {
            Data.Token memory token = message.tokens[index];

            if (token.tokenId == _metreon.defaultNativeId()) {
                payable(receiver).transfer(token.amount);
            } else {
                IERC20 tokenContract = IERC20(token.tokenId);
                tokenContract.safeTransfer(receiver, token.amount);
            }
        }
    }
}
