// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {BagelToken} from "../src/BagelToken.sol";

contract MerkleProofTest is Test {
    MerkleAirdrop public merkleAirdrop;
    BagelToken public bagelToken;
    address public user;
    uint256 public privateKey;
    bytes32 public merkleRoot =
        0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;

    function setUp() public {
        bagelToken = new BagelToken();

        merkleAirdrop = new MerkleAirdrop(address(bagelToken), merkleRoot);
        (user, privateKey) = makeAddrAndKey("user");
    }

    function testClaim() public view {
        console2.log("User address:", user);
    }
}
