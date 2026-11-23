// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// Un contrato con dueño para que el multisig lo controle.
contract Config is Ownable {
    uint256 public fee = 100;

    constructor(address initialOwner) Ownable(initialOwner) {}

    function setFee(uint256 newFee) external onlyOwner {
        fee = newFee;
    }
}
