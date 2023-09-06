// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import OpenZeppelin's ReentrancyGuard
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DonationTracker is ReentrancyGuard {
    // State variables
    address public owner;
    mapping(address => uint256) public donations;
    mapping(string => address) public charities;
    mapping(address => uint256) public charityBalances;
    mapping(string => string[]) public charityPurposes;

    // Events
    event Donated(address indexed donor, address indexed charity, string purpose, uint256 amount);
    event CharityAdded(string name, address charityAddress);
    event PurposeAdded(string charityName, string purpose);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    modifier onlyCharity(string memory name) {
        require(msg.sender == charities[name], "Only the specified charity can perform this action");
        _;
    }

    // Constructor
    constructor() {
        owner = msg.sender;
    }

    // Functions to add charities and purposes
    function addCharity(string memory name, address charityAddress) public onlyOwner {
        require(charities[name] == address(0), "Charity already exists");
        charities[name] = charityAddress;
        emit CharityAdded(name, charityAddress);
    }

    function addPurpose(string memory charityName, string memory purpose) public onlyOwner {
        require(charities[charityName] != address(0), "Invalid charity name");
        charityPurposes[charityName].push(purpose);
        emit PurposeAdded(charityName, purpose);
    }

    // Donation function
    function donate(string memory charityName, string memory purpose) public payable nonReentrant {
        require(msg.value > 0, "Donation amount must be greater than zero");
        require(charities[charityName] != address(0), "Invalid charity name");
        
        bool validPurpose = false;
        for(uint i = 0; i < charityPurposes[charityName].length; i++) {
            if(keccak256(abi.encodePacked(charityPurposes[charityName][i])) == keccak256(abi.encodePacked(purpose))) {
                validPurpose = true;
                break;
            }
        }
        require(validPurpose, "Invalid purpose for the selected charity");

        donations[msg.sender] += msg.value;
        charityBalances[charities[charityName]] += msg.value;
        
        emit Donated(msg.sender, charities[charityName], purpose, msg.value);
    }

    // Function for charities to withdraw funds
    function withdrawFunds(string memory charityName, uint256 amount) public onlyCharity(charityName) nonReentrant {
        require(amount <= charityBalances[msg.sender], "Insufficient balance");
        charityBalances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    // Function to withdraw funds (only by the owner, for emergency cases)
    function emergencyWithdraw(uint256 amount) public onlyOwner {
        require(amount <= address(this).balance, "Insufficient balance");
        payable(owner).transfer(amount);
    }
}
