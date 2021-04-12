pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface INFTPetStruct {
    struct Pet {
        uint64 tokenId;
        uint64 serialNum;
        uint64 level;
        uint64 growthValue;
        uint64 coolTime;
        uint64 addition;
        bool bonus;
    }
    struct SerialProperty {
        mapping(uint64 => string) serialToURI;
        mapping(uint64 => uint64) serialToAddition;
        //mapping(uint64 => uint64[][]) serialToRelation;
        mapping(uint64 => bool) exist;
        uint256 len;
    }
}