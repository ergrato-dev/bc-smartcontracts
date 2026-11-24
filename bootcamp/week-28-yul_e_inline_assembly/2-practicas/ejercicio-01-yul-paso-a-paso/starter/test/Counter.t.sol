// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";

// La interfaz que el contador en Yul promete: dos funciones, con sus selectores.
interface ICounter {
    function count() external view returns (uint256);
    function increment() external;
}

// ¿Qué? El contador de src/Counter.yul, desplegado desde su bytecode y llamado por su interfaz.
// ¿Para qué? Comprobar el dispatcher: cada selector llega a su función y cualquier otro revierte.
contract CounterTest is Test {
    ICounter counter;

    function setUp() public {
        // forge compila el objeto Yul, pero sin ABI: su bytecode se lee del artefacto.
        string memory artifact = vm.readFile("out/Counter.yul/Counter.json");
        bytes memory code = vm.parseJsonBytes(artifact, ".bytecode.object");
        address deployed;
        assembly ("memory-safe") {
            deployed := create(0, add(code, 0x20), mload(code))
        }
        require(deployed != address(0), "despliegue fallido");
        counter = ICounter(deployed);
    }

    function test_Paso5_StartsAtSeven() public view {
        assertEq(counter.count(), 7);
    }

    function test_Paso5_Increment() public {
        counter.increment();
        counter.increment();
        assertEq(counter.count(), 9);
    }

    function test_Paso5_UnknownSelectorReverts() public {
        (bool ok, bytes memory ret) = address(counter).call(abi.encodeWithSignature("reset()"));
        assertFalse(ok);
        assertEq(ret.length, 0);
    }
}
