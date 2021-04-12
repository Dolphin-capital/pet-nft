pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IShopStruct {
    struct Activity {
        uint64 startTime;
        uint64 endTime;
        address payToken0;
        address payToken1;
    }
    struct Order {
        uint256 TokenId;
        uint256 createTime;
        uint256 price;
        address payToken;
    }
    struct Price {
        uint256 HUSD;
        uint256 USDT;
        uint256 PETFood;
    }
}