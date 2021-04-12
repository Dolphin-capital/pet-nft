pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../lib/token/ERC721/ERC721.sol";
import "../lib/token/ERC20/SafeERC20.sol";
import "../lib/math/SafeMath.sol";
import "../lib/math/Math.sol";
import "../lib/Manager.sol";
import "../lib/String.sol";
import "../interface/INFTPet.sol";
import "../lib/math/SafeMath64.sol";
import "../lib/math/SafeMath32.sol";
import "../lib/math/Math.sol";

contract NFTPet is ERC721('NFT PET', 'NFT.PET'), Manager, INFTPet {
    using SafeMath for uint256;
    using SafeMath64 for uint64;
    using SafeMath32 for uint32;
    using String for string;
    Pet[] private Pets;
    SerialProperty  serialProperty;

    constructor(string memory baseURI) public {
        setBaseURI(baseURI);
    }

    function mintPet(address _to, uint64 _serialNum, uint64 _level, uint64 _growthValue, uint64 _coolTime, bool _bonus) external override onlyManagers returns (uint256 tokenId)  {
        tokenId = Pets.length.add(1);
        uint64 _addition = serialProperty.serialToAddition[_serialNum];
        Pets.push(Pet(uint64(tokenId), _serialNum, _level, _growthValue, _coolTime, _addition, _bonus));
        super._safeMint(_to, tokenId);
        setTokenURI(tokenId);
        emit MintPet(_to, tokenId, _serialNum, _level, _growthValue, _coolTime, _addition, _bonus);
    }
    function burnPet(uint256 _tokenId) external override onlyManagers {
        super._burn(_tokenId);
        emit BurnPet(_tokenId);
    }
    function updatePet(uint256 _tokenId, uint64 _level, uint64 _growthValue, uint64 _coolTime, bool _bonus) external override onlyManagers {
        Pets[_tokenId.sub(1)].level = _level;
        Pets[_tokenId.sub(1)].growthValue = _growthValue;
        Pets[_tokenId.sub(1)].coolTime = _coolTime;
        Pets[_tokenId.sub(1)].bonus = _bonus;
        setTokenURI(_tokenId);
        emit UpdatePet(_tokenId, _level, _growthValue, _coolTime, _bonus);
    }
    function getPetTokenIds() external view override returns (uint256[] memory){
        uint256 balance = balanceOf(msg.sender);
        uint256[] memory ids = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(msg.sender, i);
            ids[i] = tokenId;
        }
        return ids;
    }
    function getPetByTokenId(uint256 _tokenId) public view override returns (Pet memory) {
        require(_tokenId > 0, "tokenId can not be zero");
        return Pets[_tokenId.sub(1)];
    }
    function getPets(uint256 page) external view override returns (Pet[] memory,uint256) {
        require(page >= 1, "page must >= 1");
        uint256 size = 20;
        uint256 balance = balanceOf(msg.sender);
        uint256 from = (page - 1).mul(size);
        uint256 to = Math.min(page.mul(size), balance);
        if (from >= balance) {
            from = 0;
            to = balance;
        }
        Pet[] memory pets = new Pet[](to-from);
        for (uint256 i = 0; from < to; ++i) {
            uint256 tokenId = tokenOfOwnerByIndex(msg.sender, from);
            pets[i] = Pets[tokenId.sub(1)];
            ++from;
        }
        return (pets,balance);
    }
    function tokenUri(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return base.concat(_tokenURI);
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return base;
    }
    function setTokenURI(uint256 _tokenId) internal virtual {
        Pet memory pet = getPetByTokenId(_tokenId);
        string memory _tokenURI = serialProperty.serialToURI[pet.serialNum];
        _setTokenURI(_tokenId, _tokenURI);
    }
    function setBaseURI(string memory _baseURI) public override onlyManagers {
        _setBaseURI(_baseURI);
    }
    function addSerialProperty(string memory _uri, uint64 _addition) public override onlyManagers {
        serialProperty.len += 1;
        uint64 _serialNum = uint64(serialProperty.len);
        serialProperty.exist[_serialNum] = true;
        serialProperty.serialToURI[_serialNum] = _uri;
        serialProperty.serialToAddition[_serialNum] = _addition;
        emit AddSerialProperty(_serialNum, _uri, _addition);
    }
    function updateSerialProperty(uint64 _serialNum, string memory _uri, uint64 _addition) public override onlyManagers {
        require(serialProperty.exist[_serialNum], "serialNum not exist");
        serialProperty.serialToURI[_serialNum] = _uri;
        serialProperty.serialToAddition[_serialNum] = _addition;
        emit UpdateSerialProperty(_serialNum, _uri, _addition);
    }
    function getSerialPropertyByNum(uint64 _serialNum) external view override returns (string memory, uint64) {
        require(serialProperty.exist[_serialNum], "this serial num not exist");
        return (serialProperty.serialToURI[_serialNum], serialProperty.serialToAddition[_serialNum]);
    }
    function getSerialLen() external override view returns (uint256) {
        return serialProperty.len;
    }
}