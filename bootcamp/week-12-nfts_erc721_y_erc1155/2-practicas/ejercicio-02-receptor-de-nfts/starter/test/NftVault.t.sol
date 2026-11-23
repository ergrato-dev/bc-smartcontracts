// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {NftVault} from "../src/NftVault.sol";
import {Owned} from "../src/Owned.sol";
import {Collection} from "./Collection.sol";

contract NftVaultTest is Test {
    Collection art;
    NftVault vault;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        art = new Collection();
        vault = new NftVault(IERC721(address(art)));
        art.mint(alice, 7);
    }

    function _deposit() internal {
        vm.prank(alice);
        art.safeTransferFrom(alice, address(vault), 7);
    }

    function test_Step1_SafeDepositRecordsDepositor() public {
        _deposit();
        assertEq(art.ownerOf(7), address(vault));
        assertEq(vault.depositorOf(7), alice);
    }

    // Bob mueve el NFT de alice como operador: el depósito es de alice, no de bob.
    function test_Step1_OperatorDepositCreditsOwner() public {
        vm.prank(alice);
        art.setApprovalForAll(bob, true);
        vm.prank(bob);
        art.safeTransferFrom(alice, address(vault), 7);
        assertEq(vault.depositorOf(7), alice);
    }

    function test_Step1_RevertWhen_FakeCall() public {
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(NftVault.WrongCollection.selector, bob));
        vault.onERC721Received(bob, bob, 7, "");
    }

    function test_Step1_RevertWhen_OtherCollection() public {
        Collection other = new Collection();
        other.mint(alice, 1);
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(NftVault.WrongCollection.selector, address(other)));
        other.safeTransferFrom(alice, address(vault), 1);
    }

    function test_Step2_Withdraw() public {
        _deposit();
        vm.prank(alice);
        vault.withdraw(7);
        assertEq(art.ownerOf(7), alice);
        assertEq(vault.depositorOf(7), address(0));
    }

    function test_Step2_RevertWhen_NotDepositor() public {
        _deposit();
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(NftVault.NotDepositor.selector, bob, 7));
        vault.withdraw(7);
    }

    // Con `transferFrom` el NFT llega sin aviso: nadie lo apuntó y nadie lo puede retirar.
    function test_Step3_RescueStuck() public {
        vm.prank(alice);
        art.transferFrom(alice, address(vault), 7);
        assertEq(vault.depositorOf(7), address(0));
        vault.rescue(7, alice);
        assertEq(art.ownerOf(7), alice);
    }

    function test_Step3_RevertWhen_RescueDeposited() public {
        _deposit();
        vm.expectRevert(abi.encodeWithSelector(NftVault.NotStuck.selector, 7));
        vault.rescue(7, bob);
    }

    function test_Step3_RevertWhen_StrangerRescues() public {
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(Owned.NotOwner.selector, bob));
        vault.rescue(7, bob);
    }
}
