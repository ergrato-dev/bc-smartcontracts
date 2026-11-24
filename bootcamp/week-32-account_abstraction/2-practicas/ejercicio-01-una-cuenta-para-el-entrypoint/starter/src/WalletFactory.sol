// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {IEntryPoint} from "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {ISenderCreator} from "@account-abstraction/contracts/interfaces/ISenderCreator.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {SimpleWallet} from "./SimpleWallet.sol";

/// @title Fábrica de SimpleWallet con CREATE2
/// @notice La dirección de una cuenta se conoce antes de desplegarla: se le puede mandar ETH, y su
///         primera operación la despliega (`initCode`).
contract WalletFactory {
    IEntryPoint public immutable entryPoint;
    ISenderCreator public immutable senderCreator;

    error NotSenderCreator(address caller);

    constructor(IEntryPoint entryPoint_) {
        entryPoint = entryPoint_;
        senderCreator = entryPoint_.senderCreator();
    }

    /// @notice Despliega la cuenta de `owner`, o devuelve la que ya existe.
    /// @dev Solo la llama el SenderCreator del EntryPoint, al procesar un `initCode`.
    function createWallet(address owner, uint256 salt) external returns (SimpleWallet wallet) {
        if (msg.sender != address(senderCreator)) revert NotSenderCreator(msg.sender);
        address predicted = getAddress(owner, salt);
        if (predicted.code.length > 0) return SimpleWallet(payable(predicted));
        wallet = new SimpleWallet{salt: bytes32(salt)}(entryPoint, owner);
    }

    // PASO 5: la dirección de CREATE2, con el hash del código y de los argumentos del constructor.
    /// @notice La dirección que tendrá la cuenta de `owner` con `salt`.
    function getAddress(address owner, uint256 salt) public view returns (address) {
        revert("TODO: Paso 5");
        //> bytes32 initCodeHash =
        //>     keccak256(abi.encodePacked(type(SimpleWallet).creationCode, abi.encode(entryPoint, owner)));
        //> return Create2.computeAddress(bytes32(salt), initCodeHash);
    }
}
