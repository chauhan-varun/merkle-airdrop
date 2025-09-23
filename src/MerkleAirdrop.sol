// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title MerkleAirdrop
 * @author Varun Chauhan
 * @notice A contract for distributing ERC20 tokens via merkle tree-based airdrops
 * @dev This contract allows eligible recipients to claim tokens by providing a valid merkle proof
 * The merkle tree is constructed with recipient addresses and their corresponding token amounts
 * Each recipient can only claim once, preventing double-spending attacks
 */
contract MerkleAirdrop {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Thrown when an invalid merkle proof is provided
    error MerkleAirdrop__InvalidProof();
    
    /// @notice Thrown when a recipient attempts to claim tokens more than once
    error MerkleAirdrop__AlreadyClaimed();

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Array to store all recipient addresses (currently unused but available for future enhancements)
    address[] private recipients;
    
    /// @notice The ERC20 token being distributed in the airdrop
    /// @dev Immutable to save gas and prevent malicious token swapping
    IERC20 private immutable i_airdropToken;
    
    /// @notice The merkle root hash representing the entire distribution tree
    /// @dev Immutable for security - prevents tampering with the distribution
    bytes32 public i_merkleRoot;

    /// @notice Mapping to track which addresses have already claimed their tokens
    /// @dev Prevents double-claiming by the same address
    mapping(address claimer => bool claimed) public s_hasClaimed;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Emitted when a recipient successfully claims their airdrop tokens
    /// @param recipient The address that claimed the tokens
    /// @param amount The amount of tokens claimed
    event Claimed(address indexed recipient, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Initializes the airdrop contract with the token and merkle root
     * @param airdropToken The address of the ERC20 token to be distributed
     * @param merkleRoot The root hash of the merkle tree containing all eligible recipients and amounts
     * @dev The contract should be funded with sufficient tokens after deployment
     */
    constructor(address airdropToken, bytes32 merkleRoot) {
        i_airdropToken = IERC20(airdropToken);
        i_merkleRoot = merkleRoot;
    }

    /*//////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Allows eligible recipients to claim their airdrop tokens
     * @param recipient The address of the recipient claiming tokens
     * @param amount The amount of tokens the recipient is eligible to claim
     * @param proof The merkle proof demonstrating the recipient's eligibility
     * @dev The leaf is constructed by double-hashing the recipient address and amount
     * @dev Uses SafeERC20 for secure token transfers
     * 
     * Requirements:
     * - The recipient must not have already claimed
     * - The merkle proof must be valid for the given recipient and amount
     * - The contract must have sufficient token balance
     * 
     * Emits a {Claimed} event upon successful claim
     */
    function claim(
        address recipient,
        uint256 amount,
        bytes32[] calldata proof
    ) external {
        if (s_hasClaimed[recipient]) {
            revert MerkleAirdrop__AlreadyClaimed();
        }

        // Create leaf node by double-hashing recipient and amount
        // This prevents second preimage attacks
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encodePacked(recipient, amount)))
        );

        // Verify the merkle proof
        if (!MerkleProof.verify(proof, i_merkleRoot, leaf))
            revert MerkleAirdrop__InvalidProof();

        // Mark as claimed to prevent re-entry
        s_hasClaimed[recipient] = true;
        
        // Emit event before external call for CEI pattern
        emit Claimed(recipient, amount);
        
        // Transfer tokens using SafeERC20
        i_airdropToken.safeTransfer(recipient, amount);
    }

    /*//////////////////////////////////////////////////////////////
                             VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Returns the address of the token being distributed
     * @return The address of the ERC20 airdrop token
     */
    function getAirdropToken() external view returns (address) {
        return address(i_airdropToken);
    }

    /**
     * @notice Returns the merkle root hash of the distribution tree
     * @return The bytes32 merkle root used to verify claims
     */
    function getMerkleRoot() external view returns (bytes32) {
        return i_merkleRoot;
    }
}
