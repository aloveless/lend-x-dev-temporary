pragma solidity ^0.4.18;

/*
Implements ERC20 token standard: https://github.com/ethereum/EIPs/issues/20
.*/

contract ERC20 {
    string  constant public name = "Lend-X";
    string  constant public symbol = "LEND";
    uint8   constant public decimals = 18;
    uint256 constant public _totalSupply = 50000000 * 10 ** uint256(decimals);
    uint256 constant private MAX_UINT256 = 2**256 - 1;
    
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    function ERC20() public {
        balances[msg.sender] = _totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        // Andrew - Added next two requires
        // Ensures that tokens are not sent to address "0x0"
        // Ensures tokens are not sent to this contract
        require(_to != address(0));
        require(_to != address(this));
        
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value); 
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
