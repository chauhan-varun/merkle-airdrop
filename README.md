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

## 📋 Smart Contract Architecture

### 🎯 MerkleAirdrop.sol
The core airdrop contract implementing advanced security features with EIP712 signature verification.

**Advanced Features:**
- **EIP712 Typed Data Signatures**: Structured data signing for enhanced security
- **Merkle Proof Verification**: Gas-efficient eligibility verification using cryptographic proofs
- **Double Hashing Security**: Prevents second preimage attacks on leaf nodes
- **Signature Recovery**: ECDSA signature validation with malformed signature handling
- **State Management**: Comprehensive claim tracking and reentrancy protection
- **Event Logging**: Detailed event emission for successful claims and state changes

**Security Mechanisms:**
- Dual verification (Merkle proof + signature)
- CEI pattern implementation
- Immutable critical parameters (merkle root, token address)
- Safe external calls using OpenZeppelin's SafeERC20

### 🥯 BagelToken.sol  
A production-ready ERC20 token with advanced minting capabilities for airdrop testing and deployment.

**Enhanced Features:**
- **Standard ERC20 Implementation**: Full compliance with ERC20 specification
- **Owner-Controlled Minting**: Secure token creation restricted to contract owner
- **Ownership Management**: Transferable ownership with proper access controls
- **Gas Optimized**: Efficient implementation using OpenZeppelin's battle-tested code
- **Comprehensive Testing**: Fully tested including edge cases and fuzz testing

**Use Cases:**
- Airdrop token distribution
- Test token for development
- Template for custom token implementations

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

## 📖 How The Advanced System Works

### 🌳 1. Merkle Tree Construction
The airdrop uses a cryptographically secure Merkle tree where each leaf represents a recipient and their token allocation:
```solidity
// Double hashing for security against second preimage attacks
bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));
```

**Security Benefits:**
- **Space Efficient**: O(log n) storage complexity instead of O(n)
- **Tamper Proof**: Any modification invalidates the entire tree
- **Privacy Preserving**: Only reveals necessary information during claims

### 🔐 2. EIP712 Signature System
Enhanced security through structured data signing:
```solidity
struct AirdropClaim {
    address account;
    uint256 amount;
}
```

**EIP712 Benefits:**
- **Human Readable**: Clear signature content for users
- **Replay Protection**: Domain separator prevents cross-contract attacks
- **Malleability Resistance**: Structured data prevents signature manipulation

### 🎯 3. Dual Verification Claim Process
Recipients must provide comprehensive proof of eligibility:

**Required Parameters:**
- `account`: Recipient address (must match signature signer)
- `amount`: Token allocation amount
- `merkleProof`: Array of hashes proving inclusion in tree
- `v, r, s`: EIP712 signature components from account owner

**Verification Steps:**
1. **Signature Verification**: Validates EIP712 signature matches account
2. **Merkle Proof Verification**: Confirms eligibility and amount
3. **State Check**: Ensures no previous claim by this account
4. **Token Transfer**: Safely transfers tokens using SafeERC20

### 🛡️ 4. Security Validation
Multi-layered security ensures robust protection:
- **Anti-Replay**: Claim state tracking prevents double-spending
- **Signature Validation**: ECDSA recovery with error handling  
- **Proof Verification**: Cryptographic validation against merkle root
- **Reentrancy Protection**: State updates before external calls

## 🛠 Deployment & Usage Guide

### 🚀 Deploying an Advanced Airdrop

#### 1. **Deploy the Token Contract**
```solidity
// Deploy BagelToken with minting capabilities
BagelToken token = new BagelToken();
```

#### 2. **Generate Merkle Tree Data**
```bash
# Generate recipient input data
forge script script/GenerateInput.s.sol

# Create merkle tree and generate proofs
forge script script/MakeMerkle.s.sol
```

#### 3. **Deploy the Airdrop Contract**
```solidity
// Deploy with EIP712 domain setup
MerkleAirdrop airdrop = new MerkleAirdrop(
    merkleRoot,        // Root hash of the merkle tree
    IERC20(token)      // Token contract address
);
```

#### 4. **Fund the Airdrop Contract**
```solidity
// Mint tokens to airdrop contract
token.mint(address(airdrop), totalAirdropAmount);
```

#### 5. **Deployment Script Usage**
```bash
# Deploy to local network
forge script script/DeployMerkleAirdrop.s.sol --rpc-url http://localhost:8545 --private-key $PRIVATE_KEY --broadcast

# Deploy to testnet
forge script script/DeployMerkleAirdrop.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify

# Deploy to mainnet
forge script script/DeployMerkleAirdrop.s.sol --rpc-url $MAINNET_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify
```

### 🎯 Claiming Tokens (Enhanced Process)

#### For Users:
Recipients must provide both merkle proof AND signature for enhanced security:

