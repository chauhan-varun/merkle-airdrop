// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/**
 * @title MerkleAirdrop - Advanced signature-verified merkle tree airdrop system
 * @author Varun Chauhan 
 * @notice A secure contract for distributing ERC20 tokens via merkle tree-based airdrops with EIP712 signature verification
 * @dev This contract combines merkle proof verification with EIP712 signature validation for enhanced security
 *
 * The airdrop process requires two verification steps:
 * 1. Merkle proof verification to ensure the user is eligible for the specified amount
 * 2. EIP712 signature verification to ensure the claim is authorized by the account owner
 *
 * Features:
 * - Merkle tree-based eligibility verification
 * - EIP712 typed data signature verification
 * - Double-claim prevention
 * - Safe token transfers using OpenZeppelin's SafeERC20
 * - Gas-optimized design with immutable variables
 *
 * Security considerations:
 * - Uses double-hashing for leaf nodes to prevent second preimage attacks
 * - Implements CEI (Checks-Effects-Interactions) pattern
 * - Requires valid signature from the claiming account
 * - Prevents reentrancy through claim state tracking
 */
contract MerkleAirdrop is EIP712 {
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Thrown when an invalid merkle proof is provided during claim attempt
    error MerkleAirdrop__InvalidProof();

    /// @notice Thrown when a recipient attempts to claim tokens more than once
    error MerkleAirdrop__AlreadyClaimed();

    /// @notice Thrown when the provided signature is invalid or doesn't match the expected signer
    error MerkleAirdrop__InvalidSignature();

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice The ERC20 token being distributed in the airdrop
    /// @dev Immutable to save gas and prevent malicious token swapping after deployment
    IERC20 private immutable i_airdropToken;

    /// @notice The merkle root hash representing the entire distribution tree
    /// @dev Immutable for security - prevents tampering with the distribution after deployment
    bytes32 private immutable i_merkleRoot;

    /// @notice Mapping to track which addresses have already claimed their tokens
    /// @dev Prevents double-claiming by the same address, key security feature
    mapping(address => bool) private s_hasClaimed;

    /// @notice EIP712 type hash for the AirdropClaim struct used in signature verification
    /// @dev This constant defines the structure of data that must be signed
    bytes32 private constant MESSAGE_TYPEHASH =
        keccak256("AirdropClaim(address account,uint256 amount)");

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Struct defining the data structure for EIP712 signature verification
    /// @dev This struct must match the MESSAGE_TYPEHASH for proper signature validation
    /// @param account The address of the account claiming the airdrop
    /// @param amount The amount of tokens the account is eligible to claim
    struct AirdropClaim {
        address account;
        uint256 amount;
    }

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a recipient successfully claims their airdrop tokens
    /// @param account The address that successfully claimed tokens
    /// @param amount The amount of tokens that were claimed and transferred
    event Claimed(address indexed account, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the airdrop contract with EIP712 domain, merkle root, and token address
     * @param merkleRoot The root hash of the merkle tree containing all eligible recipients and amounts
     * @param airdropToken The address of the ERC20 token to be distributed in the airdrop
     * @dev The contract should be funded with sufficient tokens after deployment
     * @dev Inherits from EIP712 with domain name "Merkle Airdrop" and version "1.0.0"
     *
     * Requirements:
     * - merkleRoot must be a valid bytes32 hash representing the distribution tree
     * - airdropToken must be a valid ERC20 token contract address
     *
     * Effects:
     * - Sets the immutable merkle root for claim verification
     * - Sets the immutable airdrop token address
     * - Initializes EIP712 domain separator for signature verification
     */
    constructor(
        bytes32 merkleRoot,
        IERC20 airdropToken
    ) EIP712("Merkle Airdrop", "1.0.0") {
        i_merkleRoot = merkleRoot;
        i_airdropToken = airdropToken;
    }

    /*//////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Allows eligible recipients to claim their airdrop tokens with signature verification
     * @param account The address of the account claiming tokens (must match signature signer)
     * @param amount The amount of tokens the account is eligible to claim
     * @param merkleProof The merkle proof demonstrating the account's eligibility and amount
     * @param v The recovery byte of the ECDSA signature
     * @param r The first 32 bytes of the ECDSA signature
     * @param s The second 32 bytes of the ECDSA signature
     *
     * @dev This function implements a dual-verification system:
     * 1. EIP712 signature verification ensures the claim is authorized by the account owner
     * 2. Merkle proof verification ensures the account is eligible for the specified amount
     *
     * @dev The leaf node is constructed by double-hashing (account, amount) to prevent second preimage attacks
     * @dev Uses SafeERC20 for secure token transfers and follows CEI pattern
     *
     * Requirements:
     * - The account must not have already claimed tokens
     * - The signature (v,r,s) must be valid for the account and amount using EIP712
     * - The merkle proof must be valid for the given account and amount
     * - The contract must have sufficient token balance for the transfer
     *
     * Effects:
     * - Marks the account as having claimed to prevent double-claiming
     * - Transfers the specified amount of tokens to the account
     * - Emits a {Claimed} event
     *
     * @custom:security This function is protected against:
     * - Replay attacks (through claim state tracking)
     * - Signature malleability (through EIP712 structured data)
     * - Invalid merkle proofs (through OpenZeppelin's MerkleProof library)
     * - Reentrancy (through state updates before external calls)
     */
    function claim(
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        // Check: Ensure the account hasn't already claimed
        if (s_hasClaimed[account]) {
            revert MerkleAirdrop__AlreadyClaimed();
        }

        // Check: Verify the EIP712 signature
        if (
            !_isValidSignature(
                account,
                getMessageHash(account, amount),
                v,
                r,
                s
            )
        ) {
            revert MerkleAirdrop__InvalidSignature();
        }

        // Check: Verify the merkle proof
        // Calculate the leaf node hash using double-hashing for security
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(account, amount)))
        );
        // Verify the merkle proof against the stored root
        if (!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)) {
            revert MerkleAirdrop__InvalidProof();
        }

        // Effect: Mark as claimed to prevent double-claiming and reentrancy
        s_hasClaimed[account] = true;

        // Effect: Emit event before external call (CEI pattern)
        emit Claimed(account, amount);

        // Interaction: Transfer tokens using SafeERC20 for security
        i_airdropToken.safeTransfer(account, amount);
    }

    /**
     * @notice Generates the EIP712 compliant message hash for signature verification
     * @param account The address of the account claiming tokens
     * @param amount The amount of tokens being claimed
     * @return The EIP712 structured data hash that should be signed by the account owner
     *
     * @dev This function creates the message hash using EIP712 typed data hashing
     * @dev The hash includes the domain separator to prevent cross-contract signature replay
     * @dev Uses the MESSAGE_TYPEHASH constant to ensure consistent struct encoding
     *
     * The message structure follows EIP712 standard:
     * - Domain separator (contract address, chain ID, name, version)
     * - Type hash (AirdropClaim struct definition)
     * - Struct data (account address and amount)
     */
    function getMessageHash(
        address account,
        uint256 amount
    ) public view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        MESSAGE_TYPEHASH,
                        AirdropClaim({account: account, amount: amount})
                    )
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                             VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the merkle root hash of the distribution tree
     * @return The bytes32 merkle root used to verify claims
     * @dev This root represents the entire airdrop distribution and cannot be changed after deployment
     */
    function getMerkleRoot() external view returns (bytes32) {
        return i_merkleRoot;
    }

    /**
     * @notice Returns the ERC20 token contract being distributed
     * @return The IERC20 interface of the airdrop token
     * @dev This token address cannot be changed after deployment for security
     */
    function getAirdropToken() external view returns (IERC20) {
        return i_airdropToken;
    }

    /**
     * @notice Checks if an account has already claimed their airdrop tokens
     * @param account The address to check claim status for
     * @return True if the account has claimed, false otherwise
     * @dev This mapping prevents double-claiming and is publicly readable for transparency
     */
    function hasClaimed(address account) external view returns (bool) {
        return s_hasClaimed[account];
    }

    /*//////////////////////////////////////////////////////////////
                         INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Validates that a signature was created by the expected signer
     * @param signer The expected address that should have created the signature
     * @param digest The message hash that was signed (EIP712 compliant)
     * @param _v The recovery byte of the ECDSA signature (27 or 28)
     * @param _r The first 32 bytes of the ECDSA signature
     * @param _s The second 32 bytes of the ECDSA signature
     * @return True if the signature is valid for the given signer and digest, false otherwise
     *
     * @dev Uses ECDSA.tryRecover to safely recover the signer address from the signature
     * @dev This method is gas-efficient and handles malformed signatures gracefully
     * @dev Alternative implementation using SignatureChecker is commented below for reference
     *
     * Security considerations:
     * - Uses tryRecover instead of recover to handle invalid signatures without reverting
     * - Compares recovered address directly to prevent signature malleability
     * - Pure function to ensure no state dependencies
     */
    function _isValidSignature(
        address signer,
        bytes32 digest,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal pure returns (bool) {
        // Safely recover the signer address from the signature components
        // tryRecover returns (address, RecoverError, bytes32) but we only need the address
        (address actualSigner, , ) = /*ECDSA.RecoverError recoverError*/
        /*bytes32 signatureLength*/
        ECDSA.tryRecover(digest, _v, _r, _s);

        // Return true only if the recovered signer matches the expected signer
        return (actualSigner == signer);
    }

    /*
     * Alternative implementation using SignatureChecker for smart contract wallet support:
     *
     * function _isValidSignature(
     *     address signer,
     *     bytes32 digest,
     *     uint8 _v,
     *     bytes32 _r,
     *     bytes32 _s
     * )
     *     internal
     *     view
     *     returns (bool)
     * {
     *     bytes memory signature = abi.encodePacked(_r, _s, _v);
     *     return SignatureChecker.isValidSignatureNow(signer, digest, signature);
     * }
     */
}
