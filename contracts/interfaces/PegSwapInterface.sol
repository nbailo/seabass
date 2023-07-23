// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface PegSwapInterface {
    function swap(uint256 amount, address source, address target) external;
}
