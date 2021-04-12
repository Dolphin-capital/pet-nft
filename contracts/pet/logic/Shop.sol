pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../lib/math/SafeMath.sol";
import "../lib/token/ERC20/IERC20.sol";
import "../lib/token/ERC20/SafeERC20.sol";
import "../lib/Manager.sol";
import "../interface/INFTPet.sol";
import "../interface/IShop.sol";
import "../lib/math/SafeMath64.sol";
import "../lib/math/SafeMath32.sol";
import "../lib/IERC20EX.sol";
import "../lib/math/Math.sol";

contract Shop is Manager, IShop {
    using SafeMath for uint256;
    using SafeMath64 for uint64;
    using SafeMath32 for uint32;
    using SafeERC20 for IERC20;
    using Address for address;
    Activity public activity;
    uint32[] internal saleNumber = [1024, 512, 256, 128, 64, 32, 16, 8, 4, 2];
    uint32[] internal saleNumLeft = [1024, 512, 256, 128, 64, 32, 16, 8, 4, 2];
    uint32[] internal serialNumWeightList;
    uint32 internal serialNumWeightSum;
    uint256 internal blindBoxLeft;
    uint256 internal lowestGVal;
    uint256 internal growRatio;
    uint256[] internal levelGVals;
    Price internal blindBoxPrice;
    address internal HUSD;
    address internal USDT;
    address internal PETFoodToken;
    address internal NFT_PET;
    address internal NFTREWARD;
    address internal feeTo;
    mapping(address => Order[]) internal userOrders;
    uint256[] internal allocateRate = [50, 10, 40];
    constructor(
        uint _lowestGVal,
        uint _growRatio,
        address _husd,
        address _usdt,
        address _petFood,
        address _nft_pet,
        address _nft_reward) public {
        blindBoxLeft = uint256(blindBoxTotal());
        HUSD = _husd;
        USDT = _usdt;
        NFT_PET = _nft_pet;
        PETFoodToken = _petFood;
        feeTo = msg.sender;
        NFTREWARD = _nft_reward;
        lowestGVal = _lowestGVal;
        growRatio = _growRatio;
        for (uint256 i = 0; i < saleNumber.length; i++) {
            levelGVals.push(_lowestGVal.mul(2 ** i).mul(_growRatio ** i).div(10 ** i));
        }
    }

    modifier activityConfirm(address _payToken) {
        uint64 t = uint64(block.timestamp);
        require(t >= activity.startTime && t <= activity.endTime, "Inactive time");
        require(activity.payToken0 == _payToken || activity.payToken1 == _payToken, "invaild token");
        _;
    }

    function rand(uint256 divNum, uint256 i, uint256 j) internal view returns (uint256){
        uint256 randNum = uint256(
            keccak256(abi.encodePacked(block.number
        , msg.sender, block.timestamp, i, j))).mod(divNum);
        return randNum;
    }
    function randSerialNum(uint256 nonce) internal view returns (uint256) {
        uint32 tempSum = serialNumWeightSum;
        for (uint256 i = 1; i < serialNumWeightList.length; i += 2) {
            uint256 randomNum = rand(tempSum, i, nonce);
            if (randomNum < serialNumWeightList[i]) {
                return serialNumWeightList[i - 1];
            }
            tempSum = tempSum.sub(serialNumWeightList[i]);
        }
    }
    function randNft(uint256 number, uint256 price, address payToken) internal {
        for (uint256 i = 0; i < number; i++) {
            uint256 nonce = 0;
            uint64 _level;
            uint64 _growthValue;
            uint64 _coolTime = uint64(block.timestamp);
            uint256 tempBlindBoxLeft = blindBoxLeft;
            uint256 _serialNum = randSerialNum(i);
            for (uint256 j = 0; j < saleNumLeft.length; j++) {
                nonce ++;
                uint256 randomNum = rand(tempBlindBoxLeft, i, nonce);
                if (randomNum < saleNumLeft[j]) {
                    blindBoxLeft = blindBoxLeft.sub(1);
                    saleNumLeft[j] = saleNumLeft[j].sub(1);
                    _level = uint64(j.add(1));
                    _growthValue = uint64(randGVal(_level, i, blindBoxLeft));
                    uint256 tokenId = INFTPet(NFT_PET).mintPet(msg.sender, uint64(_serialNum), _level, _growthValue, _coolTime, false);
                    userOrders[msg.sender].push(Order(tokenId, block.timestamp, price, payToken));
                    break;
                }
                tempBlindBoxLeft = tempBlindBoxLeft.sub(saleNumLeft[j]);
            }
        }
    }
    function randGVal(uint64 _level, uint256 i, uint256 j) internal view returns (uint256) {
        uint256 gVal = levelGVals[_level.sub(1)];
        uint256 gValHalf = gVal.div(2);
        return gValHalf.add(rand(gVal, i, j));
    }
    function blindBoxTotal() public view override returns (uint32) {
        uint32 left;
        for (uint256 i = 0; i < saleNumber.length; i++) {
            left += saleNumber[i];
        }
        return left;
    }
    function buyNFTUseHUSD(uint256 _amount) external override activityConfirm(HUSD) {
        require(_amount <= IERC20(HUSD).allowance(msg.sender, address(this)), "not enough approve");
        require(_amount.div(blindBoxPrice.HUSD) > 0 && _amount.div(blindBoxPrice.HUSD) <= 5, "_amount illegal");
        require(blindBoxLeft.sub(_amount.div(blindBoxPrice.HUSD)) >= 0, "blind box not enough");
        IERC20(HUSD).transferFrom(msg.sender, feeTo, _amount.div(blindBoxPrice.HUSD).mul(blindBoxPrice.HUSD));
        randNft(_amount.div(blindBoxPrice.HUSD), blindBoxPrice.HUSD, HUSD);

        emit BuyNFTUseHUSD(msg.sender, _amount);
    }
    function buyNFTUseUSDT(uint256 _amount) external override activityConfirm(USDT) {
        require(_amount <= IERC20(USDT).allowance(msg.sender, address(this)), "not enough approve");
        require(_amount.div(blindBoxPrice.USDT) > 0 && _amount.div(blindBoxPrice.USDT) <= 5, "_amount illegal");
        require(blindBoxLeft.sub(_amount.div(blindBoxPrice.USDT)) >= 0, "blind box not enough");
        IERC20(USDT).transferFrom(msg.sender, feeTo, _amount.div(blindBoxPrice.USDT).mul(blindBoxPrice.USDT));
        randNft(_amount.div(blindBoxPrice.USDT), blindBoxPrice.USDT, USDT);

        emit BuyNFTUseUSDT(msg.sender, _amount);
    }
    function buyNFTUsePETFoodToken(uint256 _amount) external override activityConfirm(PETFoodToken) {
        require(_amount <= IERC20(PETFoodToken).allowance(msg.sender, address(this)), "not enough approve");
        require(_amount.div(blindBoxPrice.PETFood) > 0 && _amount.div(blindBoxPrice.PETFood) <= 5, "_amount not enough");
        require(blindBoxLeft.sub(_amount.div(blindBoxPrice.PETFood)) >= 0, "blind box not enough");

        _amount = _amount.div(blindBoxPrice.PETFood).mul(blindBoxPrice.PETFood);
        IERC20(PETFoodToken).safeTransferFrom(msg.sender, NFTREWARD, _amount.div(100).mul(allocateRate[0]));
        IERC20(PETFoodToken).safeTransferFrom(msg.sender, feeTo, _amount.div(100).mul(allocateRate[1]));
        IERC20EX(PETFoodToken).burn(msg.sender, _amount.div(100).mul(allocateRate[2]));

        randNft(_amount.div(blindBoxPrice.PETFood), blindBoxPrice.PETFood, PETFoodToken);
        emit BuyNFTUsePETFoodToken(msg.sender, _amount);
    }
    function setHUSD(address _husd) external override onlyManagers {
        HUSD = _husd;
    }
    function setUSDT(address _usdt) external override onlyManagers {
        USDT = _usdt;
    }
    function setPETFoodToken(address _petFoodToken) external override onlyManagers {
        PETFoodToken = _petFoodToken;
    }
    function setNFT(address _nft) external override onlyManagers {
        NFT_PET = _nft;
    }
    function setFeeTo(address _feeTo) external override onlyManagers {
        feeTo = _feeTo;
    }
    function setBlindBoxPrice(uint256 _husd, uint256 _usdt, uint256 _dogFood) external override onlyManagers {
        blindBoxPrice = Price(_husd, _usdt, _dogFood);
    }
    function setActivity(uint64 _start, uint64 _end, address _payToken0, address _payToken1) external override onlyManagers {
        activity.startTime = _start;
        activity.endTime = _end;
        activity.payToken0 = _payToken0;
        activity.payToken1 = _payToken1;
    }
    function setGrawVal(uint256 _lowestGVal, uint256 _growRatio) external override onlyManagers {
        lowestGVal = _lowestGVal;
        growRatio = _growRatio;
        uint256[] memory tempLevelGVals = new uint256[](saleNumber.length);
        for (uint256 i = 0; i < saleNumber.length; i++) {
            tempLevelGVals[i] = _lowestGVal.mul(2 ** i).mul(_growRatio ** i).div(10 ** i);
        }
        levelGVals = tempLevelGVals;
    }
    function setSaleNumber(uint32[] calldata _saleNumber) external override onlyManagers {
        require(_saleNumber.length == 10, "saleNumber length must ten");
        saleNumber = _saleNumber;
        saleNumLeft = _saleNumber;
        blindBoxLeft = uint256(blindBoxTotal());
    }
    function setSerialNumWeight(uint32[] calldata _serialNumWeight) external override onlyManagers {
        require(_serialNumWeight.length > 1 && _serialNumWeight.length.mod(2) == 0, "Integer must multiples of 2");
        serialNumWeightList = _serialNumWeight;
        serialNumWeightSum = 0;
        for (uint i = 1; i < serialNumWeightList.length; i += 2) {
            serialNumWeightSum += serialNumWeightList[i];
        }
    }
    function setAllocateRate(uint256[] calldata _allocateRate) external override onlyManagers {
        allocateRate = _allocateRate;
    }
    function getOrders(uint256 page) external view override returns (Order[] memory, uint256){
        require(page >= 1, "page must >= 1");
        uint256 size = 20;
        uint256 len = userOrders[msg.sender].length;
        uint256 from = (page - 1).mul(size);
        uint256 to = Math.min(page.mul(size), len);
        if (from >= len) {
            from = 0;
            to = len;
        }
        Order[] memory orders = new Order[](to - from);
        for (uint256 i = 0; from < to; ++i) {
            orders[i] = userOrders[msg.sender][from];
            ++from;
        }
        return (orders, len);
    }
    function getSaleNumber() external view override returns (uint32[] memory){
        return saleNumber;
    }
    function getSaleNumLeft() external view override returns (uint32[] memory){
        return saleNumLeft;
    }
    function getActivity() external view override returns (Activity memory) {
        return activity;
    }
    function getBlindBoxLeft() external view override returns (uint256) {
        return blindBoxLeft;
    }
    function getLowestGVal() external view override returns (uint256) {
        return lowestGVal;
    }
    function getGrowRatio() external view override returns (uint256) {
        return growRatio;
    }
    function getLevelGVals() external view override returns (uint256[] memory) {
        return levelGVals;
    }
    function getBlindBoxPrice() external view override returns (Price memory) {
        return blindBoxPrice;
    }
    function getAddress() external view override onlyManagers returns (address[] memory) {
        address[] memory addrs = new address[](6);
        addrs[0] = HUSD;
        addrs[1] = USDT;
        addrs[2] = PETFoodToken;
        addrs[3] = NFT_PET;
        addrs[4] = feeTo;
        addrs[5] = NFTREWARD;
        return addrs;
    }
    function getAllocateRate() external view override returns (uint256[] memory) {
        return allocateRate;
    }
    function getSerialNumWeight() external view override returns (uint32[] memory,uint32) {
        return (serialNumWeightList,serialNumWeightSum);
    }
    function aggregateShop() external view override returns (uint32, uint32, uint32[] memory, uint32[] memory, Activity memory, Price memory){
        uint32 bTotal = blindBoxTotal();
        return (bTotal, uint32(blindBoxLeft), saleNumber, saleNumLeft, activity, blindBoxPrice);
    }
}
