// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBusinessToken {
    function mintToken(address _toAddress, uint256 _amount) external;

    function totalSupply() external view returns (uint256);
}

interface IBusinessCard {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function approve(address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
}

contract BusinessWorld {
    // Modifiers
    modifier onlyOwner() {
        require(owner == msg.sender, "You're not owner.");
        _;
    }

    //Struct
    struct Company {
        string name;
        uint256 maxEmployment;
        uint256 baseSalary;
    }
    // count for company id
    uint256 private companyCount;
    // mapping from id to company
    mapping(uint256 => Company) public companies;

    //Variables
    address private owner;
    address immutable businessToken;
    address immutable businessCard;

    //

    //

    constructor(address _token, address _nftoken) {
        // owner assigned.
        owner = msg.sender;
        // businessToken is ERC20. This contract access some function with own interface.
        businessToken = _token;
        // businessToken is ERC721. This contract access some function with own interface.
        businessCard = _nftoken;

    }

    // Only owner can established company.
    function establishCompany(
        string memory _companyName,
        uint256 _maxEmployment,
        uint256 _baseSalary
    ) external onlyOwner {
        require(_baseSalary > 0, "Base salary must be greater than zero.");
        companyCount++;
        companies[companyCount] = Company({
            name: _companyName,
            maxEmployment: _maxEmployment,
            baseSalary: _baseSalary
        });
    }

    // Only owner can close the company.
    function bankruptcyCompany(uint256 _companyId) external onlyOwner {
        delete companies[_companyId];
    }

    // Only owner can change the base salary multiplier of the company
    function changeSalary(uint256 _companyId, uint256 _newSalary)
        external
        onlyOwner
    {
        require(_newSalary > 0, "Base salary must be greater than zero.");
        Company storage company = companies[_companyId];
        company.baseSalary = _newSalary;
    }

    // Only owner can change the maximum number of employees of the company
    function changeMaxEmployment(uint256 _companyId, uint256 _newMaxEmployment)
        external
        onlyOwner
    {
        Company storage company = companies[_companyId];
        company.maxEmployment = _newMaxEmployment;
    }

    // Owner of NFT can get NFT employee to work
    function getAJob(uint256 _companyId, uint256 _employeeId) external {
        Company storage company = companies[_companyId];
        address nftOwner = IBusinessCard(businessCard).ownerOf(_employeeId);
        address approvedAddress = IBusinessCard(businessCard).getApproved(_employeeId);
        require(nftOwner == msg.sender, "You're not owner of this NFT.");
        // baseSalary must be zero, so this is how the existence of this company can be checked.
        require(company.baseSalary > 0, "This company does not exist.");
        // Is the contract authorized for this nft?
        require(approvedAddress == address(this), "This contract not approved.");



    }

    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function mintToken(address _toAddress, uint256 _amount) external {
        IBusinessToken(businessToken).mintToken(_toAddress, _amount);
    }

    function totalSupp() external view returns (uint256) {
        return IBusinessToken(businessToken).totalSupply();
    }
}
