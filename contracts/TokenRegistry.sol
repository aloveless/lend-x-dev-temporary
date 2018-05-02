pragma solidity ^0.4.23;

import "./Ownable.sol";

contract TokenRegistry is Ownable {
    
    mapping (address => bool) public registered;
    address[] public addressList;
    
    constructor() public {
        
    }
    
    function validateToken(address _token) public view returns(bool){
        return registered[msg.sender];
    }
    
}
