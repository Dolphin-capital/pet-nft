pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IShopStruct {
    //活动开始时间，结束时间
    struct Activity {
        uint64 startTime;
        uint64 endTime;
        address payToken0;
        address payToken1;
    }
    //订单
    struct Order {
        uint256 TokenId;//721TokenId
        uint256 createTime;//创建时间
        uint256 price;//价格
        address payToken;//支付币种
    }
    //价格
    struct Price {
        uint256 HUSD;
        uint256 USDT;
        uint256 PETFood;
    }
}