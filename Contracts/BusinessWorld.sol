// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

// @title BusinessCard NFT
// @author @github/omercsoylu
// This contract has been prepared for educational purposes. For commercial use, you must perform the necessary security checks.


// Interface: To access the BusinessToken ERC20 contract.
interface IBusinessToken {
    function mintToken(address _toAddress, uint256 _amount) external;
}

// Interface: To access the BusinessCard ERC721 contract.
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
    // Modifiers: onlyOwner
    modifier onlyOwner() {
        require(owner == msg.sender, "You're not owner.");
        _;
    }

    // Events: To listen transactions from the frontend
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
    

    // Structs: Company
    struct Company {
        string name;
        uint256 maxEmployment;
        uint256 baseSalary;
        // activeEmployee necessary, because we need to check, while updating the max number of employees
        uint256 activeEmployee;
        uint256 companyIndex;
    }
    // will be used to index companies by id
    uint256 private companyCount;
    // mapping from id to company
    mapping(uint256 => Company) public companies;
    // array of companies for access from frontend
    Company[] private companyArr;

    // Structs: Employee
    struct Employee {
        address owner;
        uint256 companyId;
        uint256 startAt;
        uint256 lastClaimedAt;
        uint256 employeeId;
        uint256 salaryMultiple;
        uint256 employeeIndex;
    }
    // mapping from nftId to employee
    mapping(uint256 => Employee) public employees;

    // This index will increase with each recruitment. This will verify ownership.
    mapping(address => uint256[]) private ownEmployeeIndexes;

    // will be used for the onlyOwner modifier
    address private owner;
    // These will be used for the interface. Assigned as immutable to be defined in the constructor.
    address immutable businessToken;
    address immutable businessCard;

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
            activeEmployee: 0,
            companyIndex: companyCount
        });

        // can access from frontend
        companyArr.push(companies[companyCount]);

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

        // can access from frontend
        delete companyArr[_companyId - 1];

        emit BankruptcyCompany(_companyId, company.name);
    }

    // Only owner can change the maximum number of employees of the company.
    function changeMaxEmployment(uint256 _companyId, uint256 _newMaxEmployment)
        external
        onlyOwner
    {
        Company storage company = companies[_companyId];
        // baseSalary must not be zero, so this is how the existence of this company can be checked.
        require(company.baseSalary > 0, "This company does not exist.");
        require(
            company.activeEmployee <= _newMaxEmployment,
            "There are more active employees than the given amount."
        );
        company.maxEmployment = _newMaxEmployment;

        // can access from frontend
        companyArr[_companyId - 1] = company;

        emit ChangeMaxEmployment(_companyId, company.name, _newMaxEmployment);
    }

    // Owner of NFT can get NFT employee to work.
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

        // to access all nfts of owner.
        uint256 _employeeIndex = ownEmployeeIndexes[msg.sender].length;
        ownEmployeeIndexes[msg.sender].push(_employeeId);

        IBusinessCard(businessCard).safeTransferFrom(
            msg.sender,
            address(this),
            _employeeId
        );

        // updating active employee counter.
        company.activeEmployee++;

        // can access from frontend
        companyArr[_companyId - 1] = company;

        // new employee updating
        employees[_employeeId] = Employee({
            owner: msg.sender,
            companyId: _companyId,
            startAt: timestamp,
            lastClaimedAt: timestamp,
            employeeId: _employeeId,
            salaryMultiple: _salaryMultiple,
            employeeIndex: _employeeIndex
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

        uint256 companyId = employee.companyId;

        // mint businessToken to nft owner
        mintToken(employee.owner, accumulateIncome);
        // used to access all nfts of owner.
        delete ownEmployeeIndexes[msg.sender][employee.employeeIndex];

        delete employees[_employeeId];
        company.activeEmployee--;

        // can access from frontend
        companyArr[companyId - 1] = company;

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

    // This is must be 'internal' function for calculating the accumulated income.
    // But this function is defined as 'public' to access from frontend.
    function getAccumulateIncome(uint256 _employeeId)
        public
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

    // Get All employees of given address.
    function getEmployees(address _ownerOfEmployees)
        external
        view
        returns (uint256[] memory)
    {
        return ownEmployeeIndexes[_ownerOfEmployees];
    }

    // Get Companies from frontend
    function getCompanies() external view returns (Company[] memory) {
        return companyArr;
    }

    // Get company count for frontend
    function getMaxCompanyIndex() external view returns (uint256) {
        return companyCount;
    }

    // Can change the owner of this contract.
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid address.");
        owner = _newOwner;

        emit TransferOwnership(msg.sender, _newOwner);
    }

    // This is an internal function to access and mint the ERC20 token contract via the interface.
    function mintToken(address _toAddress, uint256 _amount) internal {
        IBusinessToken(businessToken).mintToken(_toAddress, _amount);
    }
}
