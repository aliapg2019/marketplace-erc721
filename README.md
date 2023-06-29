# Marketplace-ERC721

Marketplace-ERC721 is a decentralized marketplace for buying and selling ERC721 tokens on the Ethereum blockchain.

## Requirements

To run Marketplace-ERC721, you'll need:

- Node.js v12 or later
- Truffle v5 or later
- Ganache v2 or later
- MetaMask browser extension

## Installation

1. Clone the repository: `git clone https://github.com/aliapg2019/marketplace-erc721.git`
2. Install dependencies: `npm install`

## Setup

1. Start Ganache: `ganache-cli`
2. Compile the contracts: `truffle compile`
3. Migrate the contracts to the local blockchain: `truffle migrate`
4. Deploy the frontend: `npm run dev`
5. Connect to your local blockchain using MetaMask

## Usage

To use Marketplace-ERC721, you can buy or sell ERC721 tokens on the marketplace.

The contract is located in `contracts/Marketplace.sol`. You can find its ABI in `build/contracts/Marketplace.json`.

## Contributing

If you find a bug or have an idea for a new feature, feel free to submit an issue or pull request.

## License

Marketplace-ERC721 is released under the [MIT License](https://github.com/aliapg2019/marketplace-erc721/blob/main/LICENSE).