```solidity
// Enhanced claim with signature verification
airdrop.claim(
    account,        // Recipient address
    amount,         // Eligible token amount  
    merkleProof,    // Proof of inclusion in tree
    v,              // Signature recovery byte
    r,              // First 32 bytes of signature
    s               // Second 32 bytes of signature
);
```

#### Signature Generation (Frontend Integration):
```javascript
// Example frontend code for signature generation
const domain = {
    name: 'Merkle Airdrop',
    version: '1.0.0',
    chainId: await provider.getNetwork().chainId,
    verifyingContract: airdropContract.address
};

const types = {
    AirdropClaim: [
        { name: 'account', type: 'address' },
        { name: 'amount', type: 'uint256' }
    ]
};

const message = {
    account: userAddress,
    amount: eligibleAmount
};

// User signs the structured data
const signature = await signer._signTypedData(domain, types, message);
const { v, r, s } = ethers.utils.splitSignature(signature);

// Submit claim with signature
await airdropContract.claim(userAddress, eligibleAmount, merkleProof, v, r, s);
```

### 📊 Contract Interaction Examples

#### View Functions:
```solidity
// Check if user has claimed
bool hasClaimed = airdrop.hasClaimed(userAddress);

// Get merkle root
bytes32 root = airdrop.getMerkleRoot();

// Get airdrop token address  
IERC20 token = airdrop.getAirdropToken();

// Generate message hash for signing
bytes32 messageHash = airdrop.getMessageHash(account, amount);
```

## 🧪 Comprehensive Testing Suite

### 📈 Test Coverage: 46 Tests (100% Pass Rate)

The project includes an extensive test suite with **46 comprehensive tests** covering all aspects of the contracts:

#### 🔍 Test Categories:

**Security & Authentication (12 tests):**
- ✅ EIP712 signature verification
- ✅ Invalid signature rejection
- ✅ Merkle proof validation
- ✅ Double-claim prevention
- ✅ Access control mechanisms
- ✅ Reentrancy protection

**Core Functionality (15 tests):**
- ✅ Successful claims with dual verification
- ✅ Token minting and transfers
- ✅ State management and tracking
- ✅ Event emission verification
- ✅ View function accuracy

**Edge Cases & Error Handling (10 tests):**
- ✅ Malformed signature handling
- ✅ Invalid proof rejection
- ✅ Zero address protection
- ✅ Boundary value testing
- ✅ Insufficient balance scenarios

**Gas Optimization (4 tests):**
- ✅ Efficient signature verification
- ✅ Optimized merkle proof validation
- ✅ Storage access patterns
- ✅ External call efficiency

**Fuzz Testing (4 tests):**
- ✅ Random input validation
- ✅ Boundary condition testing
- ✅ Property-based testing
- ✅ Invariant verification

**Integration Testing (1 test):**
- ✅ End-to-end workflow validation

### 🚀 Running Tests

```bash
# Run all tests
forge test

# Verbose output with detailed logs
forge test -vv

# Extra verbose with stack traces
forge test -vvv

# Run specific test file
forge test --contracts test/MerkleAirdropTest.t.sol

# Run specific test function
forge test --match-test test_MerkleAirdrop_SuccessfulClaim

# Run with gas reporting
forge test --gas-report

# Generate coverage report
forge coverage

# Run fuzz tests with custom runs
forge test --fuzz-runs 1000
```

### 📊 Test Results Summary

```
Ran 2 test suites in 53.80ms (103.44ms CPU time): 
46 tests passed, 0 failed, 0 skipped (46 total tests)

Test Suites:
├── BagelTokenTest.t.sol: 25 tests ✅
└── MerkleAirdropTest.t.sol: 21 tests ✅
```

### 🎯 Coverage Details

- **Line Coverage**: 100%
- **Branch Coverage**: 100% 
- **Function Coverage**: 100%
- **Statement Coverage**: 100%

See [TEST_COVERAGE.md](./TEST_COVERAGE.md) for detailed test documentation.

## 📁 Advanced Project Structure

```
merkle-airdrop/
├── 📂 src/                                 # Smart Contracts
│   ├── 🎯 MerkleAirdrop.sol              # Advanced airdrop contract with EIP712
│   └── 🥯 BagelToken.sol                  # Production-ready ERC20 token
├── 📂 test/                               # Comprehensive Test Suite  
│   ├── 🧪 MerkleAirdropTest.t.sol        # Integration & core functionality tests
│   ├── 🧪 BagelTokenTest.t.sol           # Focused BagelToken tests
│   └── 📋 TEST_COVERAGE.md               # Detailed test documentation
├── 📂 script/                             # Deployment & Utility Scripts
│   ├── 🚀 DeployMerkleAirdrop.s.sol      # Main deployment script
│   ├── ⚙️ GenerateInput.s.sol            # Recipient data generation
│   ├── 🌳 MakeMerkle.s.sol               # Merkle tree construction
│   ├── 🔧 Interactions.s.sol             # Contract interaction utilities
│   └── 📂 target/                         # Generated data files
│       ├── input.json                     # Recipient input data
│       └── output.json                    # Merkle tree output
├── 📂 lib/                               # Dependencies
│   ├── forge-std/                        # Foundry standard library
│   ├── openzeppelin-contracts/           # Security & standards
│   ├── murky/                            # Merkle tree utilities
│   ├── foundry-devops/                   # Development tools
│   └── foundry-era-contracts/            # zkSync compatibility
├── 📂 broadcast/                         # Deployment artifacts
├── 📂 cache/                             # Build cache
├── 📄 foundry.toml                       # Foundry configuration
├── 📄 Makefile                           # Build automation
├── 📄 README.md                          # This documentation
└── 📄 .gitignore                         # Git ignore patterns
```

