pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./IShopStruct.sol";

interface IShop is IShopStruct {
    event BuyNFTUseHUSD(address indexd, uint256);
    event BuyNFTUseUSDT(address indexd, uint256);
    event BuyNFTUsePETFoodToken(address indexd, uint256);
    function blindBoxTotal() external view returns (uint32);
    function buyNFTUseHUSD(uint256 _amount) external;
    function buyNFTUseUSDT(uint256 _amount) external;
    function buyNFTUsePETFoodToken(uint256 _amount) external;
    function setHUSD(address _husd) external;
    function setUSDT(address _usdt) external;
    function setPETFoodToken(address _petFoodToken) external;
    function setNFT(address _nft) external;
    function setFeeTo(address _fee) external;
    function setBlindBoxPrice(uint256 _husd, uint256 _usdt, uint256 _petFood) external;
    function setActivity(uint64 _start, uint64 _end, address _payToken0, address _payToken1) external;
    function setGrawVal(uint256 _lowestGVal, uint256 _growRatio) external;
    function setSaleNumber(uint32[] calldata _saleNumber) external;
    function setSerialNumWeight(uint32[] calldata _serialNumWeight) external;
    function setAllocateRate(uint256[] calldata _allocateRate) external;
    function getOrders(uint256 page) external view returns (Order[] memory,uint256);
    function getSaleNumber() external view returns (uint32[] memory);
    function getSaleNumLeft() external view returns (uint32[] memory);
    function getActivity() external view returns (Activity memory);
    function getBlindBoxLeft() external view returns (uint256);
    function getLowestGVal() external view returns (uint256);
    function getGrowRatio() external view returns (uint256);
    function getLevelGVals() external view returns (uint256[] memory);
    function getBlindBoxPrice() external view returns (Price memory);
    function getAddress() external view returns (address[] memory);
    function getAllocateRate() external view returns (uint256[] memory);
    function getSerialNumWeight() external view  returns (uint32[] memory,uint32);
    function aggregateShop() external view returns(uint32,uint32,uint32[] memory,uint32[] memory,Activity memory,Price memory);
}