// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMetreonConfig {
    event SetFee(uint256 toChainId, uint256 amount);
    event SupportedChains(uint256[] chains);
    event SupportedTokens(address[] chains);
    event SetChainTokenId(
        uint256 chainId,
        address tokenId,
        address chainTokenId
    );

    error InvalidAmount(uint256 amount);
    error InvalidChainId(uint256 chainId);

    function getChainTokenId(
        uint256 chainId,
        address tokenId
    ) external view returns (address);

    function setChainTokenId(
        uint256 chainId,
        address tokenId,
        address chainToken
    ) external;

    function getFee(uint256 toChainId) external view returns (uint256);

    function setFee(uint256 toChainId, uint256 amount) external;

    function supportedChains() external view returns (uint256[] memory);

    function supportedTokens() external view returns (address[] memory);

    function updateSupportedChains(uint256[] memory chains) external;

    function updateSupportedTokens(address[] memory chains) external;
}
