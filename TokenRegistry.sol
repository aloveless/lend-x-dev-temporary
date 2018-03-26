pragma solidity ^0.4.18;

import "./Ownable.sol";

contract TokenRegistry is Ownable {
    
    mapping (address => bool) public registered;
    address[] public addressList;
    
    function TokenRegistry() public {
        
    }
    
    function validateToken(address _token) public view returns(bool){
        return registered[msg.sender];
    }
    
}
