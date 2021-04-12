pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./INFTPetStruct.sol";

interface INFTPet is INFTPetStruct {
    event MintPet(address indexed _to, uint256 _tokenId, uint64 _serialNum, uint64 _level, uint64 _growthValue, uint64 _coolTime, uint64 _addition, bool _bonus);
    event BurnPet(uint256 indexed _tokenId);
    event UpdatePet(uint256 indexed _tokenId, uint64 _level, uint64 _growthValue, uint64 _coolTime, bool _bonus);
    event AddSerialProperty(uint64 _serialNum,string _uri, uint64 _addition);
    event UpdateSerialProperty(uint64 _serialNum,string _uri, uint64 _addition);

    function mintPet(address _to, uint64 _serialNum, uint64 _level, uint64 _growthValue, uint64 _coolTime, bool _bonus) external returns (uint256 tokenID);
    function burnPet(uint256 _tokenId) external;
    function updatePet(uint256 _tokenId, uint64 _level, uint64 _growthValue, uint64 _coolTime, bool _bonus) external;
    function getPetTokenIds() external view returns (uint256[] memory);
    function getPetByTokenId(uint256 _tokenId) external view returns (Pet memory);
    function getPets(uint256 page) external view returns (Pet[] memory,uint256);
    function getPets() external view returns (Pet[] memory);
    function tokenUri(uint256 tokenId) external view returns (string memory);
    function setBaseURI(string memory _baseURI) external;
    function addSerialProperty(string memory _uri, uint64 _addition) external;
    function updateSerialProperty(uint64 _serialNum, string memory _uri, uint64 _addition) external;
    function getSerialPropertyByNum(uint64 _serialNum) external view  returns (string memory, uint64);
    function getSerialLen() external  view returns (uint256);
}