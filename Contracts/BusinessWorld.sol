// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBusinessToken {
    function mintToken(address _toAddress, uint256 _amount) external;
}

interface IBusinessCard {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);
}

contract BusinessWorld is IERC721Receiver {
    // Modifiers
    modifier onlyOwner() {
        require(owner == msg.sender, "You're not owner.");
        _;
    }

    // Events
    event EstablishCompany(
        uint256 indexed companyId,
        string companyName,
        uint256 maxEmployment,
        uint256 baseSalary
    );
    event BankruptcyCompany(uint256 indexed companyId, string companyName);
    event ChangeMaxEmployment(
        uint256 indexed companyId,
        string companyName,
        uint256 newMaxEmployment
    );
    event HireAJob(
        uint256 indexed employeeId,
        address indexed employeeOwner,
        uint256 companyId,
        uint256 startAt
    );
    event FireFromJob(
        uint256 indexed employeeId,
        address indexed employeeOwner,
        uint256 companyId,
        uint256 timestamp,
        uint256 accumulateIncome
    );
    event ClaimAccumulateIncome(
        uint256 indexed employeeId,
        address indexed employeeOwner,
        uint256 accumulateIncome
    );
    event TransferOwnership(address currentOwner, address newOwner);
    // End-of-Events

    // Structs Company
    struct Company {
        string name;
        uint256 maxEmployment;
        uint256 baseSalary;
        // activeEmployee necessary, because we need to check, while updating the max number of employees
        uint256 activeEmployee;
    }
    // count for company id
    uint256 private companyCount;
    // mapping from id to company
    mapping(uint256 => Company) public companies;

    // Structs Employee
    struct Employee {
        address owner;
        uint256 companyId;
        uint256 startAt;
        uint256 lastClaimedAt;
        uint256 employeeId;
        uint256 salaryMultiple;
    }
    // mapping from nftId to employee
    mapping(uint256 => Employee) public employees;

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
        // businessCard is ERC721. This contract access some function with own interface.
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
            baseSalary: _baseSalary,
            activeEmployee: 0
        });

        emit EstablishCompany(
            companyCount,
            _companyName,
            _maxEmployment,
            _baseSalary
        );
    }

    // Only owner can close the company.
    function bankruptcyCompany(uint256 _companyId) external onlyOwner {
        Company memory company = companies[_companyId];
        require(
            company.activeEmployee == 0,
            "You can't bankruptcy the company, there are still employees."
        );
        // baseSalary must not be zero, so this is how the existence of this company can be checked.
        require(company.baseSalary > 0, "This company does not exist.");
        delete companies[_companyId];

        emit BankruptcyCompany(_companyId, company.name);
    }

    // Only owner can change the maximum number of employees of the company
    function changeMaxEmployment(uint256 _companyId, uint256 _newMaxEmployment)
        external
        onlyOwner
    {
        Company storage company = companies[_companyId];
        require(
            company.activeEmployee <= _newMaxEmployment,
            "There are more active employees than the given amount."
        );
        company.maxEmployment = _newMaxEmployment;

        emit ChangeMaxEmployment(_companyId, company.name, _newMaxEmployment);
    }

    // Owner of NFT can get NFT employee to work
    function hireAJob(uint256 _companyId, uint256 _employeeId) external {
        Company storage company = companies[_companyId];
        address nftOwner = IBusinessCard(businessCard).ownerOf(_employeeId);
        address approvedAddress = IBusinessCard(businessCard).getApproved(
            _employeeId
        );
        require(nftOwner == msg.sender, "You're not owner of this NFT.");
        // baseSalary must not be zero, so this is how the existence of this company can be checked.
        require(company.baseSalary > 0, "This company does not exist.");
        // the maximum number of employees is exceeded?
        require(
            company.activeEmployee < company.maxEmployment,
            "the maximum number of employees is exceeded."
        );
        // Is the contract authorized for this nft?
        require(
            approvedAddress == address(this),
            "This contract not approved."
        );

        uint256 timestamp = block.timestamp;
        // salary multiplier calculate internal function.
        uint256 _salaryMultiple = getSalaryMultiplier(_employeeId);

        IBusinessCard(businessCard).safeTransferFrom(
            msg.sender,
            address(this),
            _employeeId
        );

        // updating active employee count
        company.activeEmployee++;

        // new employee updating
        employees[_employeeId] = Employee({
            owner: msg.sender,
            companyId: _companyId,
            startAt: timestamp,
            lastClaimedAt: timestamp,
            employeeId: _employeeId,
            salaryMultiple: _salaryMultiple
        });

        emit HireAJob(_employeeId, msg.sender, _companyId, timestamp);
    }

    // Owner of "NFT" can fire own employee from job. So we transfer the earned income and send the nft to the owner.
    function fireFromJob(uint256 _employeeId) external {
        Employee storage employee = employees[_employeeId];
        Company storage company = companies[employee.companyId];
        require(
            employee.companyId != 0,
            "This employee or company or job not found."
        );
        require(
            employee.owner == msg.sender,
            "You're not owner of this employee."
        );
        require(
            block.timestamp >= employee.startAt,
            "You can't withdraw the employee right now."
        );

        IBusinessCard(businessCard).safeTransferFrom(
            address(this),
            employee.owner,
            _employeeId
        );

        uint256 accumulateIncome = getAccumulateIncome(_employeeId);

        // mint businessToken to nft owner
        mintToken(employee.owner, accumulateIncome);

        delete employees[_employeeId];
        company.activeEmployee--;

        emit FireFromJob(
            _employeeId,
            msg.sender,
            employee.companyId,
            block.timestamp,
            accumulateIncome
        );
    }

    // The owner of "nft" can withdraw own accumulated income.
    function claimAccumulateIncome(uint256 _employeeId) external {
        Employee storage employee = employees[_employeeId];
        require(
            employee.companyId != 0,
            "This employee or company or job not found."
        );
        require(
            employee.owner == msg.sender,
            "You're not owner of this employee."
        );
        require(
            block.timestamp >= employee.lastClaimedAt,
            "You can't claim right now."
        );

        uint256 accumulateIncome = getAccumulateIncome(_employeeId);
        employee.lastClaimedAt = block.timestamp;
        mintToken(employee.owner, accumulateIncome);

        emit ClaimAccumulateIncome(_employeeId, msg.sender, accumulateIncome);
    }

    // This is internal function for calculating the accumulated income
    function getAccumulateIncome(uint256 _employeeId)
        internal
        view
        returns (uint256)
    {
        Employee memory employee = employees[_employeeId];
        Company memory company = companies[employee.companyId];

        uint256 timeDifference = block.timestamp - employee.lastClaimedAt;
        uint256 perTenSeconds = timeDifference / 10;

        uint256 income = company.baseSalary *
            employee.salaryMultiple *
            perTenSeconds;

        return income;
    }

    // This function is hypothetically for income multipliers.
    function getSalaryMultiplier(uint256 _employeeId)
        internal
        pure
        returns (uint256)
    {
        uint256 resValue;
        if (_employeeId % 10 == 1) {
            resValue = 25 * (10**18);
        } else if (_employeeId % 10 > 1 && _employeeId % 10 <= 4) {
            resValue = 20 * (10**18);
        } else if (_employeeId % 10 > 4 && _employeeId % 10 <= 7) {
            resValue = 15 * (10**18);
        } else if (_employeeId % 10 > 7 && _employeeId % 10 <= 9) {
            resValue = 10 * (10**18);
        } else {
            resValue = 5 * (10**18);
        }

        return resValue;
    }

    // contract receiver and transfer interface
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    // Get company count for frontend
    function getMaxCompanyIndex() external view returns (uint256) {
        return companyCount;
    }

    // Can change the owner of this contract.
    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;

        emit TransferOwnership(msg.sender, _newOwner);
    }

    // This is an internal function to access and mint the ERC20 token contract via the interface.
    function mintToken(address _toAddress, uint256 _amount) internal {
        IBusinessToken(businessToken).mintToken(_toAddress, _amount);
    }
}
