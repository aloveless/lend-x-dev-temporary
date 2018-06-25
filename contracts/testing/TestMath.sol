pragma solidity ^0.4.23;

contract TestMath {
    
    constructor() public {
      
    }
    
    function testRevert() public pure returns(uint256){
        require(1 == 2, "Test_Error");
        //return uint256(12);
    }
    
    function testMulMod(uint256 numerator, uint256 denominator, uint256 target) public pure returns(uint256){
        uint remainder = mulmod(target, numerator, denominator);
        return remainder;
    }
    
    function isRoundingError(uint lenderLoanAmount, uint principal, uint lenderAgentFee) public pure returns (uint) {
        uint remainder = mulmod(lenderAgentFee, lenderLoanAmount, principal);
        if (remainder == 0) return 0; // No rounding error.

        uint res = div(mul(remainder, 1000000), mul(lenderLoanAmount, lenderAgentFee));
        return res;
        //return res > 1000;
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
  
  function mul512(uint256 a, uint256 b) internal pure returns(uint256 r0, uint256 r1) {
      assembly {
          let mm := mulmod(a, b, not(0))
          r0 := mul(a, b)
          r1 := sub(sub(mm, r0), lt(mm, r0))
      }
  }
  
  function add512(uint256 a0, uint256 a1, uint256 b0, uint256 b1) internal pure returns(uint256 r0, uint256 r1){
      assembly{
          r0 := add(a0, b0)
          r1 := add(add(a1, b1), lt(r0, a0))
      }
  }
  
  function sub512(uint256 a0, uint256 a1, uint256 b0, uint256 b1) internal pure returns(uint256 r0, uint256 r1){
      assembly{
          r0 := sub(a0, b0)
          r1 := sub(sub(a1, b1), lt(r0, a0))
      }
  }
  
  function twoDivisor(uint256 a) internal pure returns(uint256 r){
      r = -a & a;
  }
  
  function mod256(uint256 a) internal pure returns(uint256 r){
      require(a != 0);
      assembly{
          r := mod(sub(0, a), a)
      }
  }
  
  function div256(uint256 a) internal pure returns(uint256 r){
      require(a > 1);
      assembly{
          r := add(div(sub(0, a), a), 1)
      }
  }
  
  /**
 * @title SafeMath - OpenZeppelin
 * @dev Math operations with safety checks that throw on error
 */
    /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) public pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) public pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) public pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) public pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
  
  
}
