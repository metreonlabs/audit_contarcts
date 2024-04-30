// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Data} from "../libraries/Data.sol";

interface IMessageReceiver {
    function metreonReceive(Data.IncomingMessage calldata message) external;

    function getMetreon() external view returns (address);
}
