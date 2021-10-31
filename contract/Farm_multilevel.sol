// SPDX-License-Identifier: GPLv3

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./ERC20.sol";

contract FarmMultilevel is Ownable, ReentrancyGuard {
    using SafeMath for uint;
    using SafeERC20 for ERC20;
    
    
    /* ******************* 写死 ****************** */
    
    // 精度因子
    uint public PRECISION_FACTOR;
    // 推荐奖励率
    uint[3] public refRewardRates = [70, 20, 10];
    // 质押代币
    ERC20 public stakedToken;
    // 奖励代币
    ERC20 public rewardToken;
    // 质押币是否为ERC20币
    bool public isStakedERC20;
    // 奖励币是否为ERC20币
    bool public isRewardERC20;
    

    
    /* ******************* 可改配置 ****************** */
    
    // 每个区块开采奖励的币数.
    uint rewardPerBlock = 1 * (10 ** 18);
    
    
    
    /* ******************* 计算 ****************** */
    
    // 最后计入 accruedTokenPerShare 的块号
    uint lastRewardBlock;
    // 每份额应计奖励数
    uint accruedTokenPerShare;
    // 总份额
    uint totalShares;
    // 质押代币总数
    uint totalAmount;
    // 激活用户总数
    uint totalUsers;
   
   
   
    /* ******************* 用户 ****************** */
    
    struct User {
        bool activated;     // 激活
        address ref;        // 推荐用户
        uint amount;        // 质押总数
        uint shares;        // 份额总数
        uint rewardDebt;    // 奖励债务
    }
    mapping(address => User) public users;
    
    
    
    /* ******************* 事件 ****************** */
    
    event Deposit(address indexed user, uint amount);
    event Withdraw(address indexed user, uint amount);
    event AdminTokenRecovery(address tokenRecovered, uint amount);
    event NewRewardPerBlock(uint rewardPerBlock);
    
    

    /* ******************* 构造函数 ****************** */
    
    constructor(ERC20 _stakedToken, ERC20 _rewardToken, bool _isStakedERC20, bool _isRewardERC20) {
        stakedToken = _stakedToken;
        rewardToken = _rewardToken;
        isStakedERC20 = _isStakedERC20;
        isRewardERC20 = _isRewardERC20;
        lastRewardBlock = block.number;
        users[msg.sender].activated = true;
        totalUsers = 1;
        if (isRewardERC20) {
            uint256 decimalsRewardToken = uint(rewardToken.decimals());
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
        // 校验
        uint amount;
        if (isStakedERC20) {
            require(msg.value == 0, "'msg.value' must be 0");
            amount = _amount;
        } else {
            amount = msg.value;
        }
        User storage user = users[msg.sender];
        require(user.activated || users[_ref].activated, "Referrer is not activated");
        
        // 更新池、结算、更新用户份额与负债、总份额统计
        updatePool();
        uint addShares = settleAndEvenReward(user, msg.sender, amount, amountSharesRate(), true);
        if (addShares == 0) return;     // 无质押
        uint sharesTotal = addShares;
        
        // 激活、推荐关系、激活用户统计
        if (! user.activated) {
            user.activated = true;
            user.ref = _ref;
            totalUsers = totalUsers.add(1);
        }
        
        // 推荐人奖励
        address userRef = user.ref;
        for (uint i = 0; i < refRewardRates.length; i++) {
            if (userRef == address(0)) break;                                                           // 0地址
            User storage refUser = users[userRef];
            addShares = settleAndEvenReward(refUser, userRef, amount, refRewardRates[i], true);         // 推荐人结算、更新推荐人份额与负债
            sharesTotal = sharesTotal.add(addShares);                                                   // 总份额统计
            userRef = refUser.ref;
        }
        
        // 质押
        user.amount = user.amount.add(amount);
        totalAmount = totalAmount.add(amount);
        totalShares = totalShares.add(sharesTotal);
        if (isStakedERC20) stakedToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Deposit(msg.sender, amount);
    }
    
    // 提现
    function withdraw() external nonReentrant {
        // 校验
        User storage user = users[msg.sender];
        require(user.activated, "User not activated");
        require(user.amount > 0, "'Deposit amount must be greater than 0");
        uint _amount = user.amount;
        
        // 更新池、结算、更新用户份额与负债、总份额统计
        updatePool();
        uint subShares = settleAndEvenReward(user, msg.sender, _amount, amountSharesRate(), false);
        uint sharesTotal = subShares;
        
        // 推荐人奖励
        address userRef = user.ref;
        for (uint i = 0; i < refRewardRates.length; i++) {
            if (userRef == address(0)) break;                                                           // 0地址
            User storage refUser = users[userRef];
            subShares = settleAndEvenReward(refUser, userRef, _amount, refRewardRates[i], false);       // 推荐人结算、更新推荐人份额与负债
            sharesTotal = sharesTotal.add(subShares);                                                   // 总份额统计
            userRef = refUser.ref;
        }
            
        // 解除质押-数据写入
        user.amount = 0;
        totalAmount = totalAmount.sub(_amount);
        if (totalShares < sharesTotal) sharesTotal = totalShares;  // 处理多次质押一次提现产生的精度误差
        totalShares = totalShares.sub(sharesTotal);
        
        // 解除质押-支付
        if (msg.sender == owner) {
            if (isStakedERC20) {
                stakedToken.transfer(msg.sender, _amount);
            } else {
                payable(msg.sender).transfer(_amount);
            }
        } else {
            uint fee = _amount.mul(withdrawFeeRate()).div(1000);
            if (isStakedERC20) {
                stakedToken.transfer(msg.sender, _amount.sub(fee));
                stakedToken.transfer(owner, fee);
            } else {
                payable(msg.sender).transfer(_amount.sub(fee));
                payable(owner).transfer(fee);
            }
        }
        emit Withdraw(msg.sender, _amount);
    }
    
    
    
    /* ******************* 读函数 ****************** */

    // 查询账户
    function query_account(address _addr) external view returns(bool, address, uint, uint, uint, uint) {
        User storage user = users[_addr];
        return (user.activated,
                user.ref,
                _addr.balance,
                isStakedERC20 ? stakedToken.allowance(_addr, address(this)) : 0,
                isStakedERC20 ? stakedToken.balanceOf(_addr) : 0,
                isRewardERC20 ? rewardToken.balanceOf(_addr) : 0);
    }

    // 查询质押
    function query_stake(address _addr) external view returns(uint, uint, uint, uint) {
        User storage user = users[_addr];
        return (user.amount,
                user.shares,
                user.rewardDebt,
                pendingReward(user));
    }

    // 统计与池信息、配置
    function query_summary() external view returns(uint, uint, uint, uint, uint, uint, uint, uint, uint) {
        return (totalUsers, 
                totalAmount, 
                totalShares, 
                lastRewardBlock, 
                accruedTokenPerShare,
                rewardPerBlock,
                withdrawFeeRate(),
                query_minable(),
                block.number);
    }
    


    /* ******************* 写函数-owner ****************** */

    // 回收错误币
    function recoverWrongTokens(address _tokenAddress, uint _tokenAmount) external onlyOwner {
        if (isStakedERC20) require(_tokenAddress != address(stakedToken), "Cannot be staked token");
        if (isRewardERC20) require(_tokenAddress != address(rewardToken), "Cannot be reward token");
        ERC20(_tokenAddress).transfer(msg.sender, _tokenAmount);
        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }
    
    // 更新每区块奖励数
    function updateRewardPerBlock(uint _rewardPerBlock) external onlyOwner {
        rewardPerBlock = _rewardPerBlock;
        emit NewRewardPerBlock(_rewardPerBlock);
    }
    
    
    
    /* ******************* 私有 ****************** */
    
    // 结算（返回结算数量）
    function settleReward(User storage user, address userAddr) private returns (uint, uint) {
        if (user.shares > 0) {
            uint pending = user.shares.mul(accruedTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);    // 结算数量 = 净资产 = 资产 - 负债
            uint subPending;                                                                                    // 少结算数量（因余额不足）
            (pending, subPending) = realPending(pending);
            if (pending > 0) {
                if (isRewardERC20) {
                    rewardToken.transfer(userAddr, pending);
                } else {
                    payable(userAddr).transfer(pending);
                }
                return (pending, subPending);
            }
        }
        return (0, 0);
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
    
    // 未结算奖励数
    function pendingReward(User storage user) private view returns (uint) {
        if (totalShares <= 0) return 0;                         // 无人质押
        if (block.number <= lastRewardBlock) {                  // 未出新块
            uint pending = user.shares.mul(accruedTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);
            (pending, ) = realPending(pending);
            return pending;
        }
        uint multiplier = block.number.sub(lastRewardBlock);    // 出块总数
        uint reward = multiplier.mul(rewardPerBlock);           // 出块总奖励
        uint adjustedTokenPerShare = accruedTokenPerShare.add(reward.mul(PRECISION_FACTOR).div(totalShares));
        uint pending2 = user.shares.mul(adjustedTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);
        (pending2, ) = realPending(pending2);
        return pending2;
    }
    
    // 实际可挖
    function realPending(uint pending) private view returns (uint, uint) {
        uint subPending;
        if (pending > 0) {
            uint minable = query_minable();
            if (minable < pending) {
                subPending = pending.sub(minable);
                pending = minable;
            }
        }
        return (pending, subPending);
    }
    
    // 更新池
    function updatePool() private {
        if (block.number <= lastRewardBlock) return;            // 未出新块
        if (totalShares == 0) {                                 // 无人质押
            lastRewardBlock = block.number;
            return;
        }
        uint multiplier = block.number.sub(lastRewardBlock);    // 出块总数
        uint reward = multiplier.mul(rewardPerBlock);           // 出块总奖励
        accruedTokenPerShare = accruedTokenPerShare.add(reward.mul(PRECISION_FACTOR).div(totalShares));
        lastRewardBlock = block.number;
    }

    // 查询可开采总数
    function query_minable() private view returns(uint) {
        if (isRewardERC20) {    // 挖ERC20
            if (isStakedERC20 && address(stakedToken) == address(rewardToken)) {    // 同币种-ERC20
                return rewardToken.balanceOf(address(this)).sub(totalAmount);       // 必须减去质押本金
            } else {
                return rewardToken.balanceOf(address(this));
            }
        } else {                // 挖原生币
            if (isStakedERC20) {
                return address(this).balance;
            } else {                                                                // 同币种-原生
                return address(this).balance.sub(msg.value).sub(totalAmount);
            }
        }
    }
    
    // 提现手续费率
    function withdrawFeeRate() private view returns(uint) {
        uint sum;
        for (uint i = 0; i < refRewardRates.length; i++) {
            sum += refRewardRates[i];
        }
        return sum;
    }
    
    // 质押股份率
    function amountSharesRate() private view returns(uint) {
        return 1000 - withdrawFeeRate();
    }
}