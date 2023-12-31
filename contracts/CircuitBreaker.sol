// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

contract CircuitBreaker is KeeperCompatibleInterface {
    using SafeCast for uint256;

    AggregatorV3Interface internal priceFeed;
    bool public stopped = false;
    address public owner;
    address public externalContract;
    uint256 public oracleDeviationLimit;
    bytes4 public functionSelector;
    uint256 public endSubscriptionTime;
    address public keeper;

    struct OracleLatestAnswerInfo {
        int256 latestAnswer;
        uint256 timestamp;
    }

    OracleLatestAnswerInfo public oracleLatestAnswerInfo;

    event CircuitBreakerStopped();

    constructor(
        address _owner,
        address _priceFeed,
        uint256 _oracleDeviationLimit,
        address _externalContract,
        string memory _functionName,
        address _keeper
    ) {
        owner = _owner;
        priceFeed = AggregatorV3Interface(_priceFeed);
        oracleDeviationLimit = _oracleDeviationLimit; //  10% within 1 day = 10 * (1 ether) / uint256(86400 * 100)
        externalContract = _externalContract;
        functionSelector = bytes4(keccak256(bytes(_functionName)));
        keeper = _keeper;

        _setPrice();
    }

    modifier onlyKeeper() {
        require(msg.sender == keeper, "Only keeper can call this");
        _;
    }

    /**
     * @notice Check if upkeep is needed
     * @param checkData The data passed to the contract when checking for upkeep
     * @return upkeepNeeded boolean to indicate whether upkeep is needed
     * @return performData bytes that encode the data to be passed to the
     * contract when performing upkeep
     */
    function checkUpkeep(
        bytes calldata checkData
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        // Check if at least a day has passed since the last price update
        bool priceUpdateNeeded = (block.timestamp -
            oracleLatestAnswerInfo.timestamp >=
            1 days);

        (, int256 latestAnswer, , , ) = priceFeed.latestRoundData();

        OracleLatestAnswerInfo
            storage _oracleLatestAnswerInfo = oracleLatestAnswerInfo;

        // Calculate deviation percentage per second
        int256 delta = _oracleLatestAnswerInfo.latestAnswer - latestAnswer;
        int256 deltaTime = (block.timestamp - _oracleLatestAnswerInfo.timestamp)
            .toInt256();

        if (delta < 0) delta = 0 - delta;
        if (deltaTime == 0 || _oracleLatestAnswerInfo.latestAnswer == 0)
            delta = 0;
        delta = (delta * (1 ether)) / _oracleLatestAnswerInfo.latestAnswer;

        // Check if deviation is within limit
        bool priceFluctuated;
        if (uint256(delta / deltaTime) > oracleDeviationLimit) {
            priceFluctuated = true;
        } else {
            priceFluctuated = false;
        }

        upkeepNeeded = priceUpdateNeeded || (priceFluctuated && !stopped);
        performData = checkData;
    }

    /**
     * @notice Perform upkeep
     * @param performData The data passed to the contract when performing upkeep
     */
    function performUpkeep(
        bytes calldata performData
    ) external override onlyKeeper {
        if (block.timestamp - oracleLatestAnswerInfo.timestamp >= 1 days) {
            _setPrice();
        }

        if (!stopped) {
            // Call the specific function on the external contract
            (bool success, ) = externalContract.call(
                abi.encodeWithSelector(functionSelector)
            );
            require(success, "External call failed");
            stopped = true;
            emit CircuitBreakerStopped();
        }
    }

    function _setPrice() internal {
        (, int256 latestAnswer, , , ) = priceFeed.latestRoundData();
        oracleLatestAnswerInfo.latestAnswer = latestAnswer;
        oracleLatestAnswerInfo.timestamp = block.timestamp;
    }
}
