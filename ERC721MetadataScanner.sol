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
        request.add("path", ""); // We will parse the entire JSON

        bytes32 requestId = sendChainlinkRequestTo(oracle, request, fee);
        requests[requestId] = RequestInfo(msg.sender, tokenId, uri);
    }

    function fulfill(bytes32 _requestId, string memory _data) public recordChainlinkFulfillment(_requestId) {
        RequestInfo memory requestInfo = requests[_requestId];

        // Assuming _data is a JSON string, we need to parse it
        Metadata[] memory offChainMetadata = parseJSON(_data);

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

    function parseJSON(string memory json) internal pure returns (Metadata[] memory) {
        // Implement JSON parsing logic here
        // This could involve using an off-chain service to parse the JSON and return key-value pairs
        // For the sake of this example, we'll assume the JSON is a flat key-value string separated by commas

        string[] memory keyValues = splitString(json, ","); // Adjust parsing logic as needed
        Metadata[] memory metadata = new Metadata[](keyValues.length);
        for (uint256 i = 0; i < keyValues.length; i++) {
            string[] memory keyValue = splitString(keyValues[i], ":"); // Adjust parsing logic as needed
            metadata[i] = Metadata(keyValue[0], keyValue[1]);
        }
        return metadata;
    }

    function splitString(string memory str, string memory delimiter) internal pure returns (string[] memory) {
        // Simplified split function, adjust as needed for robustness
        string[] memory parts = new string[](10);
        uint256 partCount = 0;
        bytes memory strBytes = bytes(str);
        bytes memory delimiterBytes = bytes(delimiter);

        uint256 i = 0;
        uint256 start = 0;
        for (i = 0; i < strBytes.length - delimiterBytes.length + 1; i++) {
            bool match = true;
            for (uint256 j = 0; j < delimiterBytes.length; j++) {
                if (strBytes[i + j] != delimiterBytes[j]) {
                    match = false;
                    break;
                }
            }
            if (match) {
                parts[partCount] = string(abi.encodePacked(strBytes[start:i - start]));
                partCount++;
                i += delimiterBytes.length - 1;
                start = i + 1;
            }
        }
        parts[partCount] = string(abi.encodePacked(strBytes[start:i - start]));
        partCount++;
        return parts;
    }
}
