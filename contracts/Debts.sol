pragma solidity 0.4.18;

contract Debts {
    address public owner;
    mapping(address => uint) public debts;

    event Borrowed(address indexed by, uint value);
    event Repayed(address indexed by, uint value);

    modifier onlyOwner() {
        if (msg.sender != owner) {
            return;
        }
        _;
    }

    modifier onlyNotOwner() {
        if (msg.sender == owner) {
            return;
        }
        _;
    }

    function Debts() {
        owner = msg.sender;
    }

    function borrow(uint _value) onlyNotOwner() returns(bool) {
        debts[msg.sender] = _safeAdd(debts[msg.sender], _value);
        Borrowed(msg.sender, _value);
        return true;
    }

    function repay(address _by, uint _value) onlyOwner() returns(bool) {
        debts[_by] = _safeSub(debts[_by], _value);
        Repayed(_by, _value);
        return true;
    }

    function _safeSub(uint _a, uint _b) internal constant returns(uint) {
        require(_b <= _a);
        return _a - _b;
    }

    function _safeAdd(uint _a, uint _b) internal constant returns(uint) {
        uint c = _a + _b;
        require(c >= _a);
        return c;
    }
}
