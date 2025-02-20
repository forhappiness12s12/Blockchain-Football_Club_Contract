// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FootballClubTrade {
    IERC20 public token;
    uint256 public acceptDeadline = 1296000; // Global variable for acceptance deadline, 15 days as default
    address public ownerAddress;
    address public profitAddress;
    uint256 public feePercentage = 100; // Fee percentage(100X) (e.g., 1% = 100)
    uint256 public currentClubId = 0; // Counter for the number of clubs
    uint256 public lastTimestamp = 0;
    uint256 public currentTimestamp = 0;
    uint256[] lastOpenInterest = new uint256[](clubs.length);

    struct Club {
        string name;
        string abbr;
        uint256 stockPrice;
        uint256 openinterest;
        uint256 longpercent;
        uint256 shortpercent;
        uint256 availlong;
        uint256 availshort;
        uint256 funding;
        uint256 velocity;
    }
    struct Position {
        uint256 futureId;
        uint256 clubId;
        uint256 positionType; //1 - long, 2- short
        uint256 stockAmount;
        uint256 stockPrice;
        uint256 status; //1 - open, 2 - closed, 3 - processed
        address userAddress;
    }

    mapping(uint256 => uint256) public futureDates; // Mapping from order to future date
    uint256 public futureIndex; // Keeps track of the next order index

    mapping(address => mapping(uint256 => uint256)) userStock; // Maps club number to user address to stock amount
    // Define a struct to keep track of historical data
    struct HistoricalStockData {
        uint256[] prices;
    }

    // Define mappings
    mapping(uint256 => HistoricalStockData) private historicalstockprice;

    Club[] clubs;
    Position[] positions;
    address[] positionOwners;

    modifier onlyOwner() {
        require(msg.sender == ownerAddress);
        _;
    }

    constructor(
        address _tokenAddress,
        address _ownerAddress,
        address _profitAddress
    ) {
        token = IERC20(_tokenAddress);
        ownerAddress = _ownerAddress;
        profitAddress = _profitAddress;
    }

    function registerClub(string memory name, string memory abbr) external {
        require(bytes(name).length > 0, "Club name is required");
        require(bytes(abbr).length > 0, "Club abbr is required");

        for (uint256 i = 0; i < clubs.length; i++) {
            // Club memory club = clubs[i];
            if (keccak256(bytes(clubs[i].abbr)) == keccak256(bytes(abbr))) {
                revert("Club already registered");
            }
        }

        clubs.push(Club(name, abbr, 100_000_000, 0, 0, 0, 0, 0, 0, 0));
    }

    function getClub(uint256 clubId) external view returns (Club memory) {
        require(clubId < clubs.length, "Invalid club ID");

        return clubs[clubId];
    }

    function getClubIndex() external view returns (uint256) {
        return clubs.length;
    }

    function getAllClubs() external view returns (Club[] memory) {
        Club[] memory result = new Club[](clubs.length);
        for (uint256 i = 0; i < clubs.length; i++) {
            result[i] = clubs[i];
        }

        return clubs;
    }

    function registerFutureDate(uint256 _futureDate) external onlyOwner {
        futureDates[futureIndex] = _futureDate;
        futureIndex++;
    }

    function updateFutureDate(
        uint256 orderIndex,
        uint256 newFutureDate
    ) external onlyOwner {
        require(orderIndex < futureIndex, "Invalid order index"); // Ensure the index is within the valid range

        futureDates[orderIndex] = newFutureDate;
    }

    function getRegisteredFutureDate(
        uint256 orderIndex
    ) external view returns (uint256) {
        require(orderIndex < futureIndex, "Invalid order index");
        return futureDates[orderIndex];
    }

    // Function to update acceptDeadline
    function setAcceptDeadline(uint256 _acceptDeadline) external onlyOwner {
        acceptDeadline = _acceptDeadline;
    }

    function getAcceptDeadline() external view returns (uint256) {
        return acceptDeadline;
    }

    function setClubStockPrice(uint256 clubId, uint256 newStockPrice) external {
        require(clubId < clubs.length, "Club is not registered");
        Club storage club = clubs[clubId];

        addHistoricalPrice(clubId, club.stockPrice);
        club.stockPrice = newStockPrice;
        clubs[clubId] = club;
    }
    function addHistoricalPrice(uint256 clubId, uint256 price) public {
        require(clubId < clubs.length, "Club is not registered");

        HistoricalStockData storage data = historicalstockprice[clubId];
        data.prices.push(price);
    }

    function getHistoricalClubStockPrices(
        uint256 clubId
    ) external view returns (uint256[] memory) {
        require(clubId < clubs.length, "Club is not registered");

        HistoricalStockData storage data = historicalstockprice[clubId];
        return data.prices;
    }

    function getClubStockPrice(uint256 clubId) external view returns (uint256) {
        require(clubId < clubs.length, "Club is not registered");
        return clubs[clubId].stockPrice;
    }
    function setVelocity() external {
        // Initialize arrays for storing current open interest and changes in open interest
        uint256[] memory currentOpenInterest = new uint256[](clubs.length);
        int256[] memory changeInOpenInterest = new int256[](clubs.length);

        // Populate the currentOpenInterest array
        for (uint256 i = 0; i < clubs.length; i++) {
            currentOpenInterest[i] = clubs[i].openinterest;
        }

        uint256 currentTime = block.timestamp;

        if (lastTimestamp > 0) {
            uint256 timeElapsed = currentTime - lastTimestamp;

            for (uint256 i = 0; i < clubs.length; i++) {
                changeInOpenInterest[i] =
                    int256(currentOpenInterest[i]) -
                    int256(lastOpenInterest[i]);

                if (timeElapsed > 0) {
                    // Ensure there's no division by zero
                    clubs[i].velocity = uint256(
                        changeInOpenInterest[i] / int256(timeElapsed)
                    );
                } else {
                    clubs[i].velocity = 0; // Set velocity to 0 if timeElapsed is 0
                }
            }
        }

        // Update lastOpenInterest and lastTimestamp
        for (uint256 i = 0; i < clubs.length; i++) {
            lastOpenInterest[i] = currentOpenInterest[i];
        }
        lastTimestamp = currentTime;
    }

    function getVelocity(uint256 clubId) external view returns (uint256) {
        require(clubId < clubs.length, "Invalid club ID");
        return clubs[clubId].velocity;
    }

    function setOpenInterest() external {
        // Initialize arrays for long and short stocks
        uint256[] memory totallongstock = new uint256[](clubs.length);
        uint256[] memory totalshortstock = new uint256[](clubs.length);

        // Iterate through positions and calculate long and short stocks for each club
        for (uint256 i = 0; i < positions.length; i++) {
            Position memory position = positions[i];
            if (position.status == 1) {
                if (position.positionType == 1) {
                    // Long
                    totallongstock[position.clubId] += position.stockAmount;
                } else if (position.positionType == 2) {
                    // Short
                    totalshortstock[position.clubId] += position.stockAmount;
                }
            }
        }

        // Calculate open interest, long percentage, and short percentage for each club
        for (uint256 j = 0; j < clubs.length; j++) {
            uint256 totalOpenInterest = totallongstock[j] + totalshortstock[j];
            clubs[j].openinterest = totalOpenInterest;
            clubs[j].availlong = totallongstock[j];
            clubs[j].availshort = totalshortstock[j];

            if (totalOpenInterest > 0) {
                clubs[j].longpercent =
                    (totallongstock[j] * 100) /
                    totalOpenInterest;
                clubs[j].shortpercent =
                    (totalshortstock[j] * 100) /
                    totalOpenInterest;
                clubs[j].funding = totallongstock[j] - totalshortstock[j];
            } else {
                clubs[j].longpercent = 0;
                clubs[j].shortpercent = 0;
                clubs[j].funding = 0; // Initialize funding to 0 when there is no open interest
            }
        }
    }

    function getOpenInterest(
        uint256 clubId
    )
        external
        view
        returns (
            uint256 openInterest,
            uint256 longPercent,
            uint256 shortPercent,
            uint256 availlong,
            uint256 availshort
        )
    {
        require(clubId < clubs.length, "Club is not registered");

        // Retrieve the open interest, long percent, and short percent for the specified club
        openInterest = clubs[clubId].openinterest;
        longPercent = clubs[clubId].longpercent;
        shortPercent = clubs[clubId].shortpercent;
        availlong = clubs[clubId].availlong;
        availshort = clubs[clubId].availshort;

        return (openInterest, longPercent, shortPercent, availlong, availshort);
    }

    function getAllowance() external view returns (uint256) {
        uint256 currentAllowance = token.allowance(msg.sender, address(this));
        return currentAllowance;
    }

    function openPosition(
        uint256 clubId,
        uint256 stockAmount,
        uint256 longShort,
        uint256 value,
        uint256 _futureIndex
    ) external payable {
        require(clubId < clubs.length, "Club is not registered");
        require(_futureIndex < futureIndex, "Invalid future index");

        uint256 currentTime = block.timestamp;
        uint256 adjustedFutureDate = futureDates[_futureIndex];

        require(
            currentTime < adjustedFutureDate - acceptDeadline,
            "Current time is not within the allowed acceptance period"
        );

        if (longShort == 2) {
            // Short
            require(
                userStock[msg.sender][clubId] >= stockAmount,
                "Insufficient user stock balance"
            );

            userStock[msg.sender][clubId] =
                userStock[msg.sender][clubId] -
                stockAmount;
        } else if (longShort == 1) {
            // Long position
            uint256 tokenAmount = stockAmount * value;
            require(
                token.balanceOf(msg.sender) >= tokenAmount,
                "Insufficient token balance"
            );

            require(
                token.transferFrom(msg.sender, address(this), tokenAmount),
                "Token transfer failed"
            );
        } else {
            revert("Invalid longShort value");
        }

        positions.push(
            Position(
                _futureIndex,
                clubId,
                longShort,
                stockAmount,
                value,
                1,
                msg.sender
            )
        );
    }

    function closePosition(uint256 positionId) external {
        require(positionId < positions.length, "Position not exist");
        require(
            msg.sender == positions[positionId].userAddress,
            "No privilege to close this position"
        );
        closePositionInternal(positionId);
    }

    function closePositionInternal(uint256 positionId) internal {
        Position memory position = positions[positionId];
        require(position.status == 1, "Position already closed or processed");
        address userAddress = position.userAddress;

        if (position.positionType == 1) {
            uint256 tokenAmount = (position.stockPrice *
                position.stockAmount *
                (10000 - feePercentage)) / 10000;
            require(
                token.transfer(userAddress, tokenAmount),
                "Token transfer failed"
            );
        } else if (position.positionType == 2) {
            userStock[userAddress][position.clubId] =
                userStock[userAddress][position.clubId] +
                position.stockAmount;
        } else {
            revert("Invalid longShort value");
        }

        position.status = 2;
        positions[positionId] = position;
    }

    function getOpenPosition(
        uint256 positionId
    ) external view returns (Position memory) {
        require(positionId < positions.length, "Position does not exist");

        Position memory position = positions[positionId];

        return position;
    }

    function executeFuture(uint256 _futureIndex) external {
        for (uint256 i = 0; i < positions.length; i++) {
            Position memory position = positions[i];
            if (position.futureId != _futureIndex || position.status != 1)
                continue;

            uint256 clubId = position.clubId;
            uint256 currentPrice = clubs[clubId].stockPrice;
            if (position.positionType == 1) {
                //Long
                if (currentPrice <= position.stockPrice) {
                    //process position
                    position.status = 3;
                    positions[i] = position;
                    userStock[position.userAddress][clubId] =
                        userStock[position.userAddress][clubId] +
                        position.stockAmount;
                } else {
                    //close position
                    closePositionInternal(i);
                }
            } else {
                //Short
                if (currentPrice >= position.stockPrice) {
                    //process position
                    position.status = 3;
                    positions[i] = position;
                    userStock[position.userAddress][clubId] =
                        userStock[position.userAddress][clubId] -
                        position.stockAmount;
                    uint256 tokenAmount = (position.stockPrice *
                        position.stockAmount *
                        (10000 - feePercentage)) / 10000;
                    token.transfer(position.userAddress, tokenAmount);
                } else {
                    //close position
                    closePositionInternal(i);
                }
            }
        }
    }

    function getUserOpenPositions(
        address userAddress
    ) external view returns (Position[] memory) {
        uint256 positionSize = 0;
        for (uint256 i = 0; i < positions.length; i++) {
            Position memory position = positions[i];
            if (position.status == 1 && position.userAddress == userAddress) {
                positionSize++; //result.push(position);
            }
        }

        if (positionSize == 0) {
            return new Position[](0);
        }

        Position[] memory result = new Position[](positionSize);
        positionSize = 0;
        for (uint256 i = 0; i < positions.length; i++) {
            Position memory position = positions[i];
            if (position.status == 1 && position.userAddress == userAddress) {
                result[positionSize] = position;
                positionSize++;
            }
        }
        return result;
    }

    function getUserStock(
        address userAddress
    ) external view returns (uint256[] memory) {
        uint256[] memory userStocks = new uint256[](clubs.length);
        for (uint256 i = 0; i < clubs.length; i++) {
            userStocks[i] = userStock[userAddress][i];
        }
        return userStocks;
    }

    function setManagerWallet(address _profitAddress) external onlyOwner {
        profitAddress = _profitAddress;
    }

    function setFeePercentage(uint256 _feePercentage) external onlyOwner {
        feePercentage = _feePercentage;
    }

    function withdraw(uint256 amount, address target) external onlyOwner {
        require(
            token.balanceOf(address(this)) >= amount,
            "Insufficient token balance"
        );
        token.transfer(target, amount);
    }
}
