// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {IERC1155Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {Bakery} from "../src/Bakery.sol";
import {Owned} from "../src/Owned.sol";

// Un receptor a medias: sabe recibir envíos sueltos, pero no lotes.
contract SingleOnly {
    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }
}

contract BakeryTest is Test {
    Bakery bakery;
    address alice = makeAddr("alice");

    function setUp() public {
        bakery = new Bakery();
    }

    function _pair(uint256 a, uint256 b) internal pure returns (uint256[] memory list) {
        list = new uint256[](2);
        (list[0], list[1]) = (a, b);
    }

    // 10 de harina y 5 de azúcar para alice.
    function _supplyAlice() internal {
        bakery.supply(alice, _pair(0, 1), _pair(10, 5));
    }

    function test_Step1_SupplyBatch() public {
        _supplyAlice();
        assertEq(bakery.balanceOf(alice, bakery.FLOUR()), 10);
        assertEq(bakery.balanceOf(alice, bakery.SUGAR()), 5);
    }

    function test_Step1_RevertWhen_SupplyCake() public {
        vm.expectRevert(abi.encodeWithSelector(Bakery.NotAnIngredient.selector, 2));
        bakery.supply(alice, _pair(0, 2), _pair(10, 1));
    }

    function test_Step1_RevertWhen_StrangerSupplies() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Owned.NotOwner.selector, alice));
        bakery.supply(alice, _pair(0, 1), _pair(10, 5));
    }

    function test_Step1_RevertWhen_ReceiverWithoutBatch() public {
        SingleOnly single = new SingleOnly();
        vm.expectRevert(abi.encodeWithSelector(IERC1155Errors.ERC1155InvalidReceiver.selector, address(single)));
        bakery.supply(address(single), _pair(0, 1), _pair(10, 5));
    }

    function test_Step2_Bake() public {
        _supplyAlice();
        vm.prank(alice);
        bakery.bake(3);
        address[] memory accounts = new address[](3);
        (accounts[0], accounts[1], accounts[2]) = (alice, alice, alice);
        uint256[] memory ids = new uint256[](3);
        (ids[0], ids[1], ids[2]) = (0, 1, 2);
        uint256[] memory balances = bakery.balanceOfBatch(accounts, ids);
        assertEq(balances[0], 1);
        assertEq(balances[1], 2);
        assertEq(balances[2], 3);
    }

    function test_Step2_RevertWhen_NotEnoughFlour() public {
        _supplyAlice();
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IERC1155Errors.ERC1155InsufficientBalance.selector, alice, 10, 12, 0));
        bakery.bake(4);
    }

    function test_Step2_RevertWhen_Zero() public {
        vm.prank(alice);
        vm.expectRevert(Bakery.NothingToBake.selector);
        bakery.bake(0);
    }

    function test_Step3_Uri() public view {
        assertEq(bakery.uri(2), "https://bakery.example/items/2.json");
    }

    function test_Step3_RevertWhen_UnknownItem() public {
        vm.expectRevert(abi.encodeWithSelector(Bakery.UnknownItem.selector, 3));
        bakery.uri(3);
    }

    function test_Inherited_SupportsInterface() public view {
        assertTrue(bakery.supportsInterface(0xd9b67a26)); // IERC1155
        assertTrue(bakery.supportsInterface(0x0e89341c)); // IERC1155MetadataURI
    }
}
