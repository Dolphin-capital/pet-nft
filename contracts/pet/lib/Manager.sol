pragma solidity >=0.6.0 <0.8.0;

import "./access/Ownable.sol";


abstract contract Manager is Ownable {
    //管理员地址映射
    mapping(address => bool) public managers;

    constructor () internal {
        address ownerAddr = owner();
        setManager(ownerAddr);
    }
    //modifier
    modifier onlyManagers() {
        require(managers[msg.sender]);
        _;
    }

    event SetManager(address _manager);
    event RemoveManager(address _manager);

    function setManager(address _manager) public onlyOwner {
        managers[_manager] = true;
        emit SetManager(_manager);
    }

    function removeManager(address _manager) public onlyOwner {
        delete managers[_manager];
        emit RemoveManager(_manager);
    }

}
