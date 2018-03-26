pragma solidity ^0.4.18;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./Authorized.sol";

contract ExternalStorage is Ownable, Authorized {
    using SafeMath for uint256;
    
    mapping(bytes32 => mapping(bytes32 => uint256)) public UIntStorage;
    mapping(bytes32 => mapping(bytes32 => address)) public AddressStorage;
    mapping(bytes32 => mapping(bytes32 => bool)) public BooleanStorage;
    mapping(bytes32 => mapping(uint256 => address)) public LendeeMapAccounts;
    mapping(bytes32 => mapping(address => mapping(bytes32 => uint256))) public LendeeUIntStorage;
    mapping(bytes32 => mapping(address => mapping(bytes32 => bool))) public LendeeBooleanStorage;
    mapping(address => uint256) public RequestCount;
    
    function getRequestCount(address _requestor) external view returns(uint){
        return RequestCount[_requestor];
    }
    
    function getAddressValue(bytes32 _requestID, bytes32 _variable) external view returns (address){
        return AddressStorage[_requestID][_variable];
    }
    
    function getBooleanValue(bytes32 _requestID, bytes32 _variable) external view returns (bool){
        return BooleanStorage[_requestID][_variable];
    }
    
    function setAddressValue(bytes32 _requestID, bytes32 _variable, address _value) external onlyAuthorized {
        AddressStorage[_requestID][_variable] = _value;
    }
    
    function setUIntValue(bytes32 _requestID, bytes32 _variable, uint256 _value) external onlyAuthorized {
        UIntStorage[_requestID][_variable] = _value;
    }
    
    function setBooleanValue(bytes32 _requestID, bytes32 _variable, bool _value) external onlyAuthorized {
        BooleanStorage[_requestID][_variable] = _value;
    }

}
