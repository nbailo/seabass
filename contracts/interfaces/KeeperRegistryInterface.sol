// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import {State, Config} from "@chainlink/contracts/src/v0.8/interfaces/AutomationRegistryInterface1_2.sol";

interface KeeperRegistryInterface {
    function withdrawFunds(uint256 id, address to) external;

    function cancelUpkeep(uint256 id) external;

    function getState()
        external
        view
        returns (
            State memory state,
            Config memory config,
            address[] memory keepers
        );
}
