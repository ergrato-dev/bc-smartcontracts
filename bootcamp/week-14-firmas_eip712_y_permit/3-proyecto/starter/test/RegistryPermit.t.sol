// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IERC5267} from "@openzeppelin/contracts/interfaces/IERC5267.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {Registry} from "../src/Registry.sol";
import {LoyaltyToken} from "../src/LoyaltyToken.sol";

// ¿Qué? Gastar puntos con un permit ERC-2612: la firma sustituye a la transacción `approve`.
// ¿Para qué? Comprobar que el token acepta permits de su dominio, que el registro los usa en
//   una sola transacción y que un permit enviado antes por otro no bloquea el alta.
// ¿Impacto? No los modifiques: son el contrato de esta capa.
contract RegistryPermitTest is Test {
    bytes32 constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    Registry registry;
    LoyaltyToken loyalty;
    // El mismo token visto como ERC-2612: así el test compila antes de que añadas ERC20Permit.
    IERC20Permit permitToken;
    uint256 fee;
    uint256 price;
    address alice;
    uint256 aliceKey;
    address mallory = makeAddr("mallory");
    uint256 deadline;

    function setUp() public {
        (alice, aliceKey) = makeAddrAndKey("alice");
        registry = new Registry(10);
        loyalty = registry.LOYALTY();
        permitToken = IERC20Permit(address(loyalty));
        registry.setHook(address(loyalty));
        fee = registry.REGISTRATION_FEE();
        price = registry.POINTS_PRICE();
        deadline = block.timestamp + 1 hours;
        vm.deal(alice, 1 ether);
        // Tres altas pagando ETH: 30 puntos, lo justo para una con puntos.
        string[] memory labels = new string[](3);
        labels[0] = "a";
        labels[1] = "b";
        labels[2] = "c";
        vm.prank(alice);
        registry.registerBatch{value: 3 * fee}(labels);
    }

    function _permit(uint256 key, address owner) internal view returns (uint8, bytes32, bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(PERMIT_TYPEHASH, owner, address(registry), price, permitToken.nonces(owner), deadline)
        );
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", permitToken.DOMAIN_SEPARATOR(), structHash));
        return vm.sign(key, digest);
    }

    function test_TokenDomainIsTheTokenName() public view {
        (, string memory name, string memory version,, address verifyingContract,,) =
            IERC5267(address(loyalty)).eip712Domain();
        assertEq(name, loyalty.name());
        assertEq(version, "1");
        assertEq(verifyingContract, address(loyalty));
        assertEq(permitToken.nonces(alice), 0);
    }

    function test_PermitSetsAllowance() public {
        (uint8 v, bytes32 r, bytes32 s) = _permit(aliceKey, alice);
        vm.prank(mallory);
        permitToken.permit(alice, address(registry), price, deadline, v, r, s);
        assertEq(loyalty.allowance(alice, address(registry)), price);
        assertEq(permitToken.nonces(alice), 1);
    }

    function test_RegisterWithPermitInOneTransaction() public {
        (uint8 v, bytes32 r, bytes32 s) = _permit(aliceKey, alice);
        vm.prank(alice);
        uint256 id = registry.registerWithPermit("free", deadline, v, r, s);
        assertEq(id, 4);
        assertEq(registry.getItem(4).registrant, alice);
        // Gastó 30 y el alta le dio 10 nuevos.
        assertEq(loyalty.balanceOf(alice), loyalty.REWARD());
        assertEq(loyalty.allowance(alice, address(registry)), 0);
        assertEq(permitToken.nonces(alice), 1);
    }

    function test_FrontRunPermitDoesNotBlockTheRegistration() public {
        (uint8 v, bytes32 r, bytes32 s) = _permit(aliceKey, alice);
        vm.prank(mallory);
        permitToken.permit(alice, address(registry), price, deadline, v, r, s);
        vm.prank(alice);
        registry.registerWithPermit("free", deadline, v, r, s);
        assertEq(registry.count(), 4);
    }

    // El permit es de alice: si lo envía mallory, el registro quema puntos de mallory, que no
    // dio allowance. Ignorar el fallo del permit no regala nada.
    function test_RevertWhen_OtherSendsAlicesPermit() public {
        (uint8 v, bytes32 r, bytes32 s) = _permit(aliceKey, alice);
        vm.prank(mallory);
        vm.expectRevert(
            abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, address(registry), 0, price)
        );
        registry.registerWithPermit("free", deadline, v, r, s);
        assertEq(loyalty.allowance(alice, address(registry)), 0);
    }

    function test_RevertWhen_PermitExpired() public {
        (uint8 v, bytes32 r, bytes32 s) = _permit(aliceKey, alice);
        vm.warp(deadline + 1);
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, address(registry), 0, price)
        );
        registry.registerWithPermit("free", deadline, v, r, s);
    }

    function test_RevertWhen_RegisterWithPermitWhilePaused() public {
        registry.grantRole(registry.PAUSER_ROLE(), address(this));
        registry.pause();
        (uint8 v, bytes32 r, bytes32 s) = _permit(aliceKey, alice);
        vm.prank(alice);
        vm.expectRevert(Pausable.EnforcedPause.selector);
        registry.registerWithPermit("free", deadline, v, r, s);
    }
}
