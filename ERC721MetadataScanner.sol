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
        string queryKey;
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

    function fetchMetadata(address tokenAddress, uint256 tokenId) public {
        IERC721Metadata token = IERC721Metadata(tokenAddress);
        Metadata[] memory onChainMetadata = new Metadata[](3);
        onChainMetadata[0] = Metadata("name", token.name());
        onChainMetadata[1] = Metadata("symbol", token.symbol());
        onChainMetadata[2] = Metadata("tokenURI", token.tokenURI(tokenId));

        metadataStorage[tokenId] = onChainMetadata;

        if (bytes(onChainMetadata[2].value).length > 0) {
            fetchIPFSMetadata(onChainMetadata[2].value, tokenId, queryKey); //fetchIPFSdata will be fetchOffChaindata with an extension
        } else {
            emit MetadataFetched(tokenId, onChainMetadata);
        }
    }

   function fetchOffChainMetadata(string memory uri, uint256 tokenId, string memory queryKey) internal {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        request.add("get", uri);
        request.add("path", ""); //leaving empty to get full JSON 

        bytes32 requestId = sendChainlinkRequestTo(oracle, request, fee);
        requests[requestId] = RequestInfo(msg.sender, tokenId, uri, queryKey);

        emit MetadataRequestSent(requestId, tokenId, uri);
    }

    function fulfill(bytes32 _requestId, bytes32[] memory _keys, bytes32[] memory _values) public recordChainlinkFulfillment(_requestId) {
        RequestInfo memory requestInfo = requests[_requestId];

        Metadata[] memory offChainMetadata = new Metadata[](_keys.length);
        for (uint256 i = 0; i < _keys.length; i++) {
            offChainMetadata[i] = Metadata(string(abi.encodePacked(_keys[i])), string(abi.encodePacked(_values[i])));
        }

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

        if (bytes(requestInfo.queryKey).length > 0) {
            Metadata[] memory filteredMetadata = filterMetadataByKey(allMetadata, requestInfo.queryKey);
            emit MetadataFetched(requestInfo.tokenId, filteredMetadata);
        } else {
            emit MetadataFetched(requestInfo.tokenId, allMetadata);
        }
    }

    function filterMetadataByKey(Metadata[] memory allMetadata, string memory key) internal pure returns (Metadata[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < allMetadata.length; i++) {
            if (keccak256(abi.encodePacked(allMetadata[i].key)) == keccak256(abi.encodePacked(key))) {
                count++;
            }
        }

        Metadata[] memory filteredMetadata = new Metadata[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < allMetadata.length; i++) {
            if (keccak256(abi.encodePacked(allMetadata[i].key)) == keccak256(abi.encodePacked(key))) {
                filteredMetadata[index] = allMetadata[i];
                index++;
            }
        }

        return filteredMetadata;
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
