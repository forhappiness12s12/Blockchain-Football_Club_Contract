// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PlayersContract {
    // Define a struct named Staking
    struct Staking {
        address user;
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
    }

    address public owner;
    address public managementWallet;
    IERC20 public stakingToken;

    uint256 public totalPlayersPool;
    uint256 public totalBankersPool;

    address[] players;
    address[] stakers;
    address[] todayStakers;

    uint256 public maxDailyROI = 15;
    uint256 public dailyROI = 15;
    uint256 lastDistributeROIDay = 0;
    bool isTestMode = false;

    Staking[] stakings;
    Staking[] tmpStakings;

    mapping(address =>bool) stakerExists;
    mapping(address => address) playerReference;
    mapping(address => bool) playersMap;
    mapping(address => address[]) referedPlayers;
    mapping(address => uint256) public totalEarned;
    mapping(address => uint256) todayStakerAmount;

    event Staked(address indexed user, uint256 amount);
    event ReceivedDailyROI(address indexed user, uint256 amount);

    constructor(address _stakingToken, address _managementWallet) {
        owner = msg.sender;
        managementWallet = _managementWallet;
        stakingToken = IERC20(_stakingToken);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }

    function isRegister(address user) public view returns (bool) {
        return playersMap[user];
    }

    function getPlayerReferal(address user) public view returns (address) {
        return playerReference[user];
    }

    function getReferedPlayers(address user) public view returns (address[] memory) {
        return referedPlayers[user];
    }

    function register(address user, address refer) external {
        require(!playersMap[user], "User has been registered already");
        if(refer != address(0)) {
            require(playersMap[refer], "Referrer is not valid");
        }
        players.push(user);
        playersMap[user] = true;
        playerReference[user] = refer;

        if(refer != address(0)) {
            referedPlayers[refer].push(user);
        }
    }

    function stake(uint amount) external payable {
        require(amount > 0, "Amount must be greater than zero");
        require(stakingToken.transferFrom(msg.sender, address(this), amount), "Failed to transfer tokens");

        uint256 playersPoolAmount = (amount * 80) / 100;
        uint256 bankersPoolAmount = (amount * 20) / 100;
        
        totalPlayersPool += playersPoolAmount;
        totalBankersPool += bankersPoolAmount;

        // Create a new staking 
        Staking memory newStaking = Staking(msg.sender, amount, block.timestamp, block.timestamp + 3600 * 24 * 100); //daily ROI is valid for 100 days
        stakings.push(newStaking);

        if(!stakerExists[msg.sender]) {
            stakerExists[msg.sender] = true;
            stakers.push(msg.sender);
        } 

        emit Staked(msg.sender, amount);
    }

    function distributeROI() external onlyOwner {
        uint256 currentDay = block.timestamp / 24 / 3600;
        if(!isTestMode) {
            require(currentDay > lastDistributeROIDay, "Already processed ROI distribution");
        }
        
        lastDistributeROIDay = currentDay;

        for (uint256 i = 0; i < stakings.length; i++) {
            if(stakings[i].endTime <= block.timestamp) {
                tmpStakings.push(stakings[i]);
            }
        }

        //init
        delete stakings;
        delete todayStakers;
        uint256 currentStakingAmount = 0;
        for (uint256 i = 0; i < tmpStakings.length; i++) {
            todayStakerAmount[tmpStakings[i].user] = 0;
        }

        //calc today staking
        for (uint256 i = 0; i < tmpStakings.length; i++) {
            stakings.push(tmpStakings[i]);
            currentStakingAmount += tmpStakings[i].amount;
            todayStakerAmount[tmpStakings[i].user] += tmpStakings[i].amount;
        }
        delete tmpStakings;

        if(currentStakingAmount * maxDailyROI / 1000 > totalPlayersPool * 3 / 100) {
            dailyROI = maxDailyROI * (totalPlayersPool * 3 / 100) / (currentStakingAmount * maxDailyROI / 1000);
        } else {
            dailyROI = maxDailyROI;
        }

        //loop all today stakers and process ROI
        uint256 gasFee = 0;
        for(uint256 i = 0 ; i < todayStakers.length ; i++) {
            uint256 earned = todayStakerAmount[todayStakers[i]] * dailyROI / 1000;

            gasFee += (earned * 5) / 100; // 5% for gas fee
            uint256 netAmount = earned - gasFee;

            require(totalPlayersPool >= netAmount, "Insufficient funds in Players Pool");

            totalPlayersPool -= netAmount;

            totalEarned[todayStakers[i]] += earned;

            require(stakingToken.transfer(todayStakers[i], netAmount), "Failed to transfer tokens to staker");

            emit ReceivedDailyROI(todayStakers[i], netAmount);
        }
        
        totalBankersPool += gasFee;
        require(stakingToken.transfer(managementWallet, gasFee), "Failed to transfer tokens to management wallet");
    }

    function setManagementWallet(address _managementWallet) external onlyOwner {
        managementWallet = _managementWallet;
    }

    function withdrawFromBankersPool(uint256 amount) external onlyOwner {
        require(amount <= totalBankersPool, "Amount exceeds Bankers Pool balance");
        totalBankersPool -= amount;
        require(stakingToken.transfer(owner, amount), "Failed to transfer tokens");
    }

    function withdrawFromPlayersPool(uint256 amount) external onlyOwner {
        require(amount <= totalPlayersPool, "Amount exceeds Players Pool balance");
        totalPlayersPool -= amount;
        require(stakingToken.transfer(owner, amount), "Failed to transfer tokens");
    }

    function setTestMode(bool isTest) external onlyOwner {
        isTestMode = isTest;
    }

    receive() external payable {}
}
