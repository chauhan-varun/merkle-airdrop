// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title BagelToken
 * @author Varun Chauhan
 * @notice A simple ERC20 token with minting functionality restricted to the owner
 * @dev This token is designed to be used as the airdrop token in the MerkleAirdrop contract
 * The token follows the ERC20 standard and includes OpenZeppelin's Ownable for access control
 */
contract BagelToken is ERC20, Ownable {
    
    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Initializes the Bagel Token with name "Bagel Token" and symbol "BT"
     * @dev Sets the deployer as the initial owner who can mint tokens
     */
    constructor() ERC20("Bagel Token", "BT") Ownable(msg.sender) {}

    /*//////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Mints new tokens to a specified account
     * @param account The address to receive the newly minted tokens
     * @param amount The amount of tokens to mint
     * @dev Only the contract owner can call this function
     * 
     * Requirements:
     * - Only the owner can mint tokens
     * - Account cannot be the zero address (enforced by OpenZeppelin's _mint)
     */
    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }
}
