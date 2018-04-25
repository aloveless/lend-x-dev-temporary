pragma solidity ^0.4.23;

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
    address public prevVersion; // linked list
    
    bool public locked = false;
    bool public deprecated  = false;
    uint16 constant public EXTERNAL_QUERY_GAS_LIMIT = 4999;
    
    event DeprecatedEvent(
        address indexed version,
        address indexed nextVersion,
        address prevVersion
    );
    
    event LockedEvent(
        address indexed version,
        address indexed nextVersion,
        address prevVersion,
        uint8 indexed reasonCode
    );
    
    event DebtAgreementEvent(
        address indexed lendee,
        address indexed agent,
        address indexed underwriter,
        uint _value
    );
    
    struct DebtAgreement {
        address lendee;
        address lender;
        address principalToken;
        address paymentToken;
        address underwriter;
        address collateralToken;
        address guarantor;
        address agent;
        uint256 principal;
        uint256 loanStart;
        uint256 originationFee;
        uint256 loanTerm;
        uint256 periodicInterestRate;
        uint256 paymentAmount;
        uint256 paymentInterval;
        uint256 lateFee;
        uint256 collateralAmount;
        uint256 loanDefaultPeriod;
        uint256 guarantorFee;
        uint256 lendeeAgentFee;
        uint256 lenderAgentFee;
        uint256 expires;
        bytes32 debtHash;
    }
    
    constructor(address _prevVersion, address _tokenFeeContract, address _storage, address _tokenRegistry, address _paymentHandler) public {
        externalStorage = ExternalStorage(_storage);
        tokenRegistry = TokenRegistry(_tokenRegistry);
        tokenFeeContract = _tokenFeeContract;
        paymentHandler = PaymentHandler(_paymentHandler);
        prevVersion = _prevVersion;
    }
    
    function submitDebtRequest(address[9] _loanAddresses, uint256[15] _loanValues, uint256 _amountToLend, bool[3] _loanOptions, bytes _lendeeSig, bytes _underwriterSig, bytes _guarantorSig) public isDeprecated isLocked returns(bytes32){
        
        //may only need this inside initialize function and for repayment, otherwise can probably get away with just the hash
        DebtAgreement memory debt = DebtAgreement({
            lendee: _loanAddresses[1],
            lender: _loanAddresses[2],
            principalToken: _loanAddresses[3],
            paymentToken: _loanAddresses[4],
            underwriter: _loanAddresses[5],
            collateralToken: _loanAddresses[6],
            guarantor: _loanAddresses[7],
            agent: _loanAddresses[8],
            principal: _loanValues[0],
            loanStart: _loanValues[1],
            originationFee: _loanValues[2],
            loanTerm: _loanValues[3],
            periodicInterestRate: _loanValues[4],
            paymentAmount: _loanValues[5],
            paymentInterval: _loanValues[6],
            lateFee: _loanValues[7],
            collateralAmount: _loanValues[8],
            loanDefaultPeriod: _loanValues[9],
            guarantorFee: _loanValues[10],
            lendeeAgentFee: _loanValues[11],
            lenderAgentFee: _loanValues[12],
            expires: _loanValues[13],
            debtHash: getDebtHash(_loanAddresses, _loanValues)
        });
        
        //initializeLoan();
        //require(validateArguments());
        //require(tokenRegistry.validateToken(_tokenAddress));
        
        //Loan Values
        externalStorage.setUIntValue(debt.debtHash, keccak256('Outstanding'), _amountToLend);

        //Lender Values
        externalStorage.setLenderUIntStorage(debt.debtHash, msg.sender, keccak256("LenderPrincipal"), _amountToLend);
        
        //Loan Config
        externalStorage.setBooleanValue(debt.debtHash, keccak256("Initialized"), true);
        
        return debt.debtHash;
    }
    
    function testHash1(address[2] _loanAddresses, uint256[2] _loanValues) public pure returns(bytes32){
        return keccak256(_loanAddresses, _loanValues);
    }
    
    function testHash2(address[2] _loanAddresses, uint256[2] _loanValues) public pure returns(bytes32){
        return keccak256(_loanAddresses[0], _loanAddresses[1], _loanValues);
    }
    
    function testHash3(address[2] _loanAddresses, uint256[2] _loanValues) public pure returns(bytes32){
        return keccak256(_loanAddresses[0],_loanAddresses[1], _loanValues[0], _loanValues[1]);
    }
    
    function testHash4(address[1] _loanAddresses, bytes32 _loanBytes, uint256[2] _loanValues) public pure returns(bytes32){
        return keccak256(_loanAddresses[0], _loanBytes, _loanValues);
    }
    
    function getDebtHash(address[9] _loanAddresses, uint256[15] _loanValues) public pure returns(bytes32){
        return keccak256(_loanAddresses, _loanValues);
        
        // return keccak256(
        //     _loanAddresses[0],  //Lend Contract Address
        //     _loanAddresses[1],  //Lendee
        //     _loanAddresses[2],  //Lender
        //     _loanAddresses[3],  //Principal Token
        //     _loanAddresses[4],  //Payment Token
        //     _loanAddresses[5],  //Underwriter
        //     _loanAddresses[6],  //Collateral Token
        //     _loanAddresses[7],  //Guarantor
        //     _loanAddresses[8],  //Agent
        //     _loanValues[0],     //Principal
        //     _loanValues[1],     //Loan Start
        //     _loanValues[2],     //Origination Fee
        //     _loanValues[3],     //Loan Term
        //     _loanValues[4],     //Periodic Interest Rate
        //     _loanValues[5],     //Payment Amount
        //     _loanValues[6],     //Payment Interval
        //     _loanValues[7],     //Late Fee
        //     _loanValues[8],     //Collateral Amount
        //     _loanValues[9],     //Loan Default Period
        //     _loanValues[10],    //Guarantor Fee
        //     _loanValues[11],    //Lendee Agent Fee
        //     _loanValues[12],    //Lender Agent Fee
        //     _loanValues[13],    //Expires
        //     _loanValues[14]     //Salt
        // ); 
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
    
    function forgiveDebt(uint256 requestID){
        //externalStorage.LenderBooleanStorage(requestID, msg.sender, keccak256("ForgiveDebt"), true);
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
        //return externalStorage.getRequestCount(_requestor);
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