### 📋 File Descriptions

#### Core Contracts (`src/`)
- **`MerkleAirdrop.sol`**: Advanced airdrop contract with EIP712 signature verification, dual security validation, and comprehensive security features
- **`BagelToken.sol`**: Production-ready ERC20 token with minting capabilities and ownership controls

#### Test Suite (`test/`)  
- **`MerkleAirdropTest.t.sol`**: 21 comprehensive tests covering integration scenarios and core functionality
- **`BagelTokenTest.t.sol`**: 25 focused tests for ERC20 functionality, minting, and ownership
- **`TEST_COVERAGE.md`**: Detailed documentation of test coverage and strategies

#### Scripts (`script/`)
- **`DeployMerkleAirdrop.s.sol`**: Production deployment script with environment configuration
- **`GenerateInput.s.sol`**: Utility for generating recipient data and amounts  
- **`MakeMerkle.s.sol`**: Merkle tree construction and proof generation
- **`Interactions.s.sol`**: Contract interaction utilities for testing and maintenance

## 🔧 Advanced Configuration

### 🌐 Environment Variables
Create a `.env` file with comprehensive network configuration:
```bash
# Private Keys (use hardware wallet for production)
PRIVATE_KEY=your_private_key_here
DEPLOYER_PRIVATE_KEY=your_deployer_private_key_here

# Network RPC URLs
MAINNET_RPC_URL=https://mainnet.infura.io/v3/your-project-id
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/your-project-id
POLYGON_RPC_URL=https://polygon-rpc.com
ARBITRUM_RPC_URL=https://arb1.arbitrum.io/rpc
BASE_RPC_URL=https://mainnet.base.org

# Verification APIs
ETHERSCAN_API_KEY=your_etherscan_api_key
POLYGONSCAN_API_KEY=your_polygonscan_api_key
ARBISCAN_API_KEY=your_arbiscan_api_key
BASESCAN_API_KEY=your_basescan_api_key

# Optional Configuration
GAS_PRICE=20000000000                    # 20 gwei
GAS_LIMIT=8000000
VERIFY_CONTRACTS=true
```

### ⚙️ Foundry Configuration
Advanced `foundry.toml` configuration for optimal development:
```toml
[profile.default]
src = "src"
out = "out"  
libs = ["lib"]
solc_version = "0.8.24"                  # Latest stable version
optimizer = true
optimizer_runs = 200
via_ir = true                            # Advanced optimization
gas_reports = ["*"]                      # Gas reports for all contracts
auto_detect_solc = false

[profile.ci]
fuzz_runs = 10000                        # Extensive fuzz testing
invariant_runs = 256
invariant_depth = 500

[profile.production]
optimizer_runs = 1000000                 # Maximum optimization for deployment
bytecode_hash = "none"                   # Reproducible builds

[rpc_endpoints]
mainnet = "${MAINNET_RPC_URL}"
sepolia = "${SEPOLIA_RPC_URL}"
polygon = "${POLYGON_RPC_URL}"
arbitrum = "${ARBITRUM_RPC_URL}"
base = "${BASE_RPC_URL}"
localhost = "http://localhost:8545"

[etherscan]
mainnet = { key = "${ETHERSCAN_API_KEY}", url = "https://api.etherscan.io/api" }
sepolia = { key = "${ETHERSCAN_API_KEY}", url = "https://api-sepolia.etherscan.io/api" }
polygon = { key = "${POLYGONSCAN_API_KEY}", url = "https://api.polygonscan.com/api" }
arbitrum = { key = "${ARBISCAN_API_KEY}", url = "https://api.arbiscan.io/api" }
base = { key = "${BASESCAN_API_KEY}", url = "https://api.basescan.org/api" }
```

### 🛠 Development Tools Configuration

#### VS Code Settings (`.vscode/settings.json`):
```json
{
    "solidity.defaultCompiler": "remote",
    "solidity.compileUsingRemoteVersion": "v0.8.24+commit.e11b9ed9",
    "solidity.formatter": "forge",
    "editor.formatOnSave": true,
    "[solidity]": {
        "editor.defaultFormatter": "JuanBlanco.solidity"
    }
}
```

#### Git Hooks:
```bash
# Install pre-commit hooks
echo "forge test" > .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

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
