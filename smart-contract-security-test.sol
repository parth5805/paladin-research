// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * Example contract showing potential backdoors in access-controlled storage
 */
contract RestrictedStorage {
    uint256 private secretValue;
    address public owner;
    address public authorizedAddress1;
    address public authorizedAddress2;
    
    mapping(address => bool) public authorized;
    
    // Events to track access
    event ValueChanged(address indexed by, uint256 oldValue, uint256 newValue);
    event UnauthorizedAccess(address indexed attemptedBy);
    
    constructor(address _addr1, address _addr2) {
        owner = msg.sender;
        authorizedAddress1 = _addr1;
        authorizedAddress2 = _addr2;
        authorized[_addr1] = true;
        authorized[_addr2] = true;
        secretValue = 100; // Initial value
    }
    
    modifier onlyAuthorized() {
        require(authorized[msg.sender], "Unauthorized access");
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }
    
    // Basic read function (seems secure)
    function readValue() external view onlyAuthorized returns (uint256) {
        return secretValue;
    }
    
    // Basic write function (seems secure)
    function writeValue(uint256 _newValue) external onlyAuthorized {
        uint256 oldValue = secretValue;
        secretValue = _newValue;
        emit ValueChanged(msg.sender, oldValue, _newValue);
    }
    
    // BACKDOOR 1: Owner override (admin privilege escalation)
    function emergencyWrite(uint256 _newValue) external onlyOwner {
        secretValue = _newValue;
        emit ValueChanged(msg.sender, secretValue, _newValue);
    }
    
    // BACKDOOR 2: Authorization management by owner
    function addAuthorized(address _addr) external onlyOwner {
        authorized[_addr] = true;
    }
    
    function removeAuthorized(address _addr) external onlyOwner {
        authorized[_addr] = false;
    }
    
    // BACKDOOR 3: Contract upgrade mechanism
    address public implementation;
    
    function upgradeImplementation(address _newImpl) external onlyOwner {
        implementation = _newImpl;
    }
    
    // Fallback that could delegate to new implementation
    fallback() external payable {
        if (implementation != address(0)) {
            (bool success, ) = implementation.delegatecall(msg.data);
            require(success, "Delegatecall failed");
        }
    }
    
    // BACKDOOR 4: Self-destruct mechanism
    function destroy() external onlyOwner {
        selfdestruct(payable(owner));
    }
}

/**
 * Malicious contract that could be used as upgrade target
 */
contract MaliciousImplementation {
    uint256 private secretValue; // Same storage slot as original
    
    function maliciousRead() external view returns (uint256) {
        return secretValue;
    }
    
    function maliciousWrite(uint256 _value) external {
        secretValue = _value;
    }
}

/**
 * Example of a more secure approach (but still not perfect)
 */
contract SecureRestrictedStorage {
    uint256 private secretValue;
    address public immutable authorizedAddress1;
    address public immutable authorizedAddress2;
    
    // No owner, no upgrade mechanism
    constructor(address _addr1, address _addr2) {
        authorizedAddress1 = _addr1;
        authorizedAddress2 = _addr2;
        secretValue = 100;
    }
    
    modifier onlyAuthorized() {
        require(
            msg.sender == authorizedAddress1 || msg.sender == authorizedAddress2,
            "Unauthorized"
        );
        _;
    }
    
    function readValue() external view onlyAuthorized returns (uint256) {
        return secretValue;
    }
    
    function writeValue(uint256 _newValue) external onlyAuthorized {
        secretValue = _newValue;
    }
    
    // No admin functions, no upgrade mechanism, no self-destruct
}
