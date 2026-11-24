// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {CommonBase} from "forge-std/Base.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/shared/mocks/MockV3Aggregator.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {Certificate} from "../../src/Certificate.sol";
import {IRegistry} from "../../src/IRegistry.sol";
import {LoyaltyToken} from "../../src/LoyaltyToken.sol";
import {Registry} from "../../src/Registry.sol";
import {RegistryV2} from "../../src/RegistryV2.sol";
import {RegistryV3} from "../../src/RegistryV3.sol";

// ¿Qué? El handler del protocolo: despliega el registro en V3 y ofrece al fuzzer las acciones de
//   unas pocas cuentas, con entradas acotadas para que casi ninguna llamada revierta.
// ¿Para qué? Que el fuzzer pruebe secuencias de altas, retiradas, transferencias y retiradas de
//   tasas, y que las variables fantasma (`ghost*`) lleven la cuenta de lo que debería haber.
// ¿Impacto? Lo usan los dos motores: forge (RegistryInvariants.t.sol) y Medusa (medusa.json),
//   así que no hereda de Test ni usa trucos de forge que Medusa no tiene, como vm.startBroadcast.
contract RegistryHandler is CommonBase, StdUtils {
    uint256 public constant CAPACITY = 10;
    uint256 public constant MAX_PER_ACCOUNT = 5;
    uint256 public constant USD_FEE = 25e18;

    RegistryV3 public registry;
    LoyaltyToken public loyalty;
    Certificate public certificate;
    MockV3Aggregator public feed;
    address public treasurer = address(0x7EA5);
    address[] public actors;

    // Lo que el protocolo debería tener, contado por el handler en cada acción que sale bien.
    uint256 public ghostFeesPaid;
    uint256 public ghostFeesWithdrawn;
    uint256 public ghostRetired;
    uint256 public ghostPointsRegistrations;

    constructor() {
        // El mismo despliegue que DeployProtocol y las dos actualizaciones, sin los trucos de forge
        // que Medusa no tiene (vm.startBroadcast, vm.computeCreateAddress). El nonce de un contrato
        // empieza en 1: el proxy es su cuarta creación, y su dirección, la fórmula de CREATE con
        // nonce 4 (semana 10): keccak256(rlp([handler, 4])).
        Registry implementation = new Registry();
        address proxy =
            address(uint160(uint256(keccak256(abi.encodePacked(bytes2(0xd694), address(this), bytes1(0x04))))));
        loyalty = new LoyaltyToken(proxy);
        certificate = new Certificate(IRegistry(proxy));
        bytes memory init = abi.encodeCall(Registry.initialize, (CAPACITY, loyalty, certificate));
        Registry v1 = Registry(address(new ERC1967Proxy(address(implementation), init)));
        v1.setHook(address(loyalty));
        v1.upgradeToAndCall(address(new RegistryV2()), abi.encodeCall(RegistryV2.initializeV2, (MAX_PER_ACCOUNT)));
        feed = new MockV3Aggregator(8, 2500e8);
        // Un plazo del precio de un año: la antigüedad del oráculo ya la prueba RegistryV3.t.sol.
        v1.upgradeToAndCall(
            address(new RegistryV3()),
            abi.encodeCall(RegistryV3.initializeV3, (AggregatorV3Interface(address(feed)), USD_FEE, 365 days))
        );
        registry = RegistryV3(address(v1));
        registry.grantRole(registry.TREASURER_ROLE(), treasurer);

        actors.push(address(0xA11CE));
        actors.push(address(0xB0B));
        actors.push(address(0xCA401));
    }

    function actorCount() external view returns (uint256) {
        return actors.length;
    }

    // Alta pagada en ETH, con hasta 1 ETH de más para que se pruebe la devolución. Se intenta
    // también cuando el registro debe rechazarla: el `assert` falla si acepta lo que no debe o
    // rechaza lo que debe aceptar.
    function register(uint256 actorSeed, uint256 overpay) external {
        address actor = _actor(actorSeed);
        bool allowed = _canRegister(actor, 1);
        uint256 fee = registry.registrationFee();
        uint256 value = fee + bound(overpay, 0, 1 ether);
        _fund(actor, value);
        vm.prank(actor);
        bool accepted;
        try registry.register{value: value}("item") {
            accepted = true;
        } catch {}
        assert(accepted == allowed);
        if (accepted) ghostFeesPaid += fee;
    }

    // Lote de 1 a MAX_BATCH altas, con la tasa de todas y algo de más.
    function registerBatch(uint256 actorSeed, uint256 amount, uint256 overpay) external {
        // TODO (semana 24): como `register`, con `amount` acotado entre 1 y MAX_BATCH, una etiqueta
        //   por alta y la tasa de todas. ¿Cuándo debe rechazar el lote el registro?
    }

    // Alta pagada con POINTS_PRICE puntos: sin puntos suficientes, el registro la rechaza.
    function registerWithPoints(uint256 actorSeed) external {
        // TODO (semana 24): la cuenta aprueba POINTS_PRICE al registro y llama a registerWithPoints.
        //   Debe aceptarse si hay sitio y la cuenta tiene los puntos. Con `startPrank`, el
        //   `stopPrank` va antes del `assert`. Cuenta las altas con puntos en su variable fantasma.
    }

    // Retira un recurso activo, desde la cuenta que tiene su certificado.
    function retire(uint256 idSeed) external {
        // TODO (semana 24): elige un id entre 1 y `count` con `bound`. Si está activo, lo retira
        //   quien tiene su certificado. Cuenta la retirada.
    }

    // Pasa un certificado a otra cuenta: desde entonces, retira el recurso la nueva.
    function transferCertificate(uint256 toSeed, uint256 idSeed) external {
        // TODO (semana 24): elige un id como en `retire` y pasa su certificado de quien lo tiene a
        //   una de las tres cuentas.
    }

    // El tesorero se lleva todas las tasas.
    function withdrawFees() external {
        uint256 balance = address(registry).balance;
        if (balance == 0) return;
        vm.prank(treasurer);
        registry.withdrawFees(payable(treasurer));
        ghostFeesWithdrawn += balance;
    }

    // El precio de ETH cambia entre 1000 y 5000 dólares: cambia la tasa en ETH de cada alta.
    function setPrice(uint256 price) external {
        feed.updateAnswer(int256(bound(price, 1000e8, 5000e8)));
    }

    // Da `value` a la cuenta y también al handler. Con vm.prank, forge paga el `value` desde la
    // cuenta del prank; Medusa, desde quien llama de verdad, el handler.
    function _fund(address actor, uint256 value) internal {
        vm.deal(actor, value);
        vm.deal(address(this), value);
    }

    function _actor(uint256 seed) internal view returns (address) {
        return actors[seed % actors.length];
    }

    // Las altas que el registro aceptaría: hay sitio y la cuenta no llega a su máximo.
    function _canRegister(address actor, uint256 amount) internal view returns (bool) {
        return registry.activeCount() + amount <= registry.capacity()
            && registry.idsOf(actor).length + amount <= registry.maxPerAccount();
    }
}
