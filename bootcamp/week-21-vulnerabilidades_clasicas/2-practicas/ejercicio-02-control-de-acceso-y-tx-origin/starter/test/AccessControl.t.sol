// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {OriginWallet} from "../src/OriginWallet.sol";
import {Wallet} from "../src/Wallet.sol";
import {Phisher, IWallet} from "../src/Phisher.sol";
import {Treasury} from "../src/Treasury.sol";

contract AccessControlTest is Test {
    address alice = makeAddr("alice");
    address mallory = makeAddr("mallory");

    function setUp() public {
        vm.deal(alice, 20 ether);
    }

    // Alice despliega una cartera con 10 ETH; Mallory, el cebo apuntando a ella.
    function _bait(address wallet) internal returns (Phisher phisher) {
        vm.prank(mallory);
        phisher = new Phisher(IWallet(wallet));
    }

    function test_Paso1_PhisherDrainsOriginWallet() public {
        vm.prank(alice);
        OriginWallet wallet = new OriginWallet{value: 10 ether}();
        Phisher phisher = _bait(address(wallet));
        // Alice firma la transacción (tx.origin) y llama al cebo (msg.sender).
        vm.prank(alice, alice);
        phisher.claimPrize();
        assertEq(mallory.balance, 10 ether);
        assertEq(address(wallet).balance, 0);
    }

    function test_Paso2_OwnerWithdraws() public {
        vm.prank(alice);
        Wallet wallet = new Wallet{value: 10 ether}();
        vm.prank(alice, alice);
        wallet.withdraw(alice, 4 ether);
        assertEq(alice.balance, 14 ether);
    }

    function test_Paso2_RevertWhen_PhisherCallsWallet() public {
        vm.prank(alice);
        Wallet wallet = new Wallet{value: 10 ether}();
        Phisher phisher = _bait(address(wallet));
        vm.prank(alice, alice);
        vm.expectRevert(abi.encodeWithSelector(Wallet.NotOwner.selector, address(phisher)));
        phisher.claimPrize();
        assertEq(address(wallet).balance, 10 ether);
    }

    // El proxy se despliega con `initialize` en el mismo paso: nadie puede adelantarse.
    function _treasury() internal returns (Treasury implementation, Treasury treasury) {
        implementation = new Treasury();
        bytes memory init = abi.encodeCall(Treasury.initialize, (alice));
        treasury = Treasury(payable(address(new ERC1967Proxy(address(implementation), init))));
        vm.deal(address(treasury), 5 ether);
    }

    function test_Paso3_RevertWhen_InitializeTwice() public {
        (, Treasury treasury) = _treasury();
        assertEq(treasury.owner(), alice);
        vm.prank(mallory);
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        treasury.initialize(mallory);
        assertEq(treasury.owner(), alice);
    }

    function test_Paso4_RevertWhen_InitializeImplementation() public {
        (Treasury implementation,) = _treasury();
        vm.prank(mallory);
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        implementation.initialize(mallory);
        assertEq(implementation.owner(), address(0));
    }

    function test_Paso5_OwnerSweeps() public {
        (, Treasury treasury) = _treasury();
        vm.expectEmit(address(treasury));
        emit Treasury.Swept(alice, 5 ether);
        vm.prank(alice);
        treasury.sweep(alice);
        assertEq(alice.balance, 25 ether);
    }

    function test_Paso5_RevertWhen_StrangerSweeps() public {
        (, Treasury treasury) = _treasury();
        vm.prank(mallory);
        vm.expectRevert(abi.encodeWithSelector(Treasury.NotOwner.selector, mallory));
        treasury.sweep(mallory);
        assertEq(address(treasury).balance, 5 ether);
    }
}
