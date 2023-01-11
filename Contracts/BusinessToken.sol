// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// @title BusinessToken
// @author @github/omercsoylu
// Please ensure to add BusinessWorld as owner to contract with addOwner function to access this contract.

contract BusinessToken is ERC20 {
    mapping(address => bool) private owners;

    modifier onlyOwners() {
        require(owners[msg.sender] == true, "You're not one of owners.");
        _;
    }

    constructor() ERC20("BusinessToken", "BST") {
        owners[msg.sender] = true;
    }

    function addOwner(address _ownerAddress) external onlyOwners {
        owners[_ownerAddress] = true;
    }

    function removeOwner(address _removeAddress) external onlyOwners {
        delete owners[_removeAddress];
    }

    function mintToken(address _toAddress, uint256 _amount)
        external
        onlyOwners
    {
        _mint(_toAddress, _amount);
    }


}
