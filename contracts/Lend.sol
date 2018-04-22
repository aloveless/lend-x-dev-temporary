pragma solidity ^0.4.18;

import "./ExternalStorage.sol";
import "./TokenRegistry.sol";
import "./PaymentHandler.sol";
import "./ERC20Interface.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ECRecovery.sol";

contract Lend is Ownable {
    using SafeMath for uint256;
    
    ExternalStorage public externalStorage;
    TokenRegistry public tokenRegistry;
    PaymentHandler public paymentHandler;
    address public tokenFeeContract;
    // Major Releases/Stable Version - prior version deprecated
    // Updates/New Functionality - prior version deprecated
    // Bug/Security Fixes - prior version locked
    string constant public VERSION = "0.1.0";
    address public nextVersion = address(0); //linked list
    address public previousVersion; // linked list
    
    bool public locked = false;
    bool public deprecated  = false;
    uint16 constant public EXTERNAL_QUERY_GAS_LIMIT = 4999;
    
    struct Debt {

        bytes32 debtHash;
    }
    
    function Lend(address _previousVersion, address _tokenFeeContract, address _storage, address _tokenRegistry, address _paymentHandler) public {
        externalStorage = ExternalStorage(_storage);
        tokenRegistry = TokenRegistry(_tokenRegistry);
        tokenFeeContract = _tokenFeeContract;
        paymentHandler = PaymentHandler(_paymentHandler);
        previousVersion = _previousVersion;
    }
    
    function submitDebtRequest(address[5] _loanAddresses, uint256[9] _loanValues, bool[3] _loanOptions) public isDeprecated isLocked returns(bytes32){
        //require(validateLoanRequestArguments());
        //require(tokenRegistry.validateToken(_tokenAddress));
        
        Debt memory debt = Debt({
            maker: orderAddresses[0],
            debtHash: getDebtHash(orderAddresses, orderValues)
        });
        
        return = keccak256(
            address(this),  //Lend Contract Address
            _loanAddresses[1],  //Lendee
            _loanAddresses[2],  //Lender
            _loanAddresses[3],  //Principal Token
            _loanAddresses[4],  //Payment Token
            _loanValues[0],     //Principal Amount
            _loanValues[1],     //Loan Start
            _loanValues[2],     //Expires
            _loanValues[3],     //Salt
        );
        
        //Loan Addresses
        externalStorage.setAddressValue(requestID, keccak256('Principal'), msg.sender);
        externalStorage.setAddressValue(requestID, keccak256('Guarantor'), _guarantor);
        //Loan Values
        externalStorage.setUIntValue(requestID, keccak256("Principal"), _loanValues[0]);
        externalStorage.setUIntValue(requestID, keccak256("LendingPeriodEnd"), _loanValues[1]);
        externalStorage.setUIntValue(requestID, keccak256("ClaimBy"), _loanValues[2]);
        externalStorage.setUIntValue(requestID, keccak256("RepaymentDue"), _loanValues[3]);
        externalStorage.setUIntValue(requestID, keccak256("InterestFreePeriod"), _loanValues[4]);
        externalStorage.setUIntValue(requestID, keccak256("InterestRate"), _loanValues[5]);
        externalStorage.setUIntValue(requestID, keccak256("PaymentInterval"), _loanValues[6]);
        externalStorage.setUIntValue(requestID, keccak256("FixedRepaymentAmount"), _loanValues[7]);
        externalStorage.setUIntValue(requestID, keccak256("LockUpPeriod"), _loanValues[8]);
        //Loan Options
        externalStorage.setBooleanValue(requestID, keccak256("ForgiveDebt"), _loanOptions[0]);
        externalStorage.setBooleanValue(requestID, keccak256("PartialFunding"), _loanOptions[1]);
        externalStorage.setBooleanValue(requestID, keccak256("Locked"), _loanOptions[2]);
        externalStorage.setBooleanValue(requestID, keccak256("Exists"), true);
        
        //Lender Values
        externalStorage.setLenderUIntStorage(requestID, _loanAddresses[2], keccak256("LenderPrincipal"), _loanValues[8]);
        
        return requestID;
    }
    
    function submitCollateralizedDebtRequest() public returns(bool){
        
        return true;
    }
    
    function offerCreditLine(bytes32 _messageHash) public returns(bytes32){
        
        return _messageHash;
    }
    
    function approveCreditLine(bytes32 _requestID) public returns(bytes32){
        
        return _requestID;
    }
    
    function validateLoanRequestArguments() internal pure returns(bool){
        
        return true;
    }
    
    // function getLendees() public returns(bool){
        
    // }
    
    // function getDebtRequestCount(address _requestor) public view returns(uint256){
    //     return externalStorage.getRequestCount(_requestor);
    // }
    
    function getInterestAccrued(address _requestor) public view returns(uint256){
        return externalStorage.getRequestCount(_requestor);
    }
    
    // function getRequests(address _storage, address _requestor) external view returns(bytes32[] memory loans){
    //     uint256 requests = externalStorage.getRequestCount(_requestor);
    //     for(uint256 i = 0; i < requests; i++){
    //         loans[i] = keccak256(_requestor, i.add(1));
    //     }
    //     return loans;
    // }
    
    //only swaps out Lender address
    function transferDebtOwnership(bytes32 _requestID, uint256 _newOwner) public returns(bool){
        require(!keyExists(_requestID));
        
    }
    
    function initiateSecondaryDebtSale(){
        
    }
    
    function keyExists(bytes32 _requestID) public view returns(bool){
        return externalStorage.getBooleanValue(_requestID, keccak256('Exists'));
    }
  
    function getAllowance(address _token, address _owner, uint256 _gasLimit) public view returns (uint256){
        return ERC20Interface(_token).allowance.gas(_gasLimit)(_owner, paymentHandler);
    }
    
    function getBalance(address _token, address _owner, uint256 _gasLimit) public view returns(uint256){
        return ERC20Interface(_token).balanceOf.gas(_gasLimit)(_owner);
    }
    
    function getDebtHash() public pure returns(bytes32){
        
    }
    
    function validateSignature(address _signer, bytes32 _messageHash, bytes _sig) public pure returns(bool){
        return _signer == ECRecovery.recover(_messageHash, _sig);
    }
    
    /**
    * @dev Prevent New Request Propagation, Allows Existing To Complete
    */
    function deprecateContract() public onlyOwner returns(bool){
        return deprecated = true;
    }
    
    /**
    * @dev Lock All State Changes
    */
    function lockContract() public onlyOwner returns(bool){
        
    }
    
    function unlockContract() public onlyOwner returns(bool){
        
    }
    
    modifier isDeprecated(){
        require(deprecated == false);
        _;
    }
    
    modifier isLocked(){
        require(locked == false);
        _;
    }
    
}
