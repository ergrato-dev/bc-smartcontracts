// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {ERC20Capped} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import {Registry} from "../src/Registry.sol";
import {IRegistry} from "../src/IRegistry.sol";
import {Openable} from "../src/Openable.sol";
import {LoyaltyToken} from "../src/LoyaltyToken.sol";

// ¿Qué? El token de fidelidad: quién lo emite, su tope y cómo se gasta en el registro.
// ¿Para qué? Comprobar la capa de la semana 11 sin repetir los tests de OpenZeppelin.
// ¿Impacto? No los modifiques: son el contrato de esta capa.
contract RegistryLoyaltyTest is Test {
    Registry registry;
    LoyaltyToken loyalty;
    uint256 fee;
    uint256 price;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        registry = new Registry(10);
        loyalty = registry.LOYALTY();
        registry.setHook(address(loyalty));
        fee = registry.REGISTRATION_FEE();
        price = registry.POINTS_PRICE();
        vm.deal(alice, 1 ether);
    }

    // Alice registra tres recursos pagando ETH: gana 30 tokens, lo justo para uno más.
    function _earnPoints() internal {
        vm.startPrank(alice);
        string[] memory labels = new string[](3);
        labels[0] = "a";
        labels[1] = "b";
        labels[2] = "c";
        registry.registerBatch{value: 3 * fee}(labels);
        vm.stopPrank();
    }

    function test_TokenIsDeployedByTheRegistry() public view {
        assertEq(loyalty.REGISTRY(), address(registry));
        assertEq(loyalty.decimals(), 18);
        assertEq(loyalty.totalSupply(), 0);
        assertEq(loyalty.cap(), loyalty.MAX_SUPPLY());
        assertGt(bytes(loyalty.name()).length, 0);
        assertGt(bytes(loyalty.symbol()).length, 0);
    }

    function test_RegisterMintsReward() public {
        vm.prank(alice);
        registry.register{value: fee}("north");
        assertEq(loyalty.balanceOf(alice), loyalty.REWARD());
        assertEq(loyalty.totalSupply(), loyalty.REWARD());
    }

    function test_PointsAreTransferable() public {
        _earnPoints();
        vm.prank(alice);
        loyalty.transfer(bob, 5 ether);
        assertEq(loyalty.balanceOf(bob), 5 ether);
    }

    function test_RegisterWithPoints() public {
        _earnPoints();
        vm.startPrank(alice);
        loyalty.approve(address(registry), price);
        uint256 id = registry.registerWithPoints("free");
        vm.stopPrank();

        assertEq(id, 4);
        assertEq(registry.getItem(4).registrant, alice);
        // Gastó 30 y el alta le dio 10 nuevos.
        assertEq(loyalty.balanceOf(alice), loyalty.REWARD());
        assertEq(loyalty.allowance(alice, address(registry)), 0);
        assertEq(address(registry).balance, 3 * fee);
    }

    function test_RegisterWithPointsBurnsTokens() public {
        _earnPoints();
        vm.startPrank(alice);
        loyalty.approve(address(registry), price);
        registry.registerWithPoints("free");
        vm.stopPrank();
        assertEq(loyalty.totalSupply(), 4 * loyalty.REWARD() - price);
    }

    function test_RevertWhen_PointsNotApproved() public {
        _earnPoints();
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, address(registry), 0, price)
        );
        registry.registerWithPoints("free");
    }

    function test_RevertWhen_NotEnoughPoints() public {
        vm.startPrank(bob);
        loyalty.approve(address(registry), price);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, bob, 0, price));
        registry.registerWithPoints("free");
        vm.stopPrank();
    }

    function test_RevertWhen_RegisterWithPointsWhileClosed() public {
        registry.setOpen(false);
        vm.prank(alice);
        vm.expectRevert(Openable.RegistryClosed.selector);
        registry.registerWithPoints("free");
    }

    function test_RevertWhen_RegisterWithPointsWhileFull() public {
        Registry small = new Registry(1);
        vm.prank(alice);
        small.register{value: fee}("only");
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IRegistry.RegistryFull.selector, 1));
        small.registerWithPoints("free");
    }

    function test_CapReachedDoesNotBlockRegistry() public {
        // Lleva el suministro justo al tope, como si ya se hubieran emitido todos los tokens.
        deal(address(loyalty), bob, loyalty.MAX_SUPPLY(), true);
        bytes memory reason = abi.encodeWithSelector(
            ERC20Capped.ERC20ExceededCap.selector, loyalty.MAX_SUPPLY() + loyalty.REWARD(), loyalty.MAX_SUPPLY()
        );
        vm.expectEmit(address(registry));
        emit Registry.HookFailed(1, reason);
        vm.prank(alice);
        registry.register{value: fee}("north");
        assertEq(registry.count(), 1);
        assertEq(loyalty.balanceOf(alice), 0);
    }
}
