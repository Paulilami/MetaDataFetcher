# MetaDataFetcher

MetaDataFetcher is a private project by Paul Ilami, designed to fetch and integrate both on-chain and off-chain metadata for ERC721 and ERC1155 tokens by simply providing the token ID.

## Features

- Fetch metadata for ERC721 and ERC1155 tokens.
- Retrieve both on-chain and off-chain metadata.
- Handle encrypted data and return the hash of the metadata.
- Query specific metadata or fetch all metadata associated with a token ID.

## Components

1. **Smart Contracts**
    - Core contract for fetching and storing metadata.
    - Chainlink client integration for off-chain data fetching.
2. **External Adapter**
    - Node.js service to interact with external data sources.
    - Fetch and process off-chain metadata.
3. **Chainlink Node Configuration**
    - Configuration for Chainlink nodes to use the external adapter.
4. **Deployment Scripts**
    - Scripts to deploy the smart contract and configure the Chainlink node.
5. **Testing Suite**
    - Tests to ensure smooth integration between the smart contract and the external adapter.
6. **Optional Frontend**
    - Interface for interacting with the protocol.

## Environment Variables

Create a `.env` file in the root directory and add the following environment variables:

```plaintext
RINKEBY_URL=https://rinkeby.infura.io/v3/YOUR_INFURA_PROJECT_ID
MAINNET_URL=https://mainnet.infura.io/v3/YOUR_INFURA_PROJECT_ID
PRIVATE_KEY=YOUR_PRIVATE_KEY
CHAINLINK_NODE_URL=http://localhost:6688
CHAINLINK_NODE_USERNAME=your-username
CHAINLINK_NODE_PASSWORD=your-password
```
## Getting Started

Clone the repository:

```bash
git clone https://github.com/paulilami/MetaDataFetcher.git
cd MetaDataFetcher
```

Install dependencies:

```bash
npm install
```

Deploy the smart contract:

```bash
npx hardhat run scripts/deploy.js --network rinkeby
```

Configure the Chainlink node:

```bash
node scripts/configure-chainlink-node.js
```

Run the tests:

```bash
npx hardhat test
```

##License

This project is licensed under the MIT License.

