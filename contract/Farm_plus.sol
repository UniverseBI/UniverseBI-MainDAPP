// SPDX-License-Identifier: GPLv3

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./ERC20.sol";

contract FarmPlus is Ownable, ReentrancyGuard {
    using SafeMath for uint;
    using SafeERC20 for ERC20;
    
    
    /* ******************* 写死 ****************** */
    
    // 精度因子
    uint public PRECISION_FACTOR;
    // 推荐奖励率
    uint public refRewardRate;
    // 辅助代币算力系数 *（10 ** 10）
    uint public powerPlusRate;
    // 质押代币
    ERC20 public stakedToken;
    // 奖励代币
    ERC20 public rewardToken;
    // 辅助代币
    ERC20 public powerPlusToken;
    // 质押币是否为ERC20币
    bool public isStakedERC20;
    // 奖励币是否为ERC20币
    bool public isRewardERC20;
    

    
    /* ******************* 可改配置 ****************** */
    
    // 每个区块开采奖励的币数.
    uint rewardPerBlock = 1 * (10 ** 18);
    // 每用户质押限额（0-无限额）
    uint poolLimitPerUser;
    // 每用户辅助币质押限额（0-无限额）
    uint plusLimitPerUser;
    
    
    
    /* ******************* 计算 ****************** */
    
    // 最后计入 accruedTokenPerShare 的块号
    uint lastRewardBlock;
    // 每份额应计奖励数
    uint accruedTokenPerShare;
    // 总份额
    uint totalShares;
    // 质押代币总数
    uint totalAmount;
    // 质押辅助代币总数
    uint totalPlusTokenAmount;
    // 激活用户总数
    uint totalUsers;
   
   
   
    /* ******************* 用户 ****************** */
    
    struct User {
        bool activated;         // 激活
        address ref;            // 推荐用户
        uint amount;            // 质押总数
        uint refAmount;         // 推荐用户质押总数
        uint powerPlusAmount;   // 辅助币质押总数
        uint refPowerPlusAmount;// 推荐用户辅助币质押总数
        uint rewardDebt;        // 奖励债务
    }
    mapping(address => User) public users;
    
    
    
    /* ******************* 事件 ****************** */
    
    event Deposit(address indexed user, uint amount, bool _isPlus);
    event Withdraw(address indexed user, uint amount, bool _isPlus);
    event AdminTokenRecovery(address tokenRecovered, uint amount);
    event NewPoolLimit(uint poolLimitPerUser);
    event NewPlusLimit(uint plusLimitPerUser);
    event NewRewardPerBlock(uint rewardPerBlock);
    
    

    /* ******************* 构造函数 ****************** */
    
    constructor(ERC20 _stakedToken, ERC20 _rewardToken, ERC20 _powerPlusToken, bool _isStakedERC20, bool _isRewardERC20, uint _refRewardRate, uint _powerPlusRate) {
        require(_refRewardRate <= 500, "'_refRewardRate' cannot be greater than 500");
        stakedToken = _stakedToken;
        rewardToken = _rewardToken;
        powerPlusToken = _powerPlusToken;
        isStakedERC20 = _isStakedERC20;
        isRewardERC20 = _isRewardERC20;
        refRewardRate = _refRewardRate;
        powerPlusRate = _powerPlusRate;
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
    function deposit(uint _amount, address _ref, bool _isPlus) external payable nonReentrant {
        // 校验
        uint amount;
        if (isStakedERC20 || _isPlus) {
            require(msg.value == 0, "'msg.value' must be 0");
            amount = _amount;
        } else {
            amount = msg.value;
        }
        User storage user = users[msg.sender];
        require(user.activated || users[_ref].activated, "Referrer is not activated");
        if (_isPlus) {
            require(amount == 0 || plusLimitPerUser == 0 || amount.add(user.powerPlusAmount) <= plusLimitPerUser, "User deposit amount above limit");
        } else {
            require(amount == 0 || poolLimitPerUser == 0 || amount.add(user.amount) <= poolLimitPerUser, "User deposit amount above limit");
        }
        
        // 更新奖池，结算，更新质押数、质押总数、总份额、负债
        updatePool();
        settleAndUpdate(user, msg.sender, amount, true, false, _isPlus);
        if (amount == 0) return;     // 无质押
        
        // 推荐人结算，更新推荐质押数、总份额、负债
        if (user.ref != address(0)) {
            settleAndUpdate(users[user.ref], user.ref, amount, true, true, _isPlus);
        }
        
        // 激活、推荐关系、激活用户统计
        if (! user.activated) {
            user.activated = true;
            user.ref = _ref;
            totalUsers = totalUsers.add(1);
        }
        
        // 转账
        if (_isPlus) {
            powerPlusToken.safeTransferFrom(msg.sender, address(this), amount);
        } else if (isStakedERC20) {
            stakedToken.safeTransferFrom(msg.sender, address(this), amount);
        }
        emit Deposit(msg.sender, amount, _isPlus);
    }
    
    // 提现
    function withdraw(bool _isPlus) external nonReentrant {
        // 校验
        User storage user = users[msg.sender];
        require(user.activated, "User not activated");
        uint _amount;
        if (_isPlus) {
            require(user.powerPlusAmount > 0, "'Deposit amount must be greater than 0");
            _amount = user.powerPlusAmount;
        } else {
            require(user.amount > 0, "'Deposit amount must be greater than 0");
            _amount = user.amount;
        }
        
        // 更新奖池，结算，更新质押数、质押总数、总份额、负债
        updatePool();
        settleAndUpdate(user, msg.sender, _amount, false, false, _isPlus);
        
        // 推荐人结算，更新推荐质押数、总份额、负债
        if (user.ref != address(0)) {
            settleAndUpdate(users[user.ref], user.ref, _amount, false, true, _isPlus);
        }
            
        // 解除质押-支付
        if (msg.sender == owner) {
            if  (_isPlus) {
                powerPlusToken.transfer(msg.sender, _amount);
            } else if (isStakedERC20) {
                stakedToken.transfer(msg.sender, _amount);
            } else {
                payable(msg.sender).transfer(_amount);
            }
        } else {
            uint fee = _amount.mul(refRewardRate).div(1000);
            if (_isPlus) {
                powerPlusToken.transfer(msg.sender, _amount.sub(fee));
                powerPlusToken.transfer(owner, fee);
            } else if (isStakedERC20) {
                stakedToken.transfer(msg.sender, _amount.sub(fee));
                stakedToken.transfer(owner, fee);
            } else {
                payable(msg.sender).transfer(_amount.sub(fee));
                payable(owner).transfer(fee);
            }
        }
        emit Withdraw(msg.sender, _amount, _isPlus);
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
    
    // 查询辅助币
    function query_plus(address _addr) external view returns(uint, uint) {
        return (powerPlusToken.allowance(_addr, address(this)),
                powerPlusToken.balanceOf(_addr));
    }

    // 查询质押
    function query_stake(address _addr) external view returns(uint, uint, uint, uint, uint, uint) {
        uint pending;                                                   // 未结算奖励数
        User storage user = users[_addr];
        if (totalShares > 0) {
            uint share = calcShare(user);
            if (block.number <= lastRewardBlock) {                      // 未出新块
                (pending,) = calcPending(user, share, accruedTokenPerShare);
            } else {
                uint multiplier = block.number.sub(lastRewardBlock);    // 出块总数
                uint reward = multiplier.mul(rewardPerBlock);           // 出块总奖励
                uint adjustedTokenPerShare = accruedTokenPerShare.add(reward.mul(PRECISION_FACTOR).div(totalShares));
                (pending,) = calcPending(user, share, adjustedTokenPerShare);
            }
        }
        return (user.amount,
                user.refAmount,
                user.rewardDebt,
                pending,
                user.powerPlusAmount,
                user.refPowerPlusAmount);
    }

    // 统计与池信息、配置
    function query_summary() external view returns(uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint) {
        return (totalUsers, 
                totalAmount, 
                totalPlusTokenAmount,
                totalShares,
                lastRewardBlock, 
                accruedTokenPerShare,
                rewardPerBlock,
                poolLimitPerUser,
                plusLimitPerUser,
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
    
    // 更新每用户质押限额
    function updatePoolLimitPerUser(uint _poolLimitPerUser) external onlyOwner {
        poolLimitPerUser = _poolLimitPerUser;
        emit NewPoolLimit(_poolLimitPerUser);
    }
    
    // 更新每用户辅助币质押限额
    function updatePlusLimitPerUser(uint _plusLimitPerUser) external onlyOwner {
        plusLimitPerUser = _plusLimitPerUser;
        emit NewPlusLimit(_plusLimitPerUser);
    }

    // 更新每区块奖励数
    function updateRewardPerBlock(uint _rewardPerBlock) external onlyOwner {
        rewardPerBlock = _rewardPerBlock;
        emit NewRewardPerBlock(_rewardPerBlock);
    }
    
    
    
    /* ******************* 私有 ****************** */
    
    // 结算，更新质押数、质押总数、总份额、负债
    function settleAndUpdate(User storage user, address userAddr, uint changeAmount, bool isAdd, bool isRef, bool isPlus) private {
        // 结算
        uint pending;
        uint subPending;
        uint share = calcShare(user);           // 用户总份额
        if (share > 0) {
            (pending, subPending) = calcPending(user, share, accruedTokenPerShare);
            if (pending > 0) {
                if (isRewardERC20) {
                    rewardToken.transfer(userAddr, pending);
                } else {
                    payable(userAddr).transfer(pending);
                }
            }
        }
        
        // 更新质押数、质押总数、总份额、负债
        if (changeAmount > 0) {                 // 质押数变化，负债重算
            // 更新质押数
            if (isPlus) {
                if (isRef) {
                    user.refPowerPlusAmount = isAdd ? user.refPowerPlusAmount.add(changeAmount) : user.refPowerPlusAmount.sub(changeAmount);
                } else {
                    user.powerPlusAmount = isAdd ? user.powerPlusAmount.add(changeAmount) : user.powerPlusAmount.sub(changeAmount);
                }
            } else {
                if (isRef) {
                    user.refAmount = isAdd ? user.refAmount.add(changeAmount) : user.refAmount.sub(changeAmount);
                } else {
                    user.amount = isAdd ? user.amount.add(changeAmount) : user.amount.sub(changeAmount);
                }
            }
            
            // 更新质押总数（只加减一次）
            if (! isRef) {
                if (isPlus) {
                    totalPlusTokenAmount = isAdd ? totalPlusTokenAmount.add(changeAmount) : totalPlusTokenAmount.sub(changeAmount);
                } else {
                    totalAmount = isAdd ? totalAmount.add(changeAmount) : totalAmount.sub(changeAmount);
                }
            }
            
            // 更新总份额（每次都加减）
            uint newShare = calcShare(user);    // 新用户总份额
            if (isAdd) {
                totalShares = totalShares.add(newShare.sub(share));
            } else {
                uint subShare = share.sub(newShare);
                totalShares = totalShares < subShare ? 0 : totalShares.sub(subShare);           // 处理多次质押一次提现产生的精度误差
            }
            
            // 更新负债
            uint newRewardDebt = calcRewardDebt(newShare, accruedTokenPerShare);
            user.rewardDebt = newRewardDebt >= subPending ? newRewardDebt.sub(subPending) : 0;  // 欠结算数量必须扣掉
        } else {                                // 质押数未变，奖励计入负债
            if (pending > 0) user.rewardDebt = user.rewardDebt.add(pending);
        }
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
            uint minable;
            if (isStakedERC20 && address(stakedToken) == address(rewardToken)) {    // 同币种-ERC20
                minable = rewardToken.balanceOf(address(this)).sub(totalAmount);    // 必须减去质押本金
            } else {
                minable = rewardToken.balanceOf(address(this));
            }
            return address(rewardToken) == address(powerPlusToken) ? minable.sub(totalPlusTokenAmount) : minable;
        } else {                // 挖原生币
            if (isStakedERC20) {
                return address(this).balance;
            } else {                                                                // 同币种-原生
                return address(this).balance.sub(msg.value).sub(totalAmount);
            }
        }
    }
    
    // 计算份额
    function calcShare(User storage user) private view returns (uint) {
        uint amountShareRate = uint(1000).sub(refRewardRate);                                   // 质押金额应计份额数（1000倍）
        
        uint amountShare = user.amount.mul(amountShareRate).div(1000);                          // 质押份额 = 质押数 * 0.95
        uint refAmountShare = user.refAmount.mul(refRewardRate).div(1000);                      // 推荐份额 = 推荐质押数 * 0.05
        uint baseShare = amountShare.add(refAmountShare);                                       // 基础份额
        
        uint plusAmountShare = user.powerPlusAmount.mul(amountShareRate).div(1000);             // 辅助币质押份额 = 辅助币质押数 * 0.95
        uint refPlusAmountShare = user.refPowerPlusAmount.mul(refRewardRate).div(1000);         // 辅助币推荐份额 = 辅助币推荐质押数 * 0.05
        uint basePlusShare = plusAmountShare.add(refPlusAmountShare);                           // 辅助币基础份额（10 ** 18倍）
        
        uint powerPlusShare = basePlusShare.mul(powerPlusRate).mul(baseShare).div(10 ** 28);    // 加成份额 = 辅助币基础份额 * 系数（10 ** 10倍） * 基础份额
        return baseShare.add(powerPlusShare);                                                   // 总份额 = 基础份额 + 加成份额
    }
    
    // 计算负债
    function calcRewardDebt(uint share, uint adjustedTokenPerShare) private view returns (uint) {
        return share.mul(adjustedTokenPerShare).div(PRECISION_FACTOR);
    }
    
    // 计算未结算奖励数
    function calcPending(User storage user, uint share, uint adjustedTokenPerShare) private view returns (uint, uint) {
        uint newRewardDebt = calcRewardDebt(share, adjustedTokenPerShare);
        uint pending = newRewardDebt.sub(user.rewardDebt);
        uint minable = query_minable();
        if (minable < pending) {
            return (minable, pending.sub(minable));
        } else {
            return (pending, 0);
        }
    }

}