// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Registry} from "../src/Registry.sol";
import {IRegistry} from "../src/IRegistry.sol";

// ¿Qué? Siete propiedades del registro, cada una probada con entradas al azar. Escribe cada
//   test donde dice `// TODO:` y borra su `revert`.
// ¿Para qué? Los tests de ejemplo usan block.timestamp = 1, capacidad 3 y cuotas de 0 y
//   fee + 1. Una propiedad vale para cualquier hora, capacidad o cuota, y el fuzzer las prueba.
// ¿Impacto? Bien escritas, detectan fallos que los 44 tests de ejemplo dejan pasar.
contract RegistryFuzzTest is Test {
    Registry registry;
    uint256 fee;
    address alice = makeAddr("alice");

    function setUp() public {
        registry = new Registry(10);
        fee = registry.REGISTRATION_FEE();
    }

    function _labels(uint256 n) internal pure returns (string[] memory labels) {
        labels = new string[](n);
        for (uint256 i = 0; i < n; i++) {
            labels[i] = "item";
        }
    }

    // TODO: cualquier cuenta, cualquier etiqueta válida y cualquier hora: el recurso se guarda
    //   tal cual (registrante, etiqueta, registeredAt == la hora y estado Active).
    //   Pista: `vm.assume` para la longitud de la etiqueta, `bound` + `vm.warp` para la hora
    //   y `hoax` para que pague `registrant`.
    function testFuzz_RegisterStoresItem(address registrant, string calldata label, uint256 timestamp) public {
        revert("TODO: testFuzz_RegisterStoresItem");
    }

    // TODO: toda etiqueta de MAX_LABEL_LENGTH + 1 a 1000 bytes revierte con InvalidLabel.
    //   Pista: `string(new bytes(length))` crea una etiqueta de esa longitud.
    function testFuzz_RevertWhen_LabelTooLong(uint256 length) public {
        revert("TODO: testFuzz_RevertWhen_LabelTooLong");
    }

    // TODO: cualquier cuota de 0 a 100 ether distinta de la tasa revierte con
    //   WrongFee(fee, sent).
    function testFuzz_RevertWhen_FeeIsWrong(uint256 sent) public {
        revert("TODO: testFuzz_RevertWhen_FeeIsWrong");
    }

    // TODO: en un lote de 1 a MAX_BATCH recursos, cualquier cuota distinta de amount * fee
    //   revierte con WrongFee(amount * fee, sent). De menos y de más.
    function testFuzz_RevertWhen_BatchFeeIsWrong(uint256 amount, uint256 sent) public {
        revert("TODO: testFuzz_RevertWhen_BatchFeeIsWrong");
    }

    // TODO: alice registra; cualquier otra cuenta que intente retirarlo recibe
    //   NotRegistrant(stranger, id).
    function testFuzz_RevertWhen_StrangerRetires(address stranger) public {
        revert("TODO: testFuzz_RevertWhen_StrangerRetires");
    }

    // TODO: con una capacidad de 1 a 50, el registro admite justo esa cantidad, queda lleno
    //   (isFull, remaining == 0) y el siguiente revierte con RegistryFull(capacity).
    function testFuzz_NeverExceedsCapacity(uint256 capacity) public {
        revert("TODO: testFuzz_NeverExceedsCapacity");
    }

    // TODO: tras un lote de 1 a MAX_BATCH recursos, el dueño retira y `to` recibe
    //   exactamente lo cobrado; el registro queda en 0.
    //   Pista: `to` no puede ser address(0), un precompilado, una dirección de forge ni un
    //   contrato (`assumeNotPrecompile`, `assumeNotForgeAddress`, `to.code.length == 0`).
    function testFuzz_WithdrawSendsAllFees(uint256 amount, address payable to) public {
        revert("TODO: testFuzz_WithdrawSendsAllFees");
    }
}
