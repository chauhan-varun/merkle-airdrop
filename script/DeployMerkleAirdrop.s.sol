// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {MerkleAirdrop, IERC20} from "../src/MerkleAirdrop.sol";
import {BagelToken} from "../src/BagelToken.sol";

contract DeployMerkleAirdrop is Script {
    bytes32 public constant ROOT =
        0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    uint256 public constant AMOUNT_TO_SEND = 4 * 25e18;

    function deployMerkleAirdrop() public returns (MerkleAirdrop, BagelToken) {
        // Start broadcasting transactions
        vm.startBroadcast();
        // Deploy BagelToken
        BagelToken bagelToken = new BagelToken();

        // Deploy MerkleAirdrop with the address of BagelToken and the merkle root
        MerkleAirdrop merkleAirdrop = new MerkleAirdrop(
            ROOT,
            bagelToken
        );
        // Mint some tokens to the deployer
        bagelToken.mint(bagelToken.owner(), AMOUNT_TO_SEND);
        // Transfer some tokens to the MerkleAirdrop contract
        bagelToken.transfer(address(merkleAirdrop), AMOUNT_TO_SEND);
        // Stop broadcasting transactions
        vm.stopBroadcast();
        return (merkleAirdrop, bagelToken);
    }

    function run() external returns (MerkleAirdrop, BagelToken) {
        return deployMerkleAirdrop();
    }
}
