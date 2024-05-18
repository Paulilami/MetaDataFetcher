// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

contract ERC721MetadataScanner is ChainlinkClient, ConfirmedOwner {
    using Chainlink for Chainlink.Request;
    using Strings for uint256;

    struct Metadata {
        string key;
        string value;
    }

    struct RequestInfo {
        address requester;
        uint256 tokenId;
        string tokenURI;
    }

    mapping(bytes32 => RequestInfo) private requests;
    mapping(uint256 => Metadata[]) public metadataStorage;

    address private oracle;
    bytes32 private jobId;
    uint256 private fee;

    event MetadataFetched(uint256 indexed tokenId, Metadata[] metadata);
    event MetadataRequestSent(bytes32 indexed requestId, uint256 indexed tokenId, string uri);

    constructor(address _oracle, bytes32 _jobId, uint256 _fee, address _link) ConfirmedOwner(msg.sender) {
        setChainlinkToken(_link);
        oracle = _oracle;
        jobId = _jobId;
        fee = _fee;
    }

    function getERC721Metadata(address tokenAddress, uint256 tokenId) public {
        IERC721Metadata token = IERC721Metadata(tokenAddress);
        Metadata[] memory onChainMetadata = new Metadata[](3);
        onChainMetadata[0] = Metadata("name", token.name());
        onChainMetadata[1] = Metadata("symbol", token.symbol());
        onChainMetadata[2] = Metadata("tokenURI", token.tokenURI(tokenId));

        metadataStorage[tokenId] = onChainMetadata;

        if (bytes(onChainMetadata[2].value).length > 0) {
            fetchIPFSMetadata(onChainMetadata[2].value, tokenId);
        } else {
            emit MetadataFetched(tokenId, onChainMetadata);
        }
    }

    function fetchIPFSMetadata(string memory uri, uint256 tokenId) internal {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        request.add("get", uri);
        request.add("path", ""); // Leave empty to get the full JSON

        bytes32 requestId = sendChainlinkRequestTo(oracle, request, fee);
        requests[requestId] = RequestInfo(msg.sender, tokenId, uri);

        emit MetadataRequestSent(requestId, tokenId, uri);
    }

    function fulfill(bytes32 _requestId, string[] memory _keys, string[] memory _values) public recordChainlinkFulfillment(_requestId) {
        RequestInfo memory requestInfo = requests[_requestId];

        Metadata[] memory offChainMetadata = new Metadata[](_keys.length);
        for (uint256 i = 0; i < _keys.length; i++) {
            offChainMetadata[i] = Metadata(_keys[i], _values[i]);
        }

        // Merge on-chain and off-chain metadata
        uint256 totalLength = metadataStorage[requestInfo.tokenId].length + offChainMetadata.length;
        Metadata[] memory allMetadata = new Metadata[](totalLength);
        for (uint256 i = 0; i < metadataStorage[requestInfo.tokenId].length; i++) {
            allMetadata[i] = metadataStorage[requestInfo.tokenId][i];
        }
        for (uint256 i = 0; i < offChainMetadata.length; i++) {
            allMetadata[metadataStorage[requestInfo.tokenId].length + i] = offChainMetadata[i];
        }

        metadataStorage[requestInfo.tokenId] = allMetadata;
        delete requests[_requestId];

        emit MetadataFetched(requestInfo.tokenId, allMetadata);
    }

    function getMetadataByTokenId(uint256 tokenId) public view returns (Metadata[] memory) {
        return metadataStorage[tokenId];
    }

    function getMetadataValue(uint256 tokenId, string memory key) public view returns (string memory) {
        Metadata[] memory metadata = metadataStorage[tokenId];
        for (uint256 i = 0; i < metadata.length; i++) {
            if (keccak256(abi.encodePacked(metadata[i].key)) == keccak256(abi.encodePacked(key))) {
                return metadata[i].value;
            }
        }
        return "";
    }

    function setOracle(address _oracle) external onlyOwner {
        oracle = _oracle;
    }

    function setJobId(bytes32 _jobId) external onlyOwner {
        jobId = _jobId;
    }

    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    function setLinkToken(address _link) external onlyOwner {
        setChainlinkToken(_link);
    }
}
