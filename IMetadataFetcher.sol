// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMetadataFetcher {
    
    struct Metadata {
        string key;
        string value;
    }

    function fetchMetadata(address tokenAddress, uint256 tokenId, string memory queryKey) external;

    function getMetadataByTokenId(uint256 tokenId) external view returns (Metadata[] memory);

    function getMetadataValue(uint256 tokenId, string memory key) external view returns (string memory);
}
