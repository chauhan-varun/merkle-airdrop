// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {Script} from "forge-std/Script.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {BagelToken} from "../src/BagelToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract ClaimAirdrop is Script {
    address public constant CLAIMING_ADDRESS =
        0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 public constant CLAIMING_AMOUNT = 25e18;
    bytes32 public constant PROOF1 =
        0xd1445c931158119b00449ffcac3c947d028c0c359c34a6646d95962b3b55c6ad;
    bytes32 public constant PROOF2 =
        0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] public PROOF = [PROOF1, PROOF2];

    function claimAirdrop(address airdrop) public {
        vm.startBroadcast();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d,
            MerkleAirdrop(airdrop).getMessageHash(
                CLAIMING_ADDRESS,
                CLAIMING_AMOUNT
            )
        );

        MerkleAirdrop(airdrop).claim(
            CLAIMING_ADDRESS,
            CLAIMING_AMOUNT,
            PROOF,
            v,
            r,
            s
        );
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentDeployment = DevOpsTools.get_most_recent_deployment(
            "MerkleAirdrop",
            block.chainid
        );
        claimAirdrop(mostRecentDeployment);
    }
}
