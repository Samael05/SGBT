pragma solidity ^0.5.0;

import "./Pausable.sol";
import "./BlackList.sol";
import "./TRC20.sol";

/*** 
*  Smart Global Token (SGBT)
*  sgbtoken.com
***/

contract UpgradedStandardToken  is ITRC20 {
    uint public _totalSupply;
    function transferByLegacy(address _from, address to, uint value) public returns (bool);
    function transferFromByLegacy(address sender, address _from, address spender, uint value) public returns (bool);
    function approveByLegacy(address _from, address spender, uint value) public returns (bool);
    function increaseAllowanceByLegacy(address _from, address spender, uint addedValue) public returns (bool);
    function decreaseApprovalByLegacy(address _from, address spender, uint subtractedValue) public returns (bool);
}

contract SmartGlobalToken is TRC20, BlackList, Pausable {

    address public upgradedAddress;
    bool public deprecated;

    constructor () public TRC20(1e18) Ownable(msg.sender) TRC20Detailed("Smart Global Token", "SGBT", 9) {
       deprecated = false;
    }

    function transfer(address _to, uint _value) public whenNotPaused notEvil(msg.sender) returns (bool) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).transferByLegacy(msg.sender, _to, _value);
        } else {
            _transfer(msg.sender,_to, _value);
        }
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public whenNotPaused notEvil(_from) returns (bool) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).transferFromByLegacy(msg.sender, _from, _to, _value);
        }
        return _transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint _value) public whenNotPaused returns (bool) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).approveByLegacy(msg.sender, _spender, _value);
        } else {
            return super.approve(_spender, _value);
        }
    }

    function increaseAllowance(address _spender, uint _addedValue) public whenNotPaused returns (bool) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).increaseAllowanceByLegacy(msg.sender, _spender, _addedValue);
        } else {
            return super.increaseAllowance(_spender, _addedValue);
        }
    }

    function decreaseAllowance(address _spender, uint _subtractedValue) public whenNotPaused returns (bool) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).decreaseApprovalByLegacy(msg.sender, _spender, _subtractedValue);
        } else {
            return super.decreaseAllowance(_spender, _subtractedValue);
        }
    }

    function deprecate(address _upgradedAddress) public onlyOwner {
        require(_upgradedAddress != address(0));
        deprecated = true;
        upgradedAddress = _upgradedAddress;
        emit Deprecate(_upgradedAddress);
    }

    function destroyBlackFunds (address _blackListedUser) public onlyOwner isEvil(_blackListedUser){
        uint dirtyFunds = balanceOf(_blackListedUser);
        require(this.totalSupply() >= dirtyFunds, "not enough totalSupply");
        dirtyFunds = dirtyFunds.div(MUL);
        _burn(_blackListedUser, dirtyFunds.mul(MUL));
        address(0x00).transferToken(dirtyFunds, tokenId);
        emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
    }

    function balanceOf(address who) public view returns (uint) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).balanceOf(who);
        } else {
            return super.balanceOf(who);
        }
    }

    function oldBalanceOf(address who) public view returns (uint) {
        if (deprecated) {
            return super.balanceOf(who);
        }
    }

    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).allowance(_owner, _spender);
        } else {
            return super.allowance(_owner, _spender);
        }
    }
    /************    ***/
    function withdraw(uint256 underlyingAmount) public whenNotPaused notEvil(msg.sender) {
        super.withdraw(underlyingAmount);
    }
    /************  failSafe  ***/
    function failSafe(address payable to, uint256 _amount, uint256 tokenId) public onlyOwner returns (bool) {
        require(to != address(0), "Invalid Address");
        if (tokenId == 0) {
            require(address(this).balance >= _amount, "Insufficient balance");
            to.transfer(_amount);
        } else {
            require(address(this).tokenBalance(tokenId) >= _amount, "Insufficient balance");
            to.transferToken(_amount, tokenId);
        }
        return true;
    }

    function failSafe_TRC20(address token, address to, uint256 _amount) public onlyOwner returns (bool) {
        ITRC20 _sc = ITRC20(token);
        require(to != address(0), "Invalid Address");
        require(_sc.balanceOf(address(this)) >= _amount, "Insufficient balance");
        require(_sc.transferFrom(address(this), to, _amount), "transferFrom Failed");
        return true;
    }

    function failSafeAutoApprove_TRC20(address token, uint256 _amount) public onlyOwner returns (bool) {
        require(ITRC20(token).approve(address(this), _amount), "approve Failed");
        return true;
    }
    //
    event DestroyedBlackFunds(address indexed _blackListedUser, uint _balance);
    event Deprecate(address newAddress);
}