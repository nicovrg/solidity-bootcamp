// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "../lib/openzeppelin-contracts/contracts/utils/math/SafeMath.sol";
import "../lib/openzeppelin-contracts/contracts/utils/math/Math.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

import "./ERC20_.sol";
import "./WETH_.sol";

contract Farm is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    WETH_ public weth;  // staking token
    ERC20_ public erc20;  // rewards token

    uint public rewardRate = 1;  // reward tokens to distribute per second (for all stakers combined)
    // uint public periodStart = block.timestamp + 2 days;  // timestamp when rewards stop being distributed
    uint public periodFinish = 2 weeks;  // timestamp when rewards stop being distributed
    uint public lastUpdateTime;  // last time reward vars were updated
    uint public rewardsPerTokenStored;  // reward tokens to distribute per staked token

    mapping(address => uint) public rewards;  // user rewards still not claimed
    mapping(address => uint) public userRewardPerTokenPaid; // user reward paid per token

    uint private _totalSupply;
    mapping(address => uint) private _balances;

    event Staked(address indexed staker, uint amount);
    event Unstaked(address indexed staker, uint amount);
    event RewardsPaid(address indexed staker, uint amount);

    constructor(address _erc20, address _weth) {
        erc20 = ERC20_(_erc20);
        weth = WETH_(payable(_weth));
    }

    modifier updateRewards(address account) {
        rewardsPerTokenStored = rewardsPerToken();
        lastUpdateTime = lastTimeRewardsApplicable();
        rewards[account] = earned(account);
        userRewardPerTokenPaid[account] = rewardsPerTokenStored;
        _;
    }

    function getTotalSupply() external view returns (uint) {
        return _totalSupply;
    }
    function getBalanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardsApplicable() public view returns (uint) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardsPerToken() public view returns (uint) {
        if (_totalSupply == 0)
            return rewardsPerTokenStored;
        return rewardsPerTokenStored.add(
            lastTimeRewardsApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply)
        );
    }

    function earned(address account) public view returns (uint) {
        return _balances[account].mul(
            rewardsPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    function stake(uint256 amount) external nonReentrant updateRewards(msg.sender) {
        require(amount != 0, "Farm: Cannot stake 0");

        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        require(weth.transferFrom(msg.sender, address(this), amount));

        emit Staked(msg.sender, amount);
    }

    function unstake(uint amount) public nonReentrant updateRewards(msg.sender) {
        require(amount > 0, "Farm: Cannot unstake 0");
        require(weth.transfer(msg.sender, amount));

        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _totalSupply = _totalSupply.sub(amount);

        emit Unstaked(msg.sender, amount);
    }

    function claimRewards() public nonReentrant updateRewards(msg.sender) {
        uint userRewards = rewards[msg.sender];
        if (userRewards > 0) {
            rewards[msg.sender] = 0;
            erc20._mint(msg.sender, userRewards);
            emit RewardsPaid(msg.sender, userRewards);
        }
    }

    function exit() external {
        unstake(_balances[msg.sender]);
        claimRewards();
    }
}
