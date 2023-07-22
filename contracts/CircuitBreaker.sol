// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

contract CircuitBreaker is KeeperCompatibleInterface {
    using SafeCast for uint256;

    AggregatorV3Interface internal priceFeed;
    bool public stopped = false;
    address public externalContract;
    uint256 public oracleDeviationLimit;
    bytes4 public functionSelector;
    uint256 public endSubscriptionTime;

    struct OracleLatestAnswerInfo {
        int256 latestAnswer;
        uint256 timestamp;
    }

    OracleLatestAnswerInfo public oracleLatestAnswerInfo;

    constructor(
        address _priceFeed,
        uint256 _oracleDeviationLimit,
        address _externalContract,
        string memory _functionName
    ) {
        priceFeed = AggregatorV3Interface(_priceFeed);
        oracleDeviationLimit = _oracleDeviationLimit; //  10% within 1 day = 10 * (1 ether) / uint256(86400 * 100)
        externalContract = _externalContract;
        functionSelector = bytes4(keccak256(bytes(_functionName)));

        (, int256 latestAnswer, , , ) = priceFeed.latestRoundData();
        oracleLatestAnswerInfo.latestAnswer = latestAnswer;
        oracleLatestAnswerInfo.timestamp = block.timestamp;
    }

    function checkUpkeep(
        bytes calldata checkData
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        (, int256 latestAnswer, , , ) = priceFeed.latestRoundData();

        OracleLatestAnswerInfo
            storage _oracleLatestAnswerInfo = oracleLatestAnswerInfo;

        // Calculate deviation percentage per second
        int256 delta = _oracleLatestAnswerInfo.latestAnswer - latestAnswer;
        int256 deltaTime = (block.timestamp - _oracleLatestAnswerInfo.timestamp)
            .toInt256();

        delta = (delta * (1 ether)) / _oracleLatestAnswerInfo.latestAnswer;

        // Check if deviation is within limit
        if (uint256(delta / deltaTime) > oracleDeviationLimit) {
            upkeepNeeded = true;
            performData = checkData;
        } else {
            upkeepNeeded = false;
        }
    }

    function performUpkeep(bytes calldata performData) external override {
        if (!stopped) {
            // Call the specific function on the external contract
            (bool success, ) = externalContract.call(
                abi.encodeWithSelector(functionSelector)
            );
            require(success, "External call failed");
            stopped = true;
        }
    }
}
