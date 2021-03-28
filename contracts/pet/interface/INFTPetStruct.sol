pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface INFTPetStruct {
    //宠物结构体
    struct Pet {
        uint64 tokenId;//代币ID
        uint64 serialNum;//序号
        uint64 level;//等级
        uint64 growthValue;//成长值
        uint64 coolTime;//战斗冷却时间
        uint64 addition;//额外加成百分比
        bool bonus;//分红属性
    }
    //编号对应 => URI
    //编号对应 => 额外加成
    //编号对应 => 对应多个组合的集合 [[1,2,3,4],[10,11,12]]
    //编号是否存在
    //map长度
    struct SerialProperty {
        mapping(uint64 => string) serialToURI;
        mapping(uint64 => uint64) serialToAddition;
        //mapping(uint64 => uint64[][]) serialToRelation;
        mapping(uint64 => bool) exist;
        uint256 len;
    }
}