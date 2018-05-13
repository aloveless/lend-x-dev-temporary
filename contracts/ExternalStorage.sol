pragma solidity ^0.4.23;

import "./Authorized.sol";

contract ExternalStorage is Authorized {
    
    constructor() public {
        
    }
    
    mapping(bytes32 => mapping(bytes32 => uint256)) public UIntStorage;
    mapping(bytes32 => mapping(bytes32 => address)) public AddressStorage;
    mapping(bytes32 => mapping(bytes32 => bool)) public BooleanStorage;
    
    //mapping(bytes32 => mapping(uint256 => address)) public LendeeMapAccounts;
    mapping(bytes32 => mapping(address => mapping(bytes32 => uint256))) public LenderUIntStorage;
    mapping(bytes32 => mapping(address => mapping(bytes32 => bool))) public LenderBooleanStorage;
    //mapping(address => uint256) public RequestCount;
    
    //function getRequestCount(address _requestor) external view returns(uint){
    //    return RequestCount[_requestor];
    //}

    function setUIntValue(bytes32 _requestID, bytes32 _var, uint256 _value) external {
        UIntStorage[_requestID][_var] = _value;
    }

    function getUIntValue(bytes32 _requestID, bytes32 _var) external view returns (uint256) {
        return UIntStorage[_requestID][_var];
    }
    
    function setAddressValue(bytes32 _requestID, bytes32 _var, address _value) external {
        AddressStorage[_requestID][_var] = _value;
    }
    
    function getAddressValue(bytes32 _requestID, bytes32 _var) external view returns (address){
        return AddressStorage[_requestID][_var];
    }

    function setBooleanValue(bytes32 _requestID, bytes32 _var, bool _value) external {
        BooleanStorage[_requestID][_var] = _value;
    }
    
    function getBooleanValue(bytes32 _requestID, bytes32 _var) external view returns (bool){
        return BooleanStorage[_requestID][_var];
    }
    
    function setLenderUIntValue(bytes32 _requestID, address _address, bytes32 _var, uint256 _value) external {
        LenderUIntStorage[_requestID][_address][_var] = _value;
    }
    
    function getLenderUIntValue(bytes32 _requestID, address _address, bytes32 _var) external view returns (uint256){
        return LenderUIntStorage[_requestID][_address][_var];
    }
    
    function setLenderBooleanValue(bytes32 _requestID, address _address, bytes32 _var, bool _value) external {
        LenderBooleanStorage[_requestID][_address][_var] = _value;
    }
    
    function getLenderBooleanValue(bytes32 _requestID, address _address, bytes32 _var) external view returns (bool){
        return LenderBooleanStorage[_requestID][_address][_var];
    }

}
