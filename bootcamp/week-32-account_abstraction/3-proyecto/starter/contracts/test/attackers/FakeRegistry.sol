// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

/// @notice Un contrato del atacante con la misma función que el registro: si el paymaster solo
///   mirara el selector, pagaría el gas de lo que este contrato quiera hacer.
contract FakeRegistry {
    function registerWithPermit(string calldata, uint256, uint8, bytes32, bytes32) external pure returns (uint256) {
        return 0;
    }
}
