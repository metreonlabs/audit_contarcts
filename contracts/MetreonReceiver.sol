// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Data} from "./libraries/Data.sol";
import {IMessageReceiver} from "./interfaces/IMessageReceiver.sol";
import {IMetreonConfig} from "./interfaces/IMetreonConfig.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

abstract contract MetreonReceiver is IMessageReceiver, Context, Ownable {
    address private immutable _metreon;
    IMetreonConfig private _config;

    constructor(address config_, address metreon_) Ownable() {
        if (metreon_ == address(0)) revert InvalidRouter(address(0));
        _metreon = metreon_;
        _config = IMetreonConfig(config_);
    }

    function metreonReceive(
        Data.IncomingMessage calldata message
    ) external virtual override onlyMetreon {
        Data.IncomingMessage memory updatedMessage = message;

        for (uint256 index = 0; index < updatedMessage.tokens.length; index++) {
            updatedMessage.tokens[index] = Data.Token({
                tokenId: _config.getChainTokenId(
                    message.fromChainId,
                    message.tokens[index].tokenId
                ),
                amount: message.tokens[index].amount
            });
        }

        _metreonReceive(updatedMessage);
    }

    function _metreonReceive(
        Data.IncomingMessage memory message
    ) internal virtual;

    function getMetreon() public view override returns (address) {
        return _metreon;
    }

    error InvalidRouter(address router);

    modifier onlyMetreon() {
        if (_metreon != _msgSender()) revert InvalidRouter(_msgSender());
        _;
    }
}
