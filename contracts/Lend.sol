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
    ERC20Interface public protocolToken;
    // Major Releases/Stable Version - prior version deprecated
    // Updates/New Functionality - prior version deprecated
    // Bug/Security Fixes - prior version locked
    string constant public VERSION = "0.1.0";
    
    bool public locked = false;
    bool public deprecated  = false;
    uint16 constant public GAS_LIMIT = 4999;
    
    enum Errors {
        ORDER_EXPIRED,                    // Order has already expired
        LOAN_FILLED,                      // Order has already been fully filled
        ROUNDING_ERROR_TOO_LARGE,         // Rounding error too large
        INSUFFICIENT_BALANCE_OR_ALLOWANCE // Insufficient balance or allowance for token transfer
    }
    
    event LogError(uint8 indexed errorCode, bytes32 indexed debtHash);
    
    event DeprecatedEvent(
        address indexed version
    );
    
    event LockedEvent(
        address indexed version,
        address indexed nextVersion,
        address prevVersion,
        uint8 indexed reasonCode
    );
    
    event DebtAgreementEvent(
        address indexed lendee,
        address indexed lender,
        address agent,
        address underwriter,
        uint256 lenderAmount,
        uint256 remaining
    );
    
    struct DebtAgreement {
        address lendee;
        address lender;
        address principalToken;
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
    
    constructor(address _protocolToken, address _storage, address _tokenRegistry, address _paymentHandler) public {
        externalStorage = ExternalStorage(_storage);
        tokenRegistry = TokenRegistry(_tokenRegistry);
        protocolToken = ERC20Interface(_protocolToken);
        paymentHandler = PaymentHandler(_paymentHandler);
    }
    
    function submitDebtRequest(address[8] _loanAddresses, uint256[15] _loanValues, uint256 _amountToLend, bytes _lendeeSig, bytes _underwriterSig, bytes _guarantorSig, bool allowPartialLoan) public isDeprecated isLocked returns(uint256){
        
        //may only need this inside initialize function and for repayment, otherwise can probably get away with just the hash
        DebtAgreement memory debt = DebtAgreement({
            lendee: _loanAddresses[1],
            lender: _loanAddresses[2],
            principalToken: _loanAddresses[3],
            underwriter: _loanAddresses[4],
            collateralToken: _loanAddresses[5],
            guarantor: _loanAddresses[6],
            agent: _loanAddresses[7],
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
        
        require(debt.lender == address(0) || debt.lender == msg.sender);
        require(debt.principal > 0 && debt.paymentAmount > 0 && debt.paymentInterval > 0 && _amountToLend > 0);
        require(validSignature(debt.lendee, debt.debtHash, _lendeeSig));
        
        if(debt.collateralToken != address(0) || debt.collateralAmount > 0){
            require(debt.guarantor != address(0));
        }
        
        if (block.timestamp > debt.expires) {
            emit LogError(uint8(Errors.ORDER_EXPIRED), debt.debtHash);
            return 0;
        }
        
        uint256 currentPrincipal = getPrincipal(debt.debtHash);
        uint256 principalAmountRemaining = debt.principal.sub(currentPrincipal);
        uint256 lenderLoanAmount = (_amountToLend < principalAmountRemaining ? _amountToLend : principalAmountRemaining);
        
        if (lenderLoanAmount == 0) {
            emit LogError(uint8(Errors.LOAN_FILLED), debt.debtHash);
            return 0;
        }
        
        if (validRounding(lenderLoanAmount, debt.principal, debt.lenderAgentFee)) {
            emit LogError(uint8(Errors.ROUNDING_ERROR_TOO_LARGE), debt.debtHash);
            return 0;
        }
        
        if (!validBalancesAndAllowances(debt, lenderLoanAmount)) {
            emit LogError(uint8(Errors.INSUFFICIENT_BALANCE_OR_ALLOWANCE), debt.debtHash);
            return 0;
        }
        
        
        //uint256 originationFee = (debt.underwriter != address(0) ? getPartialAmount(lenderLoanAmount, debt.principal, debt.originationFee) : uint256(0));
        //uint256 guarantorFee = (debt.guarantor != address(0) ? getPartialAmount(lenderLoanAmount, debt.principal, debt.guarantorFee) : uint256(0));
        //uint256 lendeeAgentFee;
        //uint256 lenderAgentFee;
        
        //New Principal
        externalStorage.setUIntValue(debt.debtHash, keccak256('Principal'), currentPrincipal.add(lenderLoanAmount));
        //externalStorage.setUIntValue(debt.debtHash, keccak256('Outstanding'), _amountToLend);

        externalStorage.setLenderUIntValue(debt.debtHash, msg.sender, keccak256("LenderPrincipal"), lenderLoanAmount);

        externalStorage.setBooleanValue(debt.debtHash, keccak256("Initialized"), true);
        
        //emit DebtAgreementEvent( debt.debtHash);
        
        return lenderLoanAmount;
    }
    
    function getDebtHash(address[8] _loanAddresses, uint256[15] _loanValues) public pure returns(bytes32){
        return keccak256(_loanAddresses, _loanValues);
        
        //     _loanAddresses[0],  //Protocol Contract Address
        //     _loanAddresses[1],  //Lendee
        //     _loanAddresses[2],  //Lender
        //     _loanAddresses[3],  //Principal Token
        //     _loanAddresses[4],  //Underwriter
        //     _loanAddresses[5],  //Collateral Token
        //     _loanAddresses[6],  //Guarantor
        //     _loanAddresses[7],  //Agent
        //     _loanValues[0],     //Principal Amount
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
    }
    
    function submitCollateralizedDebtRequest() public returns(bool){
        
        return true;
    }
    
    function approveCreditLineOffer(bytes32 _requestID) public returns(bytes32){
        
        return _requestID;
    }
    
    function validBalancesAndAllowances(DebtAgreement debt, uint256 lenderLoanAmount) internal view returns(bool){
        uint256 lendeeFees;
        uint256 lenderFees;
        
        lendeeFees = lendeeFees.add((debt.underwriter != address(0) ? getPartialAmount(lenderLoanAmount, debt.principal, debt.originationFee) : uint256(0)));
        lendeeFees = lendeeFees.add((debt.guarantor != address(0) ? getPartialAmount(lenderLoanAmount, debt.principal, debt.guarantorFee) : uint256(0)));
        lendeeFees = lendeeFees.add((debt.agent != address(0) ? getPartialAmount(lenderLoanAmount, debt.principal, debt.lendeeAgentFee) : uint256(0)));
        lenderFees = lenderFees.add((debt.agent != address(0) ? getPartialAmount(lenderLoanAmount, debt.principal, debt.lenderAgentFee) : uint256(0)));        
        
        //if(debt.guarantor != address(0) && debt.collateralToken != address(0) && )
        
        if(debt.principalToken == address(protocolToken)){
            return getBalance(debt.principalToken, msg.sender) < lenderFees.add(lenderLoanAmount) 
            && getBalance(debt.principalToken, debt.lendee) < lendeeFees 
            && getAllowance(debt.principalToken, msg.sender) < lenderFees.add(lenderLoanAmount) 
            && getAllowance(debt.principalToken, debt.lendee) < lendeeFees
            && (debt.collateralToken == address(0) || true);
        }
        if(lendeeFees != uint256(0)){

        }

    }
    
    function getAllowance(address _token, address _owner) public view returns (uint256){
        return ERC20Interface(_token).allowance.gas(GAS_LIMIT)(_owner, address(paymentHandler));
    }
    
    function getBalance(address _token, address _owner) public view returns(uint256){
        return ERC20Interface(_token).balanceOf.gas(GAS_LIMIT)(_owner);
    }
    
    function validSignature(address _signer, bytes32 _debtHash, bytes _sig) public pure returns(bool){
        return _signer == ECRecovery.recover(_debtHash, _sig);
    }
    
    function getPartialAmount(uint256 numerator, uint256 denominator, uint256 target) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(numerator, target), denominator);
    }
    
    
    function forgiveDebt(uint256 requestID){
        //externalStorage.LenderBooleanStorage(requestID, msg.sender, keccak256("ForgiveDebt"), true);
    }
    
    function getPrincipal(bytes32 debtHash) public returns(uint256){
        return externalStorage.getUIntValue(debtHash, keccak256('Principal'));
    }
    
    function getInterestAccrued(address _requestor) public view returns(uint256){
        //return externalStorage.getRequestCount(_requestor);
    }
    
    //only swaps out Lender address
    function transferDebtOwnership(bytes32 _requestID, uint256 _newOwner) public returns(bool){
        require(!keyExists(_requestID));
        
    }
    
    function initiateSecondaryDebtSale(){
        
    }
    
    function keyExists(bytes32 _requestID) public view returns(bool){
        return externalStorage.getBooleanValue(_requestID, keccak256('Exists'));
    }
    
    function validRounding(uint numerator, uint denominator, uint target) public pure returns(bool){
        uint remainder = mulmod(target, numerator, denominator);
        if (remainder == 0) { return false; }

        uint errPercentageTimes1000000 = SafeMath.div(SafeMath.mul(remainder, 1000000), SafeMath.mul(numerator, target));
        return errPercentageTimes1000000 > 1000;
    }
    
    /**
    * @dev Prevent New Request Propagation, Allows Existing To Complete
    */
    function deprecateContract() public onlyOwner returns(bool){
        require(!deprecated);
        emit DeprecatedEvent(address(this));
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
