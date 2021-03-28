pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./IShopStruct.sol";

interface IShop is IShopStruct {
    //事件
    event BuyNFTUseHUSD(address indexd, uint256);
    event BuyNFTUseUSDT(address indexd, uint256);
    event BuyNFTUsePETFoodToken(address indexd, uint256);
    //获取盲盒总量
    function blindBoxTotal() external view returns (uint32);
    //通过HUSD购买NFT
    function buyNFTUseHUSD(uint256 _amount) external;
    //通过USDT购买NFT
    function buyNFTUseUSDT(uint256 _amount) external;
    //通过PETFood购买NFT
    function buyNFTUsePETFoodToken(uint256 _amount) external;
    //设置HUSD的合约地址
    function setHUSD(address _husd) external;
    //设置USDT的合约地址
    function setUSDT(address _usdt) external;
    //设置petfood币的合约地址
    function setPETFoodToken(address _petFoodToken) external;
    //设置NFT的地址
    function setNFT(address _nft) external;
    //设置fee地址
    function setFeeTo(address _fee) external;
    //设置盲盒价格
    function setBlindBoxPrice(uint256 _husd, uint256 _usdt, uint256 _petFood) external;
    //设置活动
    function setActivity(uint64 _start, uint64 _end, address _payToken0, address _payToken1) external;
    //设置成长值
    function setGrawVal(uint256 _lowestGVal, uint256 _growRatio) external;
    //设置每个等级的出售数量
    function setSaleNumber(uint32[] calldata _saleNumber) external;
    //设置盲盒编号权重
    function setSerialNumWeight(uint32[] calldata _serialNumWeight) external;
    //设置分红点
    function setAllocateRate(uint256[] calldata _allocateRate) external;
    //获取订单
    function getOrders(uint256 page) external view returns (Order[] memory,uint256);
    //获取每种等级盒子的数量
    function getSaleNumber() external view returns (uint32[] memory);
    //获取每种等级盒子的剩余数量
    function getSaleNumLeft() external view returns (uint32[] memory);
    //获取活动详情，活动开始时间结束时间支持的币种
    function getActivity() external view returns (Activity memory);
    //获取盲盒剩余数量 blindBoxLeft
    function getBlindBoxLeft() external view returns (uint256);
    //获取最低等级的平均成长值
    function getLowestGVal() external view returns (uint256);
    //获取成长率
    function getGrowRatio() external view returns (uint256);
    //获取不同等级的平均成长值集合1-10级
    function getLevelGVals() external view returns (uint256[] memory);
    //盲盒售价分别是 husd单价  usdt单价 PFT单价
    function getBlindBoxPrice() external view returns (Price memory);
    //HUSD地址、USDT地址、PET代币地址、NFT_PET、盲盒收入地址
    function getAddress() external view returns (address[] memory);
    //获取分红比例[分红比例，开发者比例，销毁比例]
    function getAllocateRate() external view returns (uint256[] memory);
    //获取编号权重
    function getSerialNumWeight() external view  returns (uint32[] memory,uint32);
    //商店聚合方法
    function aggregateShop() external view returns(uint32,uint32,uint32[] memory,uint32[] memory,Activity memory,Price memory);
}