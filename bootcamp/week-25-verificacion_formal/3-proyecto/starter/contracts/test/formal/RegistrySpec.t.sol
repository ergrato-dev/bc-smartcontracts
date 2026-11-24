// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/shared/mocks/MockV3Aggregator.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {Certificate} from "../../src/Certificate.sol";
import {IRegistry} from "../../src/IRegistry.sol";
import {LoyaltyToken} from "../../src/LoyaltyToken.sol";
import {Registry} from "../../src/Registry.sol";
import {RegistryV2} from "../../src/RegistryV2.sol";
import {RegistryV3} from "../../src/RegistryV3.sol";

// ¿Qué? Las specs de Halmos del protocolo: cada `check_` dice algo que el registro promete y
//   Halmos lo comprueba para todos los valores de sus parámetros, no para unos cuantos.
// ¿Para qué? Demostrar las reglas de acceso y de cobro que las invariantes de la semana 24 solo
//   muestrean: cualquier llamante, cualquier `msg.value`, cualquier argumento.
// ¿Impacto? `forge test` no las ejecuta (no empiezan por `test`): las ejecuta `halmos` en
//   test.sh. Un camino que revierte no cuenta como fallo en Halmos: lo que debe revertir se
//   comprueba con `call` o `try` y un `assert`.
contract RegistrySpec is Test {
    uint256 internal constant CAPACITY = 10;
    uint256 internal constant MAX_PER_ACCOUNT = 5;
    // El slot de ERC-1967 donde el proxy guarda la dirección de la implementación.
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    RegistryV3 internal registry;
    LoyaltyToken internal loyalty;
    Certificate internal certificate;
    MockV3Aggregator internal feed;

    function setUp() public {
        // El token y el certificado necesitan la dirección del registro en su constructor, antes
        // de que exista. Halmos no da a CREATE ni a CREATE2 la dirección de la fórmula de la EVM
        // (las numera: 0xaaaa0001...), así que la fórmula de RegistryHandler aquí no sirve. El
        // proxy va a una dirección elegida: se copia ahí el código de un proxy de verdad
        // (`vm.etch`) y se escribe su implementación en el slot de ERC-1967 (`vm.store`).
        Registry implementation = new Registry();
        address proxy = address(0x5E6157A7);
        loyalty = new LoyaltyToken(proxy);
        certificate = new Certificate(IRegistry(proxy));
        ERC1967Proxy model = new ERC1967Proxy(address(implementation), abi.encodeCall(Registry.version, ()));
        vm.etch(proxy, address(model).code);
        vm.store(proxy, IMPLEMENTATION_SLOT, bytes32(uint256(uint160(address(implementation)))));

        // Lo mismo que DeployProtocol y las dos actualizaciones. Este contrato es el administrador.
        Registry v1 = Registry(proxy);
        v1.initialize(CAPACITY, loyalty, certificate);
        v1.setHook(address(loyalty));
        v1.upgradeToAndCall(address(new RegistryV2()), abi.encodeCall(RegistryV2.initializeV2, (MAX_PER_ACCOUNT)));
        feed = new MockV3Aggregator(8, 2500e8);
        v1.upgradeToAndCall(
            address(new RegistryV3()),
            abi.encodeCall(RegistryV3.initializeV3, (AggregatorV3Interface(address(feed)), 25e18, 365 days))
        );
        registry = RegistryV3(proxy);
        // Tasas ya cobradas: sin saldo, `withdrawFees` revertiría por NothingToWithdraw aunque
        // cualquiera pudiera llamarla, y la spec de acceso no lo vería.
        vm.deal(address(registry), 1 ether);
    }

    // Cualquier cuenta sin código que pague cualquier cantidad: el registro se queda la tasa
    // exacta y devuelve el resto.
    function check_registerChargesExactFee(address caller, uint256 value) public {
        vm.assume(caller.code.length == 0 && caller != address(0));
        uint256 fee = registry.registrationFee();
        vm.deal(caller, value);
        uint256 registryBefore = address(registry).balance;
        vm.prank(caller);
        registry.register{value: value}("label");
        assertEq(address(registry).balance, registryBefore + fee);
        assertEq(caller.balance, value - fee);
    }

    // Una cuenta da de alta un recurso. Cualquier llamante intenta retirarlo: solo lo consigue
    // quien tiene el certificado, y solo entonces baja `activeCount`.
    function check_retireOnlyByHolder(address caller) public {
        // TODO (semana 25): una cuenta fija da de alta un recurso. `caller` intenta retirarlo
        //   dentro de un `try`. Comprueba que sale bien si y solo si `caller` es esa cuenta, y que
        //   `activeCount` solo baja entonces.
        assertTrue(false, "TODO: check_retireOnlyByHolder");
    }

    // Cualquier cuenta da de alta `MAX_PER_ACCOUNT` recursos; la siguiente alta se rechaza.
    function check_perAccountLimit(address caller) public {
        // TODO (semana 25): `caller` da de alta MAX_PER_ACCOUNT recursos. La alta siguiente se
        //   intenta dentro de un `try`: comprueba que el registro la rechaza.
        assertTrue(false, "TODO: check_perAccountLimit");
    }

    // Una cuenta sin ningún rol llama a cualquiera de las funciones privilegiadas, con cualquier
    // argumento: todas revierten. `which` elige la función; la lista es explícita, y lo que no
    // está en ella no se prueba.
    function check_strangerCannotAdmin(address caller, uint8 which, address a, uint256 x, uint256 y, bytes32 role)
        public
    {
        // TODO (semana 25): `which` elige una de las diez funciones privilegiadas (pause, unpause,
        //   withdrawFees, setHook, removeHook, setFeeConfig, initializeV3, upgradeToAndCall,
        //   grantRole, revokeRole), con `a`, `x`, `y` y `role` como argumentos. `caller`, que no
        //   es el administrador, la llama con `call`: comprueba que revierte.
        assertTrue(false, "TODO: check_strangerCannotAdmin");
    }

    // Con el registro en pausa, ninguna de las cinco formas de dar de alta funciona, la llame
    // quien la llame y pague lo que pague.
    function check_pausedRejectsRegistrations(address caller, uint256 value, uint8 which, uint256 deadline) public {
        // TODO (semana 25): este contrato se da PAUSER_ROLE y pausa el registro. `which` elige una
        //   de las cinco formas de alta (register, registerBatch, registerWithPoints, registerBySig,
        //   registerWithPermit). `caller` la llama con `call` y `value` wei: comprueba que revierte.
        assertTrue(false, "TODO: check_pausedRejectsRegistrations");
    }
}
