// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Data} from "../libraries/Data.sol";
import {IPool} from "../interfaces/IPool.sol";

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Pool is IPool, Context, Ownable {
    address private immutable _metreon;

    constructor(address metreon_) Ownable() {
        if (metreon_ == address(0)) revert InvalidRouter(address(0));
        _metreon = metreon_;
    }

    function withdrawTo(
        address to,
        Data.IncomingMessage calldata message
    ) external virtual override onlyMetreon {
        _withdrawTo(to, message);
    }

    function _withdrawTo(
        address to,
        Data.IncomingMessage calldata message
    ) internal virtual;

    function withdrawTokens(
        address tokenId,
        uint256 amount
    ) external onlyOwner {
        _withdrawTokens(tokenId, amount, owner());
    }

    function _withdrawTokens(
        address tokenId,
        uint256 amount,
        address to
    ) internal virtual;

    error InvalidRouter(address router);

    modifier onlyMetreon() {
        if (_metreon != _msgSender()) revert InvalidRouter(_msgSender());
        _;
    }
}
