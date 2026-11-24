// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

/// @notice Un código anterior en el que delegó la EOA: guarda un número en el slot 0.
contract OldDelegate {
    uint256 public savedNumber;

    function save(uint256 number) external {
        savedNumber = number;
    }
}
