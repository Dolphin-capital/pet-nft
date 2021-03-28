pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./INFTPetStruct.sol";

interface INFTPet is INFTPetStruct {
    //事件
    event MintPet(address indexed _to, uint256 _tokenId, uint64 _serialNum, uint64 _level, uint64 _growthValue, uint64 _coolTime, uint64 _addition, bool _bonus);
    event BurnPet(uint256 indexed _tokenId);
    event UpdatePet(uint256 indexed _tokenId, uint64 _level, uint64 _growthValue, uint64 _coolTime, bool _bonus);
    event AddSerialProperty(uint64 _serialNum,string _uri, uint64 _addition);
    event UpdateSerialProperty(uint64 _serialNum,string _uri, uint64 _addition);

    //管理员可以铸造新宠物
    function mintPet(address _to, uint64 _serialNum, uint64 _level, uint64 _growthValue, uint64 _coolTime, bool _bonus) external returns (uint256 tokenID);
    //管理员可以销毁宠物
    function burnPet(uint256 _tokenId) external;
    //管理员可以改变宠物的属性
    function updatePet(uint256 _tokenId, uint64 _level, uint64 _growthValue, uint64 _coolTime, bool _bonus) external;
    //获取调用者拥有的PetID的集合
    function getPetTokenIds() external view returns (uint256[] memory);
    //通过tokenId获取pet属性
    function getPetByTokenId(uint256 _tokenId) external view returns (Pet memory);
    //获取该用户拥有的pet属性的集合
    function getPets(uint256 page) external view returns (Pet[] memory,uint256);
    //获得tokenURI
    function tokenUri(uint256 tokenId) external view returns (string memory);
    //设置BaseURI
    function setBaseURI(string memory _baseURI) external;
    //设置编号属性
    function addSerialProperty(string memory _uri, uint64 _addition) external;
    //更新编号属性
    function updateSerialProperty(uint64 _serialNum, string memory _uri, uint64 _addition) external;
    //获取编号对应的URI和额外加成
    function getSerialPropertyByNum(uint64 _serialNum) external view  returns (string memory, uint64);
    //获取编号属性长度
    function getSerialLen() external  view returns (uint256);
}