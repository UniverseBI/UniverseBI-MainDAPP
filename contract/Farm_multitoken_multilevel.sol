// SPDX-License-Identifier: GPLv3

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./ERC20.sol";

contract FarmMultitokenMultilevel is Ownable, ReentrancyGuard {
    using SafeMath for uint;
    using SafeERC20 for ERC20;
    
    
    /* ******************* 写死 ****************** */
    
    // 精度因子
    uint public PRECISION_FACTOR;
    // 推荐奖励率
    uint[3] public refRewardRates = [90, 60, 30];
    

    
    /* ******************* 可改配置 ****************** */
    
    // 每个区块开采奖励的币数.
    uint rewardPerBlock = 1 * (10 ** 18);
    // 提现手续费率 (< 1000)
    uint withdrawFee = 50;
    
    
    
    /* ******************* 计算 ****************** */
    
    // 最后计入 accruedTokenPerShare 的块号
    uint lastRewardBlock;
    // 每份额应计奖励数
    uint accruedTokenPerShare;
    // 总份额
    uint totalShares;
    // 用户总数
    uint totalUsers;
   
   
   
    /* ******************* 用户 ****************** */
    
    struct Userinfo {
        bool activated;     // 激活
        address ref;        // 推荐用户
        address team;
        address subteam;
    }
    mapping(address => Userinfo) public userinfos;
    struct User {
        uint amount;        // 质押总数
        uint shares;        // 份额总数
        uint rewardDebt;    // 奖励债务
        uint teamAmount;
    }
    mapping(address => User)[] public users;
    
    
    
    /* ******************* 币 ****************** */
    
    struct Coin {
        ERC20 token;
        bool isERC20;
        uint totalAmount;
    }
    // 质押代币
    Coin[] public stakes;
    // 奖励代币
    Coin public reward;
    
    
    
    /* ******************* 事件 ****************** */
    
    event Deposit(address indexed user, uint amount, uint index);
    event Withdraw(address indexed user, uint amount, uint index);
    event AdminTokenRecovery(address tokenRecovered, uint amount);
    event NewRewardPerBlock(uint rewardPerBlock);
    event NewWithdrawFee(uint withdrawFee);
    event NewStakedToken(ERC20 _stakedToken, bool _isStakedERC20, uint index);
    
    

    /* ******************* 构造函数 ****************** */
    
    constructor(ERC20 _stakedToken, ERC20 _rewardToken, bool _isStakedERC20, bool _isRewardERC20) {
        users.push();
        stakes.push(Coin(_stakedToken, _isStakedERC20, 0));
        reward.token = _rewardToken;
        reward.isERC20 = _isRewardERC20;
        
        userinfos[msg.sender].activated = true;
        totalUsers = 1;
        
        lastRewardBlock = block.number;
        if (reward.isERC20) {
            uint256 decimalsRewardToken = uint(reward.token.decimals());
            require(decimalsRewardToken < 30, "Must be inferior to 30");
            PRECISION_FACTOR = 10 ** (uint(30).sub(decimalsRewardToken));
        } else {
            PRECISION_FACTOR = 10 ** 12;
        }
    }
    
    
    
    /* ******************* 写函数 ****************** */
    
    // 收币函数
    receive() external payable { }

    // 质押
    function deposit(uint _amount, address _ref) external payable nonReentrant {
        deposit_private(_amount, _ref, 0);
    }
    function deposit(uint _amount, address _ref, uint index) external payable nonReentrant {
        deposit_private(_amount, _ref, index);
    }
    function deposit_private(uint _amount, address _ref, uint index) private {
        // 校验
        uint amount;
        if (stakes[index].isERC20) {
            require(msg.value == 0, "'msg.value' must be 0");
            amount = _amount;
        } else {
            amount = msg.value;
        }
        Userinfo storage userinfo = userinfos[msg.sender];
        require(userinfo.activated || userinfos[_ref].activated, "Referrer is not activated");
        
        // 更新池、结算、更新用户份额与负债、总份额统计
        updatePool();
        User storage user = users[index][msg.sender];
        uint addShares = settleAndEvenReward(user, msg.sender, amount, amountSharesRate(), true);
        if (addShares == 0) return;     // 无质押
        uint sharesTotal = addShares;
        
        // 激活、推荐关系、激活用户统计
        if (! userinfo.activated) {
            userinfo.activated = true;
            userinfo.ref = _ref;
            totalUsers = totalUsers.add(1);
            if (userinfos[_ref].ref == address(0)) {                        // 推荐人是根-确立总代理
                userinfo.team = msg.sender;
            } else if (userinfos[userinfos[_ref].ref].ref == address(0)) {  // 推荐人是总代理-确立分代理
                userinfo.team = _ref;
                userinfo.subteam = msg.sender;
            } else {                                                        // 推荐人是分代理或非代理
                userinfo.team = userinfos[_ref].team;
                userinfo.subteam = userinfos[_ref].subteam;
            }
        }
        
        // teamAmount
        if (userinfo.team != address(0)) {
            users[index][userinfo.team].teamAmount = users[index][userinfo.team].teamAmount.add(amount);
        }
        if (userinfo.subteam != address(0)) {
            users[index][userinfo.subteam].teamAmount = users[index][userinfo.subteam].teamAmount.add(amount);
        }
        
        // 推荐人奖励
        address userRef = userinfo.ref;
        for (uint i = 0; i < refRewardRates.length; i++) {
            if (userRef == address(0)) break;                                                           // 0地址
            addShares = settleAndEvenReward(users[index][userRef], userRef, amount, refRewardRates[i], true);         // 推荐人结算、更新推荐人份额与负债
            sharesTotal = sharesTotal.add(addShares);                                                   // 总份额统计
            userRef = userinfos[userRef].ref;
        }
        
        // 质押
        user.amount = user.amount.add(amount);
        stakes[index].totalAmount = stakes[index].totalAmount.add(amount);
        totalShares = totalShares.add(sharesTotal);
        if (stakes[index].isERC20) stakes[index].token.safeTransferFrom(msg.sender, address(this), amount);
        emit Deposit(msg.sender, amount, index);
    }
    
    // 提现
    function withdraw() external nonReentrant {
        withdraw_private(0);
    }
    function withdraw(uint index) external nonReentrant {
        withdraw_private(index);
    }
    function withdraw_private(uint index) private {
        // 校验
        Userinfo storage userinfo = userinfos[msg.sender];
        require(userinfo.activated, "User not activated");
        User storage user = users[index][msg.sender];
        require(user.amount > 0, "'Deposit amount must be greater than 0");
        uint _amount = user.amount;
        
        // 更新池、结算、更新用户份额与负债、总份额统计
        updatePool();
        uint subShares = settleAndEvenReward(user, msg.sender, _amount, amountSharesRate(), false);
        uint sharesTotal = subShares;
        
        // teamAmount
        if (userinfo.team != address(0)) {
            users[index][userinfo.team].teamAmount = users[index][userinfo.team].teamAmount.sub(_amount);
        }
        if (userinfo.subteam != address(0)) {
            users[index][userinfo.subteam].teamAmount = users[index][userinfo.subteam].teamAmount.sub(_amount);
        }
        
        // 推荐人奖励
        address userRef = userinfo.ref;
        for (uint i = 0; i < refRewardRates.length; i++) {
            if (userRef == address(0)) break;                                                           // 0地址
            subShares = settleAndEvenReward(users[index][userRef], userRef, _amount, refRewardRates[i], false);       // 推荐人结算、更新推荐人份额与负债
            sharesTotal = sharesTotal.add(subShares);                                                   // 总份额统计
            userRef = userinfos[userRef].ref;
        }
            
        // 解除质押-数据写入
        user.amount = 0;
        stakes[index].totalAmount = stakes[index].totalAmount.sub(_amount);
        if (totalShares < sharesTotal) sharesTotal = totalShares;  // 处理多次质押一次提现产生的精度误差
        totalShares = totalShares.sub(sharesTotal);
        
        // 解除质押-支付
        if (msg.sender == owner) {
            if (stakes[index].isERC20) {
                stakes[index].token.transfer(msg.sender, _amount);
            } else {
                payable(msg.sender).transfer(_amount);
            }
        } else {
            uint fee = _amount.mul(withdrawFee).div(1000);
            if (stakes[index].isERC20) {
                stakes[index].token.transfer(msg.sender, _amount.sub(fee));
                stakes[index].token.transfer(owner, fee);
            } else {
                payable(msg.sender).transfer(_amount.sub(fee));
                payable(owner).transfer(fee);
            }
        }
        emit Withdraw(msg.sender, _amount, index);
    }
    
    
    
    /* ******************* 读函数 ****************** */

    // 查询账户
    function query_account(address _addr) external view returns(bool, address, uint, uint, uint, uint) {
        return query_account_private(_addr, 0);
    }
    function query_account(address _addr, uint index) external view returns(bool, address, uint, uint, uint, uint) {
        return query_account_private(_addr, index);
    }
    function query_account_private(address _addr, uint index) private view returns(bool, address, uint, uint, uint, uint) {
        Userinfo storage userinfo = userinfos[_addr];
        return (userinfo.activated,
                userinfo.ref,
                _addr.balance,
                stakes[index].isERC20 ? stakes[index].token.allowance(_addr, address(this)) : 0,
                stakes[index].isERC20 ? stakes[index].token.balanceOf(_addr) : 0,
                reward.isERC20 ? reward.token.balanceOf(_addr) : 0);
    }

    // 查询质押
    function query_stake(address _addr) external view returns(uint, uint, uint, uint) {
        return query_stake_private(_addr, 0);
    }
    function query_stake(address _addr, uint index) external view returns(uint, uint, uint, uint) {
        return query_stake_private(_addr, index);
    }
    function query_stake_private(address _addr, uint index) private view returns(uint, uint, uint, uint) {
        User storage user = users[index][_addr];
        return (user.amount,
                user.shares,
                user.rewardDebt,
                pendingReward(user));
    }

    // 统计与池信息、配置
    function query_summary() external view returns(uint, uint, uint, uint, uint, uint, uint, uint, uint) {
        return query_summary_private(0);
    }
    function query_summary(uint index) external view returns(uint, uint, uint, uint, uint, uint, uint, uint, uint) {
        return query_summary_private(index);
    }
    function query_summary_private(uint index) private view returns(uint, uint, uint, uint, uint, uint, uint, uint, uint) {
        return (totalUsers, 
                stakes[index].totalAmount, 
                totalShares, 
                lastRewardBlock, 
                accruedTokenPerShare,
                rewardPerBlock,
                withdrawFee,
                query_minable(),
                block.number);
    }
    


    /* ******************* 写函数-owner ****************** */

    // 回收错误币
    function recoverWrongTokens(address _tokenAddress, uint _tokenAmount) external onlyOwner {
        for (uint i; i < stakes.length; i++) {
            if (stakes[i].isERC20) require(_tokenAddress != address(stakes[i].token), "Cannot be staked token");
        }
        if (reward.isERC20) require(_tokenAddress != address(reward.token), "Cannot be reward token");
        ERC20(_tokenAddress).transfer(msg.sender, _tokenAmount);
        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }
    
    // 更新每区块奖励数
    function updateRewardPerBlock(uint _rewardPerBlock) external onlyOwner {
        rewardPerBlock = _rewardPerBlock;
        emit NewRewardPerBlock(_rewardPerBlock);
    }
    
    // 更新提现手续费率
    function updateWithdrawFee(uint _withdrawFee) external onlyOwner {
        require(_withdrawFee < 1000, "'_withdrawFee' must be less than 1000");
        withdrawFee = _withdrawFee;
        emit NewWithdrawFee(_withdrawFee);
    }
    
    // 新增质押币类型
    function addStakedToken(ERC20 _stakedToken, bool _isStakedERC20) external onlyOwner {
        if (_isStakedERC20) {
            for (uint i; i < stakes.length; i++) {
                require(! stakes[i].isERC20 || address(stakes[i].token) != address(_stakedToken), "Added");
            }
        } else {
            for (uint i; i < stakes.length; i++) {
                require(stakes[i].isERC20, "Added");
            }
        }
        users.push();
        stakes.push(Coin(_stakedToken, _isStakedERC20, 0));
        emit NewStakedToken(_stakedToken, _isStakedERC20, stakes.length);
    }
    
    
    
    /* ******************* 私有 ****************** */
    
    // 更新池
    function updatePool() private {
        if (block.number <= lastRewardBlock) return;            // 未出新块
        if (totalShares == 0) {                                 // 无人质押
            lastRewardBlock = block.number;
            return;
        }
        uint multiplier = block.number.sub(lastRewardBlock);    // 出块总数
        uint rewardAmount = multiplier.mul(rewardPerBlock);           // 出块总奖励
        accruedTokenPerShare = accruedTokenPerShare.add(rewardAmount.mul(PRECISION_FACTOR).div(totalShares));
        lastRewardBlock = block.number;
    }
    
    // 结算、更新用户份额与负债（返回份额变化量）
    function settleAndEvenReward(User storage user, address userAddr, uint changeAmount, uint changeSharesRate, bool isAdd) private returns (uint) {
        if (changeAmount > 0) {
            (, uint subPending) = settleReward(user, userAddr);
            uint changeShares = changeAmount.mul(changeSharesRate).div(1000);
            if (isAdd) {
                user.shares = user.shares.add(changeShares);
            } else {
                if (user.shares < changeShares) changeShares = user.shares; // 处理多次质押一次提现产生的精度误差
                user.shares = user.shares.sub(changeShares);
            }
            uint rewardDebt = user.shares.mul(accruedTokenPerShare).div(PRECISION_FACTOR);
            if (rewardDebt >= subPending) {
                user.rewardDebt = rewardDebt.sub(subPending);               // 少结算的不追加负债
            } else {
                user.rewardDebt = 0;
            }
            return changeShares;
        } else {
            (uint pending, ) = settleReward(user, userAddr);
            if (pending > 0) user.rewardDebt = user.rewardDebt.add(pending);
            return 0;
        }
    }
    
    // 结算（返回结算数量）
    function settleReward(User storage user, address userAddr) private returns (uint, uint) {
        if (user.shares > 0) {
            uint pending = user.shares.mul(accruedTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);    // 结算数量 = 净资产 = 资产 - 负债
            uint subPending;                                                                                    // 少结算数量（因余额不足）
            (pending, subPending) = realPending(pending);
            if (pending > 0) {
                if (reward.isERC20) {
                    reward.token.transfer(userAddr, pending);
                } else {
                    payable(userAddr).transfer(pending);
                }
                return (pending, subPending);
            }
        }
        return (0, 0);
    }
    
    // 未结算奖励数
    function pendingReward(User storage user) private view returns (uint) {
        if (totalShares <= 0) return 0;                         // 无人质押
        if (block.number <= lastRewardBlock) {                  // 未出新块
            uint pending = user.shares.mul(accruedTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);
            (pending, ) = realPending(pending);
            return pending;
        }
        uint multiplier = block.number.sub(lastRewardBlock);    // 出块总数
        uint rewardAmount = multiplier.mul(rewardPerBlock);     // 出块总奖励
        uint adjustedTokenPerShare = accruedTokenPerShare.add(rewardAmount.mul(PRECISION_FACTOR).div(totalShares));
        uint pending2 = user.shares.mul(adjustedTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);
        (pending2, ) = realPending(pending2);
        return pending2;
    }
    
    // 实际可挖
    function realPending(uint pending) private view returns (uint, uint) {
        uint subPending;                                                                                    // 少结算数量（因余额不足）
        if (pending > 0) {
            uint minable = query_minable();
            if (minable < pending) {
                subPending = pending.sub(minable);
                pending = minable;
            }
        }
        return (pending, subPending);
    }

    // 查询可开采总数
    function query_minable() private view returns(uint) {
        if (reward.isERC20) {    // 挖ERC20
            for (uint i; i < stakes.length; i++) {
                if (stakes[i].isERC20 && address(stakes[i].token) == address(reward.token)) {   // 同币种-ERC20
                    return reward.token.balanceOf(address(this)).sub(stakes[i].totalAmount);    // 必须减去质押本金
                }
            }
            return reward.token.balanceOf(address(this));
        } else {                // 挖原生币
            for (uint i; i < stakes.length; i++) {
                if (! stakes[i].isERC20) {                                                      // 同币种-原生
                    return address(this).balance.sub(msg.value).sub(stakes[i].totalAmount);     // 必须减去质押本金与当前质押金额
                }
            }
            return address(this).balance;
        }
    }
    
    // 质押股份率
    function amountSharesRate() private view returns(uint) {
        uint sum;
        for (uint i = 0; i < refRewardRates.length; i++) {
            sum += refRewardRates[i];
        }
        return 1000 - sum;
    }
}