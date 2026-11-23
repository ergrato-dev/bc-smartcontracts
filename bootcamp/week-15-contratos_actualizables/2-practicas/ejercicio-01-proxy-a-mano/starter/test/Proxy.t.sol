// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Errors} from "@openzeppelin/contracts/utils/Errors.sol";
import {CounterV1, CounterV2} from "../src/Counter.sol";
import {NaiveProxy} from "../src/NaiveProxy.sol";
import {Proxy} from "../src/Proxy.sol";

contract ProxyTest is Test {
    bytes32 constant IMPLEMENTATION_SLOT = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
    bytes32 constant ADMIN_SLOT = bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1);

    event Upgraded(address indexed implementation);
    event Incremented(address indexed by, uint256 count);

    CounterV1 v1;
    CounterV2 v2;
    Proxy proxy;
    CounterV1 counter; // el proxy, visto como un CounterV1
    address alice = makeAddr("alice");

    function setUp() public {
        v1 = new CounterV1();
        v2 = new CounterV2();
        proxy = new Proxy(address(v1));
        counter = CounterV1(address(proxy));
    }

    // --- Dado ---

    function test_Given_NaiveProxyBreaksOnFirstWrite() public {
        NaiveProxy naive = new NaiveProxy(address(v1));
        CounterV1(address(naive)).increment();
        // `count++` sumó 1 al slot 0, que era la dirección de la implementación.
        address broken = address(uint160(address(v1)) + 1);
        assertEq(naive.implementation(), broken);
        vm.expectRevert(abi.encodeWithSelector(Address.AddressEmptyCode.selector, broken));
        CounterV1(address(naive)).count();
    }

    function test_Given_AdminIsTheDeployer() public view {
        assertEq(address(uint160(uint256(vm.load(address(proxy), ADMIN_SLOT)))), address(this));
    }

    function test_Given_SlotZeroIsFree() public view {
        assertEq(vm.load(address(proxy), 0), bytes32(0));
    }

    // --- Paso 1: los slots de EIP-1967 ---

    function test_Step1_ImplementationInEip1967Slot() public view {
        assertEq(address(uint160(uint256(vm.load(address(proxy), IMPLEMENTATION_SLOT)))), address(v1));
    }

    // --- Paso 2: reenviar con delegatecall ---

    function test_Step2_StateLivesInTheProxy() public {
        counter.increment();
        counter.increment();
        assertEq(counter.count(), 2);
        assertEq(vm.load(address(proxy), 0), bytes32(uint256(2)));
        assertEq(v1.count(), 0);
    }

    function test_Step2_MsgSenderIsTheCaller() public {
        vm.expectEmit(address(proxy));
        emit Incremented(alice, 1);
        vm.prank(alice);
        counter.increment();
    }

    function test_Step2_RevertWhen_FunctionIsNotInImplementation() public {
        vm.expectRevert(Errors.FailedCall.selector);
        CounterV2(address(proxy)).decrement();
    }

    // --- Paso 3: actualizar ---

    function test_Step3_UpgradeKeepsTheState() public {
        counter.increment();
        counter.increment();
        counter.increment();
        proxy.upgradeTo(address(v2));
        CounterV2 upgraded = CounterV2(address(proxy));
        assertEq(upgraded.version(), 2);
        assertEq(upgraded.count(), 3);
        upgraded.decrement();
        assertEq(upgraded.count(), 2);
        assertEq(address(uint160(uint256(vm.load(address(proxy), IMPLEMENTATION_SLOT)))), address(v2));
    }

    function test_Step3_EmitsUpgraded() public {
        vm.expectEmit(address(proxy));
        emit Upgraded(address(v2));
        proxy.upgradeTo(address(v2));
    }

    function test_Step3_BubblesTheImplementationError() public {
        proxy.upgradeTo(address(v2));
        vm.expectRevert(CounterV1.NothingToDecrement.selector);
        CounterV2(address(proxy)).decrement();
    }

    function test_Step3_RevertWhen_NotAdmin() public {
        vm.expectRevert(abi.encodeWithSelector(Proxy.NotAdmin.selector, alice));
        vm.prank(alice);
        proxy.upgradeTo(address(v2));
    }

    function test_Step3_RevertWhen_NotAContract() public {
        vm.expectRevert(abi.encodeWithSelector(Proxy.NotAContract.selector, alice));
        proxy.upgradeTo(alice);
    }
}
