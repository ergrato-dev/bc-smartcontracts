// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MultiSig} from "../src/MultiSig.sol";
import {Config} from "./Config.sol";

contract MultiSigTest is Test {
    MultiSig wallet;
    Config config;
    address ana = makeAddr("ana");
    address beto = makeAddr("beto");
    address carla = makeAddr("carla");
    address stranger = makeAddr("stranger");

    function setUp() public {
        address[] memory list = new address[](3);
        (list[0], list[1], list[2]) = (ana, beto, carla);
        wallet = new MultiSig(list, 2);
        config = new Config(address(wallet));
    }

    function _list(address a, address b) internal pure returns (address[] memory list) {
        list = new address[](2);
        (list[0], list[1]) = (a, b);
    }

    // Ana propone `config.setFee(fee)`.
    function _submitFee(uint256 fee) internal returns (uint256) {
        vm.prank(ana);
        return wallet.submit(address(config), 0, abi.encodeCall(Config.setFee, (fee)));
    }

    function _confirm(address owner, uint256 id) internal {
        vm.prank(owner);
        wallet.confirm(id);
    }

    function test_Step1_OwnersAndThreshold() public view {
        assertTrue(wallet.isOwner(ana));
        assertTrue(wallet.isOwner(carla));
        assertFalse(wallet.isOwner(stranger));
        assertEq(wallet.owners(1), beto);
        assertEq(wallet.THRESHOLD(), 2);
    }

    function test_Step1_RevertWhen_ThresholdTooHigh() public {
        vm.expectRevert(abi.encodeWithSelector(MultiSig.InvalidThreshold.selector, 3, 2));
        new MultiSig(_list(ana, beto), 3);
    }

    function test_Step1_RevertWhen_ZeroThreshold() public {
        vm.expectRevert(abi.encodeWithSelector(MultiSig.InvalidThreshold.selector, 0, 2));
        new MultiSig(_list(ana, beto), 0);
    }

    function test_Step1_RevertWhen_DuplicateOwner() public {
        vm.expectRevert(abi.encodeWithSelector(MultiSig.InvalidOwner.selector, ana));
        new MultiSig(_list(ana, ana), 1);
    }

    function test_Step2_Submit() public {
        bytes memory data = abi.encodeCall(Config.setFee, (50));
        vm.expectEmit(address(wallet));
        emit MultiSig.Submitted(0, ana, address(config), 0, data);
        assertEq(_submitFee(50), 0);
        (address target, uint256 value, bytes memory stored, uint256 confirmations, bool executed) = wallet.proposals(0);
        assertEq(target, address(config));
        assertEq(value, 0);
        assertEq(stored, data);
        assertEq(confirmations, 0);
        assertFalse(executed);
    }

    function test_Step2_RevertWhen_StrangerSubmits() public {
        vm.prank(stranger);
        vm.expectRevert(abi.encodeWithSelector(MultiSig.NotOwner.selector, stranger));
        wallet.submit(address(config), 0, "");
    }

    function test_Step3_Confirm() public {
        uint256 id = _submitFee(50);
        vm.expectEmit(address(wallet));
        emit MultiSig.Confirmed(id, beto);
        _confirm(beto, id);
        assertTrue(wallet.confirmed(id, beto));
        (,,, uint256 confirmations,) = wallet.proposals(id);
        assertEq(confirmations, 1);
    }

    function test_Step3_RevertWhen_ConfirmTwice() public {
        uint256 id = _submitFee(50);
        _confirm(beto, id);
        vm.prank(beto);
        vm.expectRevert(abi.encodeWithSelector(MultiSig.AlreadyConfirmed.selector, id, beto));
        wallet.confirm(id);
    }

    function test_Step3_RevertWhen_ProposalNotFound() public {
        vm.prank(ana);
        vm.expectRevert(abi.encodeWithSelector(MultiSig.ProposalNotFound.selector, 9));
        wallet.confirm(9);
    }

    function test_Step4_ExecuteChangesConfig() public {
        uint256 id = _submitFee(50);
        _confirm(ana, id);
        _confirm(carla, id);
        vm.expectEmit(address(wallet));
        emit MultiSig.Executed(id);
        vm.prank(beto);
        wallet.execute(id);
        assertEq(config.fee(), 50);
        (,,,, bool executed) = wallet.proposals(id);
        assertTrue(executed);
    }

    function test_Step4_RevertWhen_NotEnoughConfirmations() public {
        uint256 id = _submitFee(50);
        _confirm(ana, id);
        vm.prank(ana);
        vm.expectRevert(abi.encodeWithSelector(MultiSig.NotEnoughConfirmations.selector, id, 1, 2));
        wallet.execute(id);
    }

    function test_Step4_RevertWhen_ExecuteTwice() public {
        uint256 id = _submitFee(50);
        _confirm(ana, id);
        _confirm(beto, id);
        vm.prank(ana);
        wallet.execute(id);
        vm.prank(ana);
        vm.expectRevert(abi.encodeWithSelector(MultiSig.AlreadyExecuted.selector, id));
        wallet.execute(id);
    }

    function test_Step4_SendsEther() public {
        vm.deal(address(wallet), 1 ether);
        vm.prank(ana);
        uint256 id = wallet.submit(stranger, 0.4 ether, "");
        _confirm(ana, id);
        _confirm(beto, id);
        vm.prank(carla);
        wallet.execute(id);
        assertEq(stranger.balance, 0.4 ether);
        assertEq(address(wallet).balance, 0.6 ether);
    }

    function test_Step4_RevertWhen_CallFails() public {
        Config foreign = new Config(stranger);
        vm.prank(ana);
        uint256 id = wallet.submit(address(foreign), 0, abi.encodeCall(Config.setFee, (1)));
        _confirm(ana, id);
        _confirm(beto, id);
        bytes memory reason = abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(wallet));
        vm.prank(ana);
        vm.expectRevert(abi.encodeWithSelector(MultiSig.CallFailed.selector, id, reason));
        wallet.execute(id);
    }
}
