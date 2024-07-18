pragma solidity ^0.5.0;

import "./Ownable.sol";

contract BlackList is Ownable {

    // Getter to allow the same blacklist to be used also by other contracts
    function getBlackListStatus(address _maker) external view returns (bool) {
        return isBlackListed[_maker];
    }

    mapping (address => bool) public isBlackListed;
    
    modifier notEvil (address _address) {
        require(!isBlackListed[_address], "Logic: Address is evil");
        _;
    }
    modifier isEvil (address _address) {
        require(isBlackListed[_address], "Logic: Address is not evil");
        _;
    }
    function addBlackList (address _evilUser) public onlyOwner {
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

    function removeBlackList (address _clearedUser) public onlyOwner {
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }

    event AddedBlackList(address indexed _user);
    event RemovedBlackList(address indexed _user);
}