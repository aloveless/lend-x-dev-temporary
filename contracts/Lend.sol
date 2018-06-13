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
    // Major Releases/Stable Version - prior version is deprecated
    // Updates/New Functionality - prior version deprecated
    // Bug/Security Fixes - prior version locked
    string constant public VERSION = "0.1.0";
    
    bool public locked = false;
    bool public deprecated  = false;
    uint16 constant public GAS_LIMIT = 4999;
    
    //https://github.com/ethereum/solidity/issues/1686
    //Return Transaction Error from Require/Revert not supported yet
    enum Errors {
        REQUEST_EXPIRED,                      // Agreement has already expired
        LOAN_FILLED,                            // Debt has been fully transfered
        ROUNDING_ERROR_TOO_LARGE,               // Rounding error too large
        INSUFFICIENT_BALANCE_OR_ALLOWANCE,      // Insufficient balance or allowance for token transfer
        lENDER_PARTIAL_LOAN_NOT_ALLOWABLE       // Lender does not allow partial fill and fillable amount is less than lender loan amount
    }
    
    //Remove After Testing
    event LogTestValue(uint256 output);
    
    event LogError(uint8 indexed errorCode, bytes32 indexed debtHash);
    event DeprecatedEvent(address supercededBy);
    event LockedEvent(bool status);
    event DebtTransferEvent(bytes32 debtHash, address _from, address _to);
    event DebtAgreementEvent(
        address indexed lendee,
        address lender,
        address principalToken,
        address underwriter,
        address collateralToken,
        address indexed guarantor,
        address indexed agent,
        uint256 lenderLoanAmount, //let lendee know amount loaned
        uint256 originationFee,
        uint256 loanTerm,
        uint256 periodicInterestRate,
        uint256 paymentAmount,
        uint256 paymentInterval,
        uint256 lateFee,
        uint256 collateralAmount,
        uint256 defaultPeriod,
        uint256 lendeeAgentFee,
        uint256 lenderAgentFee,
        bytes32 debtHash //should this be indexed
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
        uint256 loanStart; // may not need this, set to block # when loan is funded or expires & funded
        uint256 originationFee;
        uint256 loanTerm;
        uint256 periodicInterestRate;
        uint256 paymentAmount;
        uint256 paymentInterval;
        uint256 lateFee;
        uint256 collateralAmount;
        uint256 defaultPeriod;
        uint256 guarantorFee;
        uint256 lendeeAgentFee;
        uint256 lenderAgentFee;
        uint256 expires;
        bytes32 debtHash;
    }
    
    constructor(address _protocolToken, address _storage, address _paymentHandler, address _tokenRegistry) public {
        externalStorage = ExternalStorage(_storage);
        tokenRegistry = TokenRegistry(_tokenRegistry);
        protocolToken = ERC20Interface(_protocolToken);
        paymentHandler = PaymentHandler(_paymentHandler);
    }

    /** 
    * @dev Process offchain Debt Request
    * @param _lenderLoanOptions array of Lender conditions that must be met before tokens are transferred. [0] = allowPartialLoan
    * @return Total amount of consideration transfered from Lender to Lendee.
    */
    function processDebtRequest(address[8] _loanAddresses, uint256[15] _loanValues, uint256 _amountToLend, bytes _lendeeSig, bytes _underwriterSig, bytes _guarantorSig, bool[1] _lenderLoanOptions) public isDeprecated isLocked returns(uint256){
        
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
            defaultPeriod: _loanValues[9],
            guarantorFee: _loanValues[10],
            lendeeAgentFee: _loanValues[11],
            lenderAgentFee: _loanValues[12],
            expires: _loanValues[13],
            debtHash: getDebtHash(_loanAddresses, _loanValues)
        });
        
        //initializeLoan();
        //require(validateArguments());
        //require(tokenRegistry.validateToken(_tokenAddress));
        
        require(debt.lender == address(0) || debt.lender == msg.sender, "Invalid Lender");
        require(debt.underwriter == address(0) || debt.underwriter != debt.lendee, "Invalid Underwriter");
        require(debt.principal > 0 && debt.paymentAmount > 0 && debt.paymentInterval > 0 && _amountToLend > 0, "Invalid Amounts Provided");
        require(validSignature(debt.lendee, debt.debtHash, _lendeeSig), "Lendee Signature Validation Failed");
        
        if(debt.underwriter != address(0)){
            require(validSignature(debt.underwriter, debt.debtHash, _underwriterSig));
        }
        
        if(debt.guarantor != address(0)){
            require(validSignature(debt.guarantor, debt.debtHash, _guarantorSig));
        }
        
        if(debt.originationFee > 0){
            require(debt.underwriter != address(0) && debt.underwriter != debt.lendee);
        }
        
        if(debt.collateralAmount > 0){ 
            require(debt.guarantor != address(0) && debt.collateralToken != address(0));
        }
        
        if(debt.lendeeAgentFee > 0 || debt.lenderAgentFee > 0){
            require(debt.agent != address(0)); 
        }
        
        if(block.timestamp > debt.expires){
            emit LogError(uint8(Errors.REQUEST_EXPIRED), debt.debtHash);
            return 0;
        }
        
        //validations needed if lender object is passed
        // Needs some consideration based on lendee & lender options
        //// should loan amount be less than or equal to this amount, Lendee options parameter is needed to define this also
        // update struct and array to include lender object values
        // if(debt.lender == msg.sender && debt.lenderAmount > 0){ require(_amountToLend == debt.lenderAmount); }
        
        uint256 currentPrincipal = getPrincipal(debt.debtHash);
        uint256 principalAmountRemaining = debt.principal.sub(currentPrincipal);
        uint256 lenderLoanAmount = (_amountToLend < principalAmountRemaining ? _amountToLend : principalAmountRemaining);

        if(_lenderLoanOptions[0] == false && lenderLoanAmount < _amountToLend){
            emit LogError(uint8(Errors.lENDER_PARTIAL_LOAN_NOT_ALLOWABLE), debt.debtHash);
            return 0;
        }
        
        if(lenderLoanAmount == 0){
            emit LogError(uint8(Errors.LOAN_FILLED), debt.debtHash);
            return 0;
        }
        
        //Needs to be vetted
        if(debt.collateralAmount > 0 && isRoundingError(lenderLoanAmount, debt.principal, debt.collateralAmount)){
            emit LogError(uint8(Errors.ROUNDING_ERROR_TOO_LARGE), debt.debtHash);
            return 0;
        }
        
        if(!validBalancesAndAllowances(debt, lenderLoanAmount)){
            emit LogError(uint8(Errors.INSUFFICIENT_BALANCE_OR_ALLOWANCE), debt.debtHash);
            return 0;
        }
        
        //State Changes
        externalStorage.setUIntValue(debt.debtHash, keccak256('Principal'), currentPrincipal.add(lenderLoanAmount));
        externalStorage.setLenderUIntValue(debt.debtHash, msg.sender, keccak256("LenderPrincipal"), lenderLoanAmount.add(externalStorage.getLenderUIntValue(debt.debtHash, msg.sender, keccak256("LenderPrincipal"))));
        //externalStorage.setBooleanValue(debt.debtHash, keccak256("Initialized"), true);
        
        //Transfer Principal Tokens from Lender to Lendee
        require(paymentHandler.transferFrom(debt.principalToken, msg.sender, debt.lendee, lenderLoanAmount));
        
        if(debt.underwriter == debt.agent){
            //Transfer Origination Fee & Lendee Agent Fee from Lendee to Underwriter
            if(debt.originationFee > 0 || debt.lendeeAgentFee > 0){
                require(paymentHandler.transferFrom(protocolToken, debt.lendee, debt.underwriter, getPartialAmount(lenderLoanAmount, debt.principal, SafeMath.add(debt.originationFee, debt.lendeeAgentFee))));
            }
            //Transfer Lender Agent Fee from Lender to Agent
            if(debt.lenderAgentFee > 0){
                require(paymentHandler.transferFrom(protocolToken, msg.sender, debt.agent, getPartialAmount(lenderLoanAmount, debt.principal, debt.lenderAgentFee)));
            }
        } else {
            //Transfer Origination Fee from Lendee to Underwriter
            if(debt.originationFee > 0){
                require(paymentHandler.transferFrom(protocolToken, debt.lendee, debt.underwriter, getPartialAmount(lenderLoanAmount, debt.principal, debt.originationFee)));
            }
            //Transfer Lendee Agent Fee from Lendee to Agent
            if(debt.lendeeAgentFee > 0){
                require(paymentHandler.transferFrom(protocolToken, debt.lendee, debt.agent, getPartialAmount(lenderLoanAmount, debt.principal, debt.lendeeAgentFee)));
            }
            //Transfer Lender Agent Fee from Lender to Agent
            if(debt.lenderAgentFee > 0){
                require(paymentHandler.transferFrom(protocolToken, msg.sender, debt.agent, getPartialAmount(lenderLoanAmount, debt.principal, debt.lenderAgentFee)));
            }
        }
        
        if(debt.guarantor != address(0)){
            //Transfer Guarantor Fees from Lendee to Guarantor
            if(debt.guarantorFee > 0){
                require(paymentHandler.transferFrom(protocolToken, debt.lendee, debt.guarantor, getPartialAmount(lenderLoanAmount, debt.principal, debt.guarantorFee)));
            } 
            //Transfer Collateral from Guarantor to PaymentHandler Contract
            if(debt.collateralAmount > 0){
                require(paymentHandler.transferFrom(debt.collateralToken, debt.guarantor, paymentHandler, getPartialAmount(lenderLoanAmount, debt.principal, debt.collateralAmount)));
            }
        }
        
        //emit DebtAgreementEvent( debt.debtHash);

        return lenderLoanAmount;
    }
    
    //crowdfunded loan where it's first transferred to payment paymentHandler
    //then lendee withdraws committed amount if min comittment is achieved
    function processPublicDebtOffering(){
        
    }
    
    //crowdfunded loan where lendee/or underwriter doesn't sign offer,
    //whoever doesn't sign can submit committed amount
    //instead of leaving out sigs could also be another signed array parameter called _servicingOptions
    //separate function since parameters are different
    function processLendeeControlledDebtOffering(){
        
    }
    
    //If guarantor is not part of original signed request lender can separatly include
    //this could also be part of original function as separate guarantor array argument
    //breaking into separate function for now and will probably be part of v2
    function submitLenderGuaranteedDebtAgreement(){
        
    }
    
    function transferDebt(bytes32 _debtHash, address _newHolder) public returns(bool){
        require(!keyExists(_debtHash));
        
    }
    
    function massDebtTransfer(bytes32[] _debtHash, address[] _newHolder) public returns(bool){
        
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
        //     _loanValues[9],     //Default Period
        //     _loanValues[10],    //Guarantor Fee
        //     _loanValues[11],    //Lendee Agent Fee
        //     _loanValues[12],    //Lender Agent Fee
        //     _loanValues[13],    //Expires
        //     _loanValues[14]     //Salt
    }
    
    function validBalancesAndAllowances(DebtAgreement debt, uint256 lenderLoanAmount) internal view returns(bool){
        uint256 lendeeFees = lendeeFees.add((debt.underwriter != address(0) ? getPartialAmount(lenderLoanAmount, debt.principal, debt.originationFee) : uint256(0)));
        lendeeFees = lendeeFees.add((debt.guarantor != address(0) ? getPartialAmount(lenderLoanAmount, debt.principal, debt.guarantorFee) : uint256(0)));
        lendeeFees = lendeeFees.add((debt.agent != address(0) ? getPartialAmount(lenderLoanAmount, debt.principal, debt.lendeeAgentFee) : uint256(0)));
        uint256 lenderFees = lenderFees.add((debt.agent != address(0) ? getPartialAmount(lenderLoanAmount, debt.principal, debt.lenderAgentFee) : uint256(0)));
        uint256 guaranteedAmount = (debt.collateralAmount > 0 ? getPartialAmount(lenderLoanAmount, debt.principal, debt.collateralAmount) : uint256(0));
        
        if(debt.principalToken == address(protocolToken)){
            return getBalance(debt.principalToken, msg.sender) >= lenderFees.add(lenderLoanAmount) 
                && getBalance(debt.principalToken, debt.lendee) >= lendeeFees 
                && getAllowance(debt.principalToken, msg.sender) >= lenderFees.add(lenderLoanAmount) 
                && getAllowance(debt.principalToken, debt.lendee) >= lendeeFees
                && (guaranteedAmount == uint256(0) || getBalance(debt.collateralToken, debt.guarantor) >= guaranteedAmount)
                && (guaranteedAmount == uint256(0) || getAllowance(debt.collateralToken, debt.guarantor) >= guaranteedAmount);
        }
        
        return getBalance(debt.principalToken, msg.sender) >= lenderLoanAmount 
            && getBalance(protocolToken, msg.sender) >= lenderFees 
            && getBalance(protocolToken, debt.lendee) >= lendeeFees 
            && getAllowance(debt.principalToken, msg.sender) >= lenderLoanAmount 
            && getAllowance(protocolToken, msg.sender) >= lenderFees 
            && getAllowance(protocolToken, debt.lendee) >= lendeeFees
            && (guaranteedAmount == uint256(0) || getBalance(debt.collateralToken, debt.guarantor) >= guaranteedAmount)
            && (guaranteedAmount == uint256(0) || getAllowance(debt.collateralToken, debt.guarantor) >= guaranteedAmount);
    }

    function approveCreditLineOffer(bytes32 _requestID) public returns(uint256 approveOfferAmount){
        return approveOfferAmount;
    }
    
    function getAllowance(address _token, address _owner) public view returns (uint256){
        return ERC20Interface(_token).allowance.gas(GAS_LIMIT)(_owner, address(paymentHandler));
    }
    
    function getBalance(address _token, address _owner) public view returns(uint256){
        return ERC20Interface(_token).balanceOf.gas(GAS_LIMIT)(_owner);
    }

    function isRoundingError(uint numerator, uint denominator, uint target) internal pure returns(bool){
        uint remainder = mulmod(target, numerator, denominator);
        if (remainder == 0) { return false; }

        uint errPercentageTimes1000000 = SafeMath.div(SafeMath.mul(remainder, 1000000), SafeMath.mul(numerator, target));
        return errPercentageTimes1000000 > 1000;
    }
    
    function validSignature(address _signer, bytes32 _debtHash, bytes _sig) public pure returns(bool){
        return _signer == ECRecovery.recover(_debtHash, _sig);
    }
    
    function getPartialAmount(uint256 numerator, uint256 denominator, uint256 target) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(numerator, target), denominator);
    }
    
    function getPrincipal(bytes32 debtHash) public view returns(uint256){
        return externalStorage.getUIntValue(debtHash, keccak256('Principal'));
    }
    
    function getOutstandingDebt(bytes32 debtHash) public view returns(uint256){
        // Outstanding = (Principal + AccruedInterest) - AmountRepaid
        return externalStorage.getUIntValue(debtHash, keccak256('Outstanding'));
    }
    
    function getInterestAccrued(address _requestor) public view returns(uint256){
        //return externalStorage.getRequestCount(_requestor);
    }

    function forgiveDebt(bytes32 debtHash, uint256 amountToForgive) public returns(bool){
        // also need to reduce principal by Lender amount not withdrawn and possibly some interest accrued?
        externalStorage.setLenderBooleanValue(debtHash, msg.sender, keccak256("ForgiveDebt"), true);
    }
    
    function keyExists(bytes32 _requestID) internal view returns(bool){
        return externalStorage.getBooleanValue(_requestID, keccak256('Exists'));
    }
    
    function isContract(address addr) returns (bool) {
      uint size;
      assembly { size := extcodesize(addr) }
      return size > 0;
    }
    
    /**
    * @dev Prevent New Request Propagation, Allows Existing Withdrawals To Complete
    * @param _supercededBy Protocol Contract That Replaces This Version
    * @return Status
    */
    function deprecateContract(address _supercededBy) public onlyOwner returns(bool){
        require(!deprecated);
        emit DeprecatedEvent(_supercededBy);
        return deprecated = true;
    }
    
    /**
    * @dev Global Trigger To Stop All State Changes & Transfers
    * @return Status
    */
    function lockContract() public onlyOwner returns(bool){
        require(!locked);
        emit LockedEvent(true);
        return locked = true;
    }

    /**
    * @dev Unlock
    * @return Status
    */
    function unlockContract() public onlyOwner returns(bool){
        require(locked);
        emit LockedEvent(false);
        return locked = false;
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
