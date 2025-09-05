// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleAirdrop {
    using SafeERC20 for IERC20;

    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__AlreadyClaimed();

    address[] private recipients;
    IERC20 private immutable i_airdropToken;
    bytes32 public i_merkleRoot;

    mapping(address claimer => bool claimed) public s_hasClaimed;

    event Claimed(address indexed recipient, uint256 amount);

    constructor(address airdropToken, bytes32 merkleRoot) {
        i_airdropToken = IERC20(airdropToken);
        i_merkleRoot = merkleRoot;
    }

    function claim(
        address recipient,
        uint256 amount,
        bytes32[] calldata proof
    ) external {
        if (s_hasClaimed[recipient]) {
            revert MerkleAirdrop__AlreadyClaimed();
        }

        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encodePacked(recipient, amount)))
        );

        if (!MerkleProof.verify(proof, i_merkleRoot, leaf))
            revert MerkleAirdrop__InvalidProof();

        s_hasClaimed[recipient] = true;
        emit Claimed(recipient, amount);
        i_airdropToken.safeTransfer(recipient, amount);
    }

    function getAirdropToken() external view returns (address) {
        return address(i_airdropToken);
    }

    function getMerkleRoot() external view returns (bytes32) {
        return i_merkleRoot;
    }
}
