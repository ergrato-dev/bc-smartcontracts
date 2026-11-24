// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/shared/mocks/MockV3Aggregator.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {Vouchers} from "../src/Vouchers.sol";
import {CrossChainAddress} from "../src/CrossChainAddress.sol";
import {L2PriceReader} from "../src/L2PriceReader.sol";

// ¿Qué? Dos cadenas en un solo EVM de pruebas: `vm.chainId` cambia `block.chainid`, y
//   `vm.snapshotState`/`vm.revertToState` deshacen un despliegue para repetirlo "en la otra".
contract MultiChainTest is Test {
    uint256 constant L1 = 1;
    uint256 constant L2 = 10;
    bytes32 constant SALT = keccak256("vouchers-v1");

    uint256 issuerKey = 0xA11CE;
    address issuer = vm.addr(issuerKey);
    address alice = makeAddr("alice");

    MockV3Aggregator sequencerFeed;
    MockV3Aggregator priceFeed;
    L2PriceReader reader;

    function setUp() public {
        vm.warp(1_800_000_000);
        // Un 0 en el feed de disponibilidad: secuenciador en marcha desde este instante.
        sequencerFeed = new MockV3Aggregator(0, 0);
        priceFeed = new MockV3Aggregator(8, 3000e8);
        reader =
            new L2PriceReader(AggregatorV3Interface(address(sequencerFeed)), AggregatorV3Interface(address(priceFeed)));
        vm.warp(block.timestamp + 2 hours);
        priceFeed.updateAnswer(3000e8);
    }

    // El digest EIP-712 tal como lo define el estándar, con la cadena dentro del dominio.
    function _sign(address vouchers, uint256 chainId, address to, uint256 amount, uint256 nonce)
        internal
        view
        returns (bytes memory)
    {
        bytes32 domain = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256("Vouchers"),
                keccak256("1"),
                chainId,
                vouchers
            )
        );
        bytes32 structHash =
            keccak256(abi.encode(keccak256("Voucher(address to,uint256 points,uint256 nonce)"), to, amount, nonce));
        (uint8 v, bytes32 r, bytes32 s) =
            vm.sign(issuerKey, keccak256(abi.encodePacked("\x19\x01", domain, structHash)));
        return abi.encodePacked(r, s, v);
    }

    function _initCode(address issuer_) internal pure returns (bytes memory) {
        return abi.encodePacked(type(Vouchers).creationCode, abi.encode(issuer_));
    }

    function test_Paso1_RedeemsOnItsChain() public {
        vm.chainId(L1);
        Vouchers vouchers = new Vouchers(issuer);
        vouchers.redeem(alice, 30, 1, _sign(address(vouchers), L1, alice, 30, 1));
        assertEq(vouchers.points(alice), 30, "Paso 1: el vale firmado para esta cadena vale");
    }

    function test_Paso1_RevertWhen_ReplayedAfterAChainSplit() public {
        vm.chainId(L1);
        Vouchers vouchers = new Vouchers(issuer);
        bytes memory signature = _sign(address(vouchers), L1, alice, 30, 1);
        // La cadena se divide y la copia cambia de chain id: el contrato y su storage son los mismos.
        vm.chainId(L1 + 1);
        vm.expectRevert(Vouchers.InvalidSignature.selector);
        vouchers.redeem(alice, 30, 1, signature);
    }

    function test_Paso1_RevertWhen_RedeemedTwice() public {
        vm.chainId(L1);
        Vouchers vouchers = new Vouchers(issuer);
        bytes memory signature = _sign(address(vouchers), L1, alice, 30, 1);
        vouchers.redeem(alice, 30, 1, signature);
        vm.expectRevert(abi.encodeWithSelector(Vouchers.AlreadyRedeemed.selector, 1));
        vouchers.redeem(alice, 30, 1, signature);
    }

    function test_Paso2_SameAddressOnTwoChains() public {
        bytes memory initCode = _initCode(issuer);
        uint256 beforeDeploy = vm.snapshotState();
        vm.chainId(L1);
        address onL1 = CrossChainAddress.deploy(SALT, initCode);
        vm.revertToState(beforeDeploy);
        vm.chainId(L2);
        address onL2 = CrossChainAddress.deploy(SALT, initCode);
        assertEq(onL1, onL2, "Paso 2: misma sal y mismo codigo, misma direccion");
        assertEq(onL2, CrossChainAddress.predict(SALT, initCode), "Paso 2: predict acierta");
    }

    function test_Paso2_OtherArgumentsOtherAddress() public view {
        address predicted = CrossChainAddress.predict(SALT, _initCode(issuer));
        assertNotEq(predicted, CrossChainAddress.predict(SALT, _initCode(alice)), "Paso 2: el constructor cuenta");
        assertNotEq(predicted, CrossChainAddress.predict(bytes32(0), _initCode(issuer)), "Paso 2: la sal cuenta");
    }

    function test_Paso2_RevertWhen_ReplayedOnTheTwinContract() public {
        bytes memory initCode = _initCode(issuer);
        address twin = CrossChainAddress.predict(SALT, initCode);
        bytes memory signedForL1 = _sign(twin, L1, alice, 30, 1);
        uint256 beforeDeploy = vm.snapshotState();
        vm.chainId(L1);
        CrossChainAddress.deploy(SALT, initCode);
        Vouchers(twin).redeem(alice, 30, 1, signedForL1);
        vm.revertToState(beforeDeploy);
        vm.chainId(L2);
        CrossChainAddress.deploy(SALT, initCode);
        // Misma dirección, mismo emisor y nonce sin usar en L2: solo el chain id lo para.
        vm.expectRevert(Vouchers.InvalidSignature.selector);
        Vouchers(twin).redeem(alice, 30, 1, signedForL1);
    }

    function test_Paso3_ReadsThePriceWhileUp() public view {
        assertEq(reader.ethUsd(), 3000e8);
    }

    function test_Paso3_RevertWhen_SequencerIsDown() public {
        sequencerFeed.updateAnswer(1);
        vm.expectRevert(L2PriceReader.SequencerDown.selector);
        reader.ethUsd();
    }

    function test_Paso4_RevertWhen_SequencerJustCameBack() public {
        sequencerFeed.updateAnswer(1);
        vm.warp(block.timestamp + 20 minutes);
        sequencerFeed.updateAnswer(0);
        uint256 upSince = block.timestamp;
        vm.warp(block.timestamp + 30 minutes);
        priceFeed.updateAnswer(3100e8);
        vm.expectRevert(abi.encodeWithSelector(L2PriceReader.GracePeriodNotOver.selector, upSince));
        reader.ethUsd();
    }

    function test_Paso4_RevertWhen_GracePeriodEndsThisSecond() public {
        sequencerFeed.updateAnswer(1);
        sequencerFeed.updateAnswer(0);
        uint256 upSince = block.timestamp;
        vm.warp(upSince + reader.GRACE_PERIOD());
        priceFeed.updateAnswer(3100e8);
        vm.expectRevert(abi.encodeWithSelector(L2PriceReader.GracePeriodNotOver.selector, upSince));
        reader.ethUsd();
    }

    function test_Paso4_ReadsAfterTheGracePeriod() public {
        sequencerFeed.updateAnswer(1);
        sequencerFeed.updateAnswer(0);
        vm.warp(block.timestamp + reader.GRACE_PERIOD() + 1);
        priceFeed.updateAnswer(3100e8);
        assertEq(reader.ethUsd(), 3100e8, "Paso 4: pasado el plazo, el precio vale");
    }
}
