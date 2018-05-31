pragma solidity ^0.4.23;

import "./Ownable.sol";

/**
 * Authorized
 *
 * Base contract with multiple owners.
 * Provides onlyAuthorized modifier, which prevents function from running if it is called by anyone other than an authorized address.
 */

contract Authorized is Ownable {
    
    mapping (address => bool) public authorized;
    address[] public addressList;

    modifier onlyAuthorized() {
        require(authorized[msg.sender] == true);
        _;
    }

    function addAuthorization(address addAuth) public onlyOwner {
        if (addAuth != address(0)) {
            addressList.push(addAuth);
            authorized[addAuth] = true;
        }
    }
    
    function removeAuthorization(address removeAuth) public onlyOwner {
        if (removeAuth != address(0)) {
            authorized[removeAuth] = false;
            for (uint i = 0; i < addressList.length; i++) {
                if (addressList[i] == removeAuth) {
                    addressList[i] = addressList[addressList.length - 1];
                    addressList.length -= 1;
                    break;
                }
            }
        }
    }
}
