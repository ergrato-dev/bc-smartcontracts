// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";
import {VaultFactory} from "../src/VaultFactory.sol";

// ¿Qué? Un test por paso del ejercicio. No los modifiques.
contract VaultFactoryTest is Test {
    VaultFactory factory;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    bytes32 constant SALT = keccak256("caja-1");

    function setUp() public {
        factory = new VaultFactory();
    }

    function test_Step1_Create() public {
        vm.startPrank(alice);
        Vault first = factory.create();
        Vault second = factory.create();
        vm.stopPrank();

        assertEq(first.OWNER(), alice);
        assertEq(address(first), vm.computeCreateAddress(address(factory), 1));
        assertEq(address(second), vm.computeCreateAddress(address(factory), 2));
    }

    function test_Step2_SaltOf() public view {
        assertEq(factory.saltOf(alice, SALT), keccak256(abi.encode(alice, SALT)));
        assertNotEq(factory.saltOf(alice, SALT), factory.saltOf(bob, SALT));
    }

    function test_Step3_Predict() public view {
        bytes32 initCodeHash = keccak256(bytes.concat(type(Vault).creationCode, abi.encode(alice)));
        address expected = vm.computeCreate2Address(factory.saltOf(alice, SALT), initCodeHash, address(factory));
        assertEq(factory.predict(alice, SALT), expected);
        assertNotEq(factory.predict(bob, SALT), expected);
    }

    function test_Step4_Create2() public {
        address predicted = factory.predict(alice, SALT);
        vm.prank(alice);
        Vault vault = factory.create2(SALT);
        assertEq(address(vault), predicted);
        assertEq(vault.OWNER(), alice);
    }

    function test_Step4_RevertWhen_SaltReused() public {
        address predicted = factory.predict(alice, SALT);
        vm.startPrank(alice);
        factory.create2(SALT);
        vm.expectRevert(abi.encodeWithSelector(VaultFactory.AlreadyDeployed.selector, predicted));
        factory.create2(SALT);
        vm.stopPrank();
    }

    function test_Step4_SameSaltOtherAccount() public {
        vm.prank(alice);
        Vault aliceVault = factory.create2(SALT);
        vm.prank(bob);
        Vault bobVault = factory.create2(SALT);
        assertNotEq(address(aliceVault), address(bobVault));
        assertEq(bobVault.OWNER(), bob);
    }

    function test_Step4_FundsArriveBeforeDeploy() public {
        address predicted = factory.predict(alice, SALT);
        vm.deal(predicted, 1 ether);
        assertEq(predicted.code.length, 0);

        vm.startPrank(alice);
        Vault vault = factory.create2(SALT);
        vault.withdraw();
        vm.stopPrank();
        assertEq(alice.balance, 1 ether);
    }
}
