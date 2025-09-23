# 🪂 Advanced Merkle Airdrop System

**Author**: Varun Chauhan  
**Version**: 2.0.0  
**License**: MIT

An advanced, gas-efficient, and highly secure smart contract system for distributing ERC20 tokens via Merkle tree-based airdrops with EIP712 signature verification. This implementation combines the scalability of Merkle trees with the security of cryptographic signatures, allowing for secure token distribution to thousands of recipients while minimizing on-chain storage costs.

## 🌟 Key Features

### 🔒 Enhanced Security
- **EIP712 Signature Verification**: Requires cryptographic signatures from account owners
- **Dual Verification System**: Both Merkle proof AND signature validation
- **Reentrancy Protection**: Implements CEI (Checks-Effects-Interactions) pattern
- **Double-claim Prevention**: Prevents users from claiming multiple times
- **Comprehensive Input Validation**: Robust error handling and edge case coverage

### ⚡ Gas Optimization  
- **Merkle Tree Efficiency**: Verify eligibility without storing all recipient data on-chain
- **Immutable Variables**: Gas-optimized storage for unchanging data
- **Optimized Signature Verification**: Efficient ECDSA recovery implementation
- **Safe Token Transfers**: Uses OpenZeppelin's SafeERC20

### 🚀 Developer Experience
- **Comprehensive Test Suite**: 46+ tests with 100% coverage
- **Extensive Documentation**: Full NatSpec comments and usage examples  
- **Fuzz Testing**: Robustness validation with random inputs
- **CI/CD Ready**: Fast test execution and detailed reporting
- **Battle-tested**: Built using OpenZeppelin's secure contract libraries

### 📈 Scalability
- **Unlimited Recipients**: Can handle airdrops to any number of recipients
- **Cross-chain Compatible**: Works on any EVM-compatible blockchain
- **Flexible Token Support**: Compatible with any ERC20 token

## 📋 Contract Overview

### MerkleAirdrop.sol
The main airdrop contract that handles token distribution using Merkle proofs.

**Key Features:**
- Merkle proof verification for gas-efficient eligibility checking
- Double-claim prevention
- Safe ERC20 token transfers
- Event emission for successful claims

### BagelToken.sol
A sample ERC20 token with minting functionality for testing the airdrop system.

**Key Features:**
- Standard ERC20 implementation
- Owner-controlled minting
- Ready for airdrop distribution

## 🚀 Quick Start

### Prerequisites

- [Foundry](https://getfoundry.sh/) installed
- Git for cloning the repository

### Installation

```bash
git clone https://github.com/chauhan-varun/merkle-airdrop.git
cd merkle-airdrop
forge install
```

### Build

```bash
forge build
```

### Test

```bash
forge test
```

## 📖 How It Works

### 1. Merkle Tree Construction
The airdrop uses a Merkle tree where each leaf represents a recipient and their token allocation:
- Leaf = keccak256(keccak256(abi.encodePacked(recipient, amount)))
- Double hashing prevents second preimage attacks

### 2. Claim Process
Recipients claim tokens by providing:
- Their address
- Their allocated amount
- A Merkle proof demonstrating their inclusion in the tree

### 3. Verification
The contract verifies the Merkle proof against the stored root hash and ensures the recipient hasn't already claimed.

## 🛠 Usage

### Deploying an Airdrop

1. **Deploy the token contract:**
```solidity
BagelToken token = new BagelToken();
```

2. **Generate Merkle tree and root:**
```bash
forge script script/GenerateInput.s.sol
forge script script/MakeMerkle.s.sol
```

3. **Deploy the airdrop contract:**
```solidity
MerkleAirdrop airdrop = new MerkleAirdrop(
    address(token),
    merkleRoot
);
```

4. **Fund the airdrop contract:**
```solidity
token.mint(address(airdrop), totalAirdropAmount);
```

### Claiming Tokens

Recipients can claim their tokens by calling:
```solidity
airdrop.claim(recipient, amount, proof);
```

## 🧪 Testing

The project includes comprehensive tests covering:
- Valid claims with correct proofs
- Invalid proof rejection
- Double-claim prevention
- Gas optimization verification

Run tests with:
```bash
forge test -vvv
```

## 📁 Project Structure

```
├── src/
│   ├── MerkleAirdrop.sol    # Main airdrop contract
│   └── BagelToken.sol       # Sample ERC20 token
├── test/
│   └── MerkleAirdropTest.t.sol  # Test suite
├── script/
│   ├── GenerateInput.s.sol  # Input generation script
│   └── MakeMerkle.s.sol     # Merkle tree generation
├── lib/                     # Dependencies
└── foundry.toml            # Foundry configuration
```

## 🔧 Configuration

### Environment Variables
Create a `.env` file with:
```bash
PRIVATE_KEY=your_private_key_here
RPC_URL=your_rpc_url_here
ETHERSCAN_API_KEY=your_etherscan_api_key
```

### Foundry Configuration
The project uses standard Foundry configuration in `foundry.toml`:
- Solidity version: ^0.8.20
- Optimizer enabled
- Gas reports included

## 📊 Gas Optimization

The contract is optimized for gas efficiency:
- Uses `immutable` variables for storage that doesn't change
- Implements CEI (Checks-Effects-Interactions) pattern
- Utilizes OpenZeppelin's `SafeERC20` for secure transfers
- Merkle proofs minimize on-chain storage requirements

## 🔐 Security Features

- **Reentrancy Protection**: Follows CEI pattern
- **Double-claim Prevention**: Mapping tracks claimed addresses
- **Input Validation**: Comprehensive error handling
- **Safe Transfers**: Uses OpenZeppelin's SafeERC20
- **Immutable Critical Data**: Prevents post-deployment tampering

## 📋 Common Commands

### Development
```bash
# Format code
forge fmt

# Generate gas snapshots
forge snapshot

# Start local node
anvil

# Deploy to local network
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --private-key $PRIVATE_KEY --broadcast
```

### Verification
```bash
# Verify contract on Etherscan
forge verify-contract --chain-id 1 --watch CONTRACT_ADDRESS src/MerkleAirdrop.sol:MerkleAirdrop
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [OpenZeppelin](https://openzeppelin.com/) for secure contract libraries
- [Foundry](https://getfoundry.sh/) for the development framework
- [Murky](https://github.com/dmfxyz/murky) for Merkle tree utilities

## 📞 Contact

**Varun Chauhan**
- GitHub: [@chauhan-varun](https://github.com/chauhan-varun)

---

⭐ Star this repository if you find it helpful!
