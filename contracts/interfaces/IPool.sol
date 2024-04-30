// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Data} from "../libraries/Data.sol";

interface IPool {
    function withdrawTo(
        address to,
        Data.IncomingMessage calldata message
    ) external;
}
