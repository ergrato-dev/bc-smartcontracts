// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

/// @notice Lo que el paymaster patrocina en este ejercicio: un contador.
contract Counter {
    uint256 public count;

    function increment() external {
        count++;
    }
}
