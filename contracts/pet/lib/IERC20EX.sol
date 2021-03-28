pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20EX {
    function mint(address _to, uint256 _amount) external;

    function burn(address _to, uint256 _amount) external;
}