// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface Link677Interface {
    function transferAndCall(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function approve(
        address _spender,
        uint256 _value
    ) external returns (bool success);
}
