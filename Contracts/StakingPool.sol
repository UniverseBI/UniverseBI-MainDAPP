// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _setOwner(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }
    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
interface ERC20 is IERC20Metadata {
}
library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor() {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
library SafeERC20 {
    using Address for address;
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
contract YieldFarm is Ownable, ReentrancyGuard {
    using SafeMath for uint;
    using SafeERC20 for ERC20;
    uint PRECISION_FACTOR;
    uint public refRewardRate;
    ERC20 public stakedToken;
    ERC20 public rewardToken;
    bool isStakedERC20;
    bool isRewardERC20;
    uint rewardPerBlock = 1 * (10 ** 18);
    uint poolLimitPerUser;
    uint lastRewardBlock;
    uint accruedTokenPerShare;
    uint totalShares;
    uint totalAmount;
    uint totalUsers;
    struct User {
        bool activated;    
        address ref;       
        uint amount;       
        uint shares;       
        uint rewardDebt;   
    }
    mapping(address => User) public users;
    event Deposit(address indexed user, uint amount);
    event Withdraw(address indexed user, uint amount);
    event AdminTokenRecovery(address tokenRecovered, uint amount);
    event NewPoolLimit(uint poolLimitPerUser);
    event NewRewardPerBlock(uint rewardPerBlock);
    constructor(ERC20 _stakedToken, ERC20 _rewardToken, bool _isStakedERC20, bool _isRewardERC20, uint _refRewardRate) {
        stakedToken = _stakedToken;
        rewardToken = _rewardToken;
        isStakedERC20 = _isStakedERC20;
        isRewardERC20 = _isRewardERC20;
        refRewardRate = _refRewardRate;
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
    receive() external payable { }
    function deposit(uint _amount, address _ref) external payable nonReentrant {
        uint amount;
        if (isStakedERC20) {
            require(msg.value == 0, "'msg.value' must be 0");
            amount = _amount;
        } else {
            amount = msg.value;
        }
        User storage user = users[msg.sender];
        require(user.activated || users[_ref].activated, "Referrer is not activated");
        if (poolLimitPerUser > 0 && amount > 0) {
            require(amount.add(user.amount) <= poolLimitPerUser, "User deposit amount above limit");
        }
        updatePool();
        uint addShares = settleAndEvenReward(user, msg.sender, amount, uint(1000).sub(refRewardRate), true);
        if (addShares == 0) return;    
        uint sharesTotal = addShares;
        if (! user.activated) {
            user.activated = true;
            user.ref = _ref;
            totalUsers = totalUsers.add(1);
        }
        if (user.ref != address(0)) {
            User storage refUser = users[user.ref];
            addShares = settleAndEvenReward(refUser, user.ref, amount, refRewardRate, true);   
            sharesTotal = sharesTotal.add(addShares);                                          
        }
        user.amount = user.amount.add(amount);
        totalAmount = totalAmount.add(amount);
        totalShares = totalShares.add(sharesTotal);
        if (isStakedERC20) stakedToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Deposit(msg.sender, amount);
    }
    function withdraw() external nonReentrant {
        User storage user = users[msg.sender];
        require(user.activated, "User not activated");
        require(user.amount > 0, "'Deposit amount must be greater than 0");
        uint _amount = user.amount;
        updatePool();
        uint subShares = settleAndEvenReward(user, msg.sender, _amount, uint(1000).sub(refRewardRate), false);
        uint sharesTotal = subShares;
        if (user.ref != address(0)) {
            User storage refUser = users[user.ref];
            subShares = settleAndEvenReward(refUser, user.ref, _amount, refRewardRate, false); 
            sharesTotal = sharesTotal.add(subShares);                                          
        }
        user.amount = 0;
        totalAmount = totalAmount.sub(_amount);
        if (totalShares < sharesTotal) sharesTotal = totalShares;     
        totalShares = totalShares.sub(sharesTotal);
        if (msg.sender == owner()) {
            if (isStakedERC20) {
                stakedToken.transfer(msg.sender, _amount);
            } else {
                payable(msg.sender).transfer(_amount);
            }
        } else {
            uint fee = _amount.mul(refRewardRate).div(1000);
            if (isStakedERC20) {
                stakedToken.transfer(msg.sender, _amount.sub(fee));
                stakedToken.transfer(owner(), fee);
            } else {
                payable(msg.sender).transfer(_amount.sub(fee));
                payable(owner()).transfer(fee);
            }
        }
        emit Withdraw(msg.sender, _amount);
    }
    function query_account(address _addr) external view returns(bool, address, uint, uint, uint, uint) {
        User storage user = users[_addr];
        return (user.activated,
                user.ref,
                _addr.balance,
                isStakedERC20 ? stakedToken.allowance(_addr, address(this)) : 0,
                isStakedERC20 ? stakedToken.balanceOf(_addr) : 0,
                isRewardERC20 ? rewardToken.balanceOf(_addr) : 0);
    }
    function query_stake(address _addr) external view returns(uint, uint, uint, uint) {
        User storage user = users[_addr];
        return (user.amount,
                user.shares,
                user.rewardDebt,
                pendingReward(user));
    }
    function query_summary() external view returns(uint, uint, uint, uint, uint, uint, uint, uint, uint) {
        return (totalUsers, 
                totalAmount, 
                totalShares, 
                lastRewardBlock, 
                accruedTokenPerShare,
                rewardPerBlock,
                poolLimitPerUser,
                query_minable(),
                block.number);
    }
    function recoverWrongTokens(address _tokenAddress, uint _tokenAmount) external onlyOwner {
        if (isStakedERC20) require(_tokenAddress != address(stakedToken), "Cannot be staked token");
        if (isRewardERC20) require(_tokenAddress != address(rewardToken), "Cannot be reward token");
        ERC20(_tokenAddress).transfer(msg.sender, _tokenAmount);
        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }
    function updatePoolLimitPerUser(uint _poolLimitPerUser) external onlyOwner {
        poolLimitPerUser = _poolLimitPerUser;
        emit NewPoolLimit(_poolLimitPerUser);
    }
    function updateRewardPerBlock(uint _rewardPerBlock) external onlyOwner {
        rewardPerBlock = _rewardPerBlock;
        emit NewRewardPerBlock(_rewardPerBlock);
    }
    function settleReward(User storage user, address userAddr) private returns (uint, uint) {
        if (user.shares > 0) {
            uint pending = user.shares.mul(accruedTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);   
            uint subPending;                                                                                   
            if (pending > 0) {
                uint minable = query_minable();
                if (minable < pending) {
                    subPending = pending.sub(minable);
                    pending = minable;
                }
            }
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
    function settleAndEvenReward(User storage user, address userAddr, uint changeAmount, uint changeSharesRate, bool isAdd) private returns (uint) {
        if (changeAmount > 0) {
            (, uint subPending) = settleReward(user, userAddr);
            uint changeShares = changeAmount.mul(changeSharesRate).div(1000);
            if (isAdd) {
                user.shares = user.shares.add(changeShares);
            } else {
                if (user.shares < changeShares) changeShares = user.shares;
                user.shares = user.shares.sub(changeShares);
            }
            uint rewardDebt = user.shares.mul(accruedTokenPerShare).div(PRECISION_FACTOR);
            if (rewardDebt >= subPending) {
                user.rewardDebt = rewardDebt.sub(subPending);              
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
    function pendingReward(User storage user) private view returns (uint) {
        if (totalShares <= 0) return 0;                        
        if (block.number <= lastRewardBlock) {                 
            uint pending = user.shares.mul(accruedTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);
            return realPending(pending);
        }
        uint multiplier = block.number.sub(lastRewardBlock);   
        uint reward = multiplier.mul(rewardPerBlock);          
        uint adjustedTokenPerShare = accruedTokenPerShare.add(reward.mul(PRECISION_FACTOR).div(totalShares));
        uint pending2 = user.shares.mul(adjustedTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);
        return realPending(pending2);
    }
    function realPending(uint pending) private view returns (uint) {
        if (pending > 0) {
            uint minable = query_minable();
            if (minable < pending) pending = minable;
        }
        return pending;
    }
    function updatePool() private {
        if (block.number <= lastRewardBlock) return;           
        if (totalShares == 0) {                                
            lastRewardBlock = block.number;
            return;
        }
        uint multiplier = block.number.sub(lastRewardBlock);   
        uint reward = multiplier.mul(rewardPerBlock);          
        accruedTokenPerShare = accruedTokenPerShare.add(reward.mul(PRECISION_FACTOR).div(totalShares));
        lastRewardBlock = block.number;
    }
    function query_minable() private view returns(uint) {
        if (isRewardERC20) {   
            if (isStakedERC20 && address(stakedToken) == address(rewardToken)) {   
                return rewardToken.balanceOf(address(this)).sub(totalAmount);      
            } else {
                return rewardToken.balanceOf(address(this));
            }
        } else {               
            if (isStakedERC20) {
                return address(this).balance;
            } else {                                                               
                return address(this).balance.sub(msg.value).sub(totalAmount);
            }
        }
    }
}