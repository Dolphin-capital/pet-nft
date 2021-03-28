pragma solidity 0.6.12;

import "../lib/token/ERC20/ERC20.sol";
import "../lib/Manager.sol";


contract TokenPetFood is ERC20("Pet Food Token", "PFT"), Manager {
    function mint(address _to, uint256 _amount) public onlyManagers {
        _mint(_to, _amount);
    }
    function burn(address _to, uint256 _amount) public onlyManagers {
        _burn(_to, _amount);
    }
}