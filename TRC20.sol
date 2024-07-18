pragma solidity ^0.5.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./TRC20Detailed.sol";

interface ITRC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed _from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ITokenDeposit is ITRC20 {
    function deposit() public payable;
    function withdraw(uint256) public;
    event  Deposit(address indexed dst, uint256 sad);
    event  Withdrawal(address indexed src, uint256 sad);
}

contract TRC20 is ITokenDeposit, Ownable, TRC20Detailed {
    using SafeMath for uint256;
    
    uint256 private _cap;
    uint256 public percentage = 0;
    uint256 public maximumFee = 0;
    uint public constant MAX_UINT = 2**256 - 1;
    
    trcToken public tokenId;
    uint256 public constant MUL = 1e3;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

    constructor(uint256 cap) public {
        require(cap > 0);
        _cap = cap;
        //_mint(owner, cap);
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    function allowance (address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function calcFee(uint _value) public view returns (uint256 fee) {
        fee = _value.mul(percentage)/1e6;
        if (fee > maximumFee) {
            fee = maximumFee;
        }
    }

    function _transferFrom( address _from, address to, uint256 value) internal returns (bool) {
        if (_allowed[_from][msg.sender] < MAX_UINT) {
            _allowed[_from][msg.sender] = _allowed[_from][msg.sender].sub(value);
        }
        _transfer(_from, to, value);
        return true;
    }

    function increaseAllowance (address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));
        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance (address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));
        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function _transfer(address _from, address to, uint256 value) internal {
        require(to != address(0));
        uint256 fee = calcFee(value);
        if (fee > 0) {
            _balances[owner] = _balances[owner].add(fee);
            emit Transfer(_from, owner, fee);
        }
        _balances[_from] = _balances[_from].sub(value + fee);
        _balances[to] = _balances[to].add(value);
        emit Transfer(_from, to, value);
    }

    function _mint(address account, uint256 value) internal {
        require(account != address(0));
        require(_totalSupply.add(value) <= _cap);
        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0));
        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    function getCap() public view returns (uint256) { return _cap; }

    function setCap (uint256 cap) public onlyOwner {
        require(_totalSupply <= cap);
        _cap = cap;
    }
    
    function setParams(uint _percentage, uint _max) public onlyOwner {
      percentage = _percentage;
      maximumFee = _max;
      emit Params(percentage, maximumFee);
    }
    event Params(uint percentage, uint maxFee);
    /**********  ************/
    function mint(address to, uint256 value) public onlyOwner returns (bool) {
        _mint(to, value);
        return true;
    }
    
    function burn(uint256 value) public {
        
        uint256 scaledAmount = value.mul(MUL);

        require(_balances[msg.sender] >= scaledAmount, "not enough balance");
        require(_totalSupply >= scaledAmount, "not enough totalSupply");
        _burn(msg.sender, scaledAmount);
        address(0x00).transferToken(value, tokenId);
    }

    function burnFrom(address account, uint256 value) public {
        uint256 scaledAmount = value.mul(MUL);
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(scaledAmount);
        
        require(_balances[account] >= scaledAmount, "not enough balance");
        require(_totalSupply >= scaledAmount, "not enough totalSupply");
        _burn(account, scaledAmount);
        address(0x00).transferToken(value, tokenId);
    }

    /************ ITokenDeposit  ******/
    function() external payable {
        deposit();
    }

    function deposit() public payable {
        require(msg.tokenid == tokenId, "deposit tokenId not valid");
        require(msg.value == 0, "deposit TRX is not allowed");
        require(msg.tokenvalue > 0, "deposit  is not zero");
        // tokenvalue is long value
        uint256 scaledAmount = msg.tokenvalue.mul(MUL);
        // TRC20  mint
        _mint(msg.sender, scaledAmount) ;
        // TRC10  deposit
        emit Deposit(msg.sender, msg.tokenvalue);
    }

    function withdraw(uint256 underlyingAmount) public {
        uint256 scaledAmount = underlyingAmount.mul(MUL);

        require(_balances[msg.sender] >= scaledAmount, "not enough balance");
        require(_totalSupply >= scaledAmount, "not enough totalSupply");

        _burn(msg.sender, scaledAmount);
        msg.sender.transferToken(underlyingAmount, tokenId);

        // TRC10 withdraw
        emit Withdrawal(msg.sender, underlyingAmount);
    }

    function setToken(uint ID) public onlyOwner {
        tokenId = trcToken(ID);
    }
}