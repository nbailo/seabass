// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

contract External {
    bool status = true;

    function update() external {
        status = false;
    }

    function getStatus() external view returns (bool) {
        return status;
    }
}
