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
    //activity时间
    Activity public activity;
    //每个等级预售数量 key: 等级 value:数量
    uint32[] internal saleNumber = [1024, 512, 256, 128, 64, 32, 16, 8, 4, 2]; //2046个，战斗力总值大概=102300
    //每个等级剩余可销预售数量
    uint32[] internal saleNumLeft = [1024, 512, 256, 128, 64, 32, 16, 8, 4, 2]; //2046个，战斗力总值大概=102300
    //编号随机权重 list = [编号，权重，编号，权重]
    uint32[] internal serialNumWeightList;
    //随机编号权重之和
    uint32 internal serialNumWeightSum;
    //盲盒剩余数量
    uint256 internal blindBoxLeft;
    //最低等级的平均成长值
    uint256 internal lowestGVal;
    //成长系数12 相当于1.2
    uint256 internal growRatio;
    //最低等级的平均成长值
    uint256[] internal levelGVals;
    //盲盒单价
    Price internal blindBoxPrice;
    //地址
    address internal HUSD;//HUSD地址
    address internal USDT;//USDT地址
    address internal PETFoodToken;//宠物粮代币地址
    address internal NFT_PET;
    address internal NFTREWARD;
    address internal feeTo; //盲盒收入地址
    //用户订单
    mapping(address => Order[]) internal userOrders;
    //分配比例
    uint256[] internal allocateRate = [50, 10, 40];
    //构造函数
    constructor(
        uint _lowestGVal,
        uint _growRatio,
        address _husd,
        address _usdt,
        address _petFood,
        address _nft_pet,
        address _nft_reward) public {
        blindBoxLeft = uint256(blindBoxTotal());
        //设置各类地址的地址
        HUSD = _husd;
        USDT = _usdt;
        NFT_PET = _nft_pet;
        PETFoodToken = _petFood;
        feeTo = msg.sender;
        NFTREWARD = _nft_reward;
        //最低等级的平均成长值
        lowestGVal = _lowestGVal;
        growRatio = _growRatio;
        //计算出平均成长值
        for (uint256 i = 0; i < saleNumber.length; i++) {
            levelGVals.push(_lowestGVal.mul(2 ** i).mul(_growRatio ** i).div(10 ** i));
        }
    }

    //装饰器
    //判断是否在活动时间
    modifier activityConfirm(address _payToken) {
        uint64 t = uint64(block.timestamp);
        require(t >= activity.startTime && t <= activity.endTime, "Inactive time");
        require(activity.payToken0 == _payToken || activity.payToken1 == _payToken, "invaild token");
        _;
    }

    //随机数函数  //随机数函数，产生 0 - (divNum-1) 范围之间的随机数
    function rand(uint256 divNum, uint256 i, uint256 j) internal view returns (uint256){
        uint256 randNum = uint256(
            keccak256(abi.encodePacked(block.number
        , msg.sender, block.timestamp, i, j))).mod(divNum);
        return randNum;
    }
    //按权重随机产生编号
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
    //获取随机产生卡片
    function randNft(uint256 number, uint256 price, address payToken) internal {
        for (uint256 i = 0; i < number; i++) {
            uint256 nonce = 0;
            uint64 _level;
            uint64 _growthValue;
            uint64 _coolTime = uint64(block.timestamp);
            //抽奖
            //临时变量：盲盒剩余数量
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
    //随机成长值
    function randGVal(uint64 _level, uint256 i, uint256 j) internal view returns (uint256) {
        //假设level1的dog平均成长值是50 那么他的数值波动范围是 25-75 ,应该在0-50的基础上都加上25
        //计算不同等级的成长值
        uint256 gVal = levelGVals[_level.sub(1)];
        //每个等级的平均成长值
        uint256 gValHalf = gVal.div(2);
        return gValHalf.add(rand(gVal, i, j));
    }
    //判断盲盒总数量
    function blindBoxTotal() public view override returns (uint32) {
        uint32 left;
        for (uint256 i = 0; i < saleNumber.length; i++) {
            left += saleNumber[i];
        }
        return left;
    }
    //通过HUSD购买NFT,最多一次购买5个
    function buyNFTUseHUSD(uint256 _amount) external override activityConfirm(HUSD) {
        //判断是否有足够授权
        require(_amount <= IERC20(HUSD).allowance(msg.sender, address(this)), "not enough approve");
        //判断输入金额是否>= blindBoxPrice.HUSD <= 5 * blindBoxPrice.HUSD
        require(_amount.div(blindBoxPrice.HUSD) > 0 && _amount.div(blindBoxPrice.HUSD) <= 5, "_amount illegal");
        //判断盲盒是否足够
        require(blindBoxLeft.sub(_amount.div(blindBoxPrice.HUSD)) >= 0, "blind box not enough");
        //转移代币到设定收费地址
        IERC20(HUSD).transferFrom(msg.sender, feeTo, _amount.div(blindBoxPrice.HUSD).mul(blindBoxPrice.HUSD));
        //_amount.div(50 * 1e8)计算出应该产生多少NFT
        randNft(_amount.div(blindBoxPrice.HUSD), blindBoxPrice.HUSD, HUSD);

        emit BuyNFTUseHUSD(msg.sender, _amount);
    }
    //通过USDT购买NFT,最多一次购买5个
    function buyNFTUseUSDT(uint256 _amount) external override activityConfirm(USDT) {
        //判断是否有足够授权
        require(_amount <= IERC20(USDT).allowance(msg.sender, address(this)), "not enough approve");
        //判断输入金额是否>= blindBoxPrice.HUSD <= 5 * blindBoxPrice.HUSD
        require(_amount.div(blindBoxPrice.USDT) > 0 && _amount.div(blindBoxPrice.USDT) <= 5, "_amount illegal");
        //判断盲盒是否足够
        require(blindBoxLeft.sub(_amount.div(blindBoxPrice.USDT)) >= 0, "blind box not enough");
        //转移代币到设定收费地址
        IERC20(USDT).transferFrom(msg.sender, feeTo, _amount.div(blindBoxPrice.USDT).mul(blindBoxPrice.USDT));
        //_amount.div(50 * 1e8)计算出应该产生多少NFT
        randNft(_amount.div(blindBoxPrice.USDT), blindBoxPrice.USDT, USDT);

        emit BuyNFTUseUSDT(msg.sender, _amount);
    }
    //通过PETFoodToken购买NFT,最多一次购买5个
    function buyNFTUsePETFoodToken(uint256 _amount) external override activityConfirm(PETFoodToken) {
        //判断是否有足够授权
        require(_amount <= IERC20(PETFoodToken).allowance(msg.sender, address(this)), "not enough approve");
        //判断输入金额是否>= blindBoxPrice.PETFood && <= 5 * blindBoxPrice.PETFood
        require(_amount.div(blindBoxPrice.PETFood) > 0 && _amount.div(blindBoxPrice.PETFood) <= 5, "_amount not enough");
        //判断盲盒是否足够
        require(blindBoxLeft.sub(_amount.div(blindBoxPrice.PETFood)) >= 0, "blind box not enough");

        _amount = _amount.div(blindBoxPrice.PETFood).mul(blindBoxPrice.PETFood);
        //往NFTReward分红池子发送PET百分之50
        IERC20(PETFoodToken).safeTransferFrom(msg.sender, NFTREWARD, _amount.div(100).mul(allocateRate[0]));
        //往开发者地址发送百分之10
        IERC20(PETFoodToken).safeTransferFrom(msg.sender, feeTo, _amount.div(100).mul(allocateRate[1]));
        //销毁百分之40
        IERC20EX(PETFoodToken).burn(msg.sender, _amount.div(100).mul(allocateRate[2]));

        randNft(_amount.div(blindBoxPrice.PETFood), blindBoxPrice.PETFood, PETFoodToken);
        emit BuyNFTUsePETFoodToken(msg.sender, _amount);
    }
    //设置HUSD的合约地址
    function setHUSD(address _husd) external override onlyManagers {
        HUSD = _husd;
    }
    //设置USDT的合约地址
    function setUSDT(address _usdt) external override onlyManagers {
        USDT = _usdt;
    }
    //设置pet代币的合约地址
    function setPETFoodToken(address _petFoodToken) external override onlyManagers {
        PETFoodToken = _petFoodToken;
    }
    //设置NFT的地址
    function setNFT(address _nft) external override onlyManagers {
        NFT_PET = _nft;
    }
    //设置fee地址
    function setFeeTo(address _feeTo) external override onlyManagers {
        feeTo = _feeTo;
    }
    //设置盲盒价格
    function setBlindBoxPrice(uint256 _husd, uint256 _usdt, uint256 _dogFood) external override onlyManagers {
        blindBoxPrice = Price(_husd, _usdt, _dogFood);
    }
    //设置活动
    function setActivity(uint64 _start, uint64 _end, address _payToken0, address _payToken1) external override onlyManagers {
        activity.startTime = _start;
        activity.endTime = _end;
        activity.payToken0 = _payToken0;
        activity.payToken1 = _payToken1;
    }
    //设置和最低级别成长值和成长系数
    function setGrawVal(uint256 _lowestGVal, uint256 _growRatio) external override onlyManagers {
        //最低等级的平均成长值
        lowestGVal = _lowestGVal;
        growRatio = _growRatio;
        //计算出平均成长值
        for (uint256 i = 0; i < saleNumber.length; i++) {
            levelGVals.push(_lowestGVal.mul(2 ** i).mul(_growRatio ** i).div(10 ** i));
        }
    }
    //设置saleNumber，重置抽奖盲盒
    function setSaleNumber(uint32[] calldata _saleNumber) external override onlyManagers {
        require(_saleNumber.length == 10, "saleNumber length must ten");
        saleNumber = _saleNumber;
        saleNumLeft = _saleNumber;
        blindBoxLeft = uint256(blindBoxTotal());
    }
    //设置盲盒编号权重
    function setSerialNumWeight(uint32[] calldata _serialNumWeight) external override onlyManagers {
        require(_serialNumWeight.length > 1 && _serialNumWeight.length.mod(2) == 0, "Integer must multiples of 2");
        serialNumWeightList = _serialNumWeight;
        serialNumWeightSum = 0;
        for (uint i = 1; i < serialNumWeightList.length; i += 2) {
            serialNumWeightSum += serialNumWeightList[i];
        }
    }
    //设置分红点
    function setAllocateRate(uint256[] calldata _allocateRate) external override onlyManagers {
        //feeTo地址
        allocateRate = _allocateRate;
    }
    //获取订单
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
    //获取每种等级盒子的数量
    function getSaleNumber() external view override returns (uint32[] memory){
        return saleNumber;
    }
    //获取每种等级盒子的剩余数量
    function getSaleNumLeft() external view override returns (uint32[] memory){
        return saleNumLeft;
    }
    //获取活动详情
    function getActivity() external view override returns (Activity memory) {
        return activity;
    }
    //获取盲盒剩余数量 blindBoxLeft
    function getBlindBoxLeft() external view override returns (uint256) {
        return blindBoxLeft;
    }
    //最低等级的平均成长值
    function getLowestGVal() external view override returns (uint256) {
        return lowestGVal;
    }
    //成长率
    function getGrowRatio() external view override returns (uint256) {
        return growRatio;
    }
    //不同等级的平均成长值集合
    function getLevelGVals() external view override returns (uint256[] memory) {
        return levelGVals;
    }
    //盲盒售价
    function getBlindBoxPrice() external view override returns (Price memory) {
        return blindBoxPrice;
    }
    //HUSD地址、USDT地址、PET代币地址、NFT_PET、盲盒收入地址、NFT分红地址
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
    //获取分红比例
    function getAllocateRate() external view override returns (uint256[] memory) {
        return allocateRate;
    }
    //获取编号权重
    function getSerialNumWeight() external view override returns (uint32[] memory,uint32) {
        return (serialNumWeightList,serialNumWeightSum);
    }
    //商店聚合方法
    function aggregateShop() external view override returns (uint32, uint32, uint32[] memory, uint32[] memory, Activity memory, Price memory){
        uint32 bTotal = blindBoxTotal();
        return (bTotal, uint32(blindBoxLeft), saleNumber, saleNumLeft, activity, blindBoxPrice);
    }
}
