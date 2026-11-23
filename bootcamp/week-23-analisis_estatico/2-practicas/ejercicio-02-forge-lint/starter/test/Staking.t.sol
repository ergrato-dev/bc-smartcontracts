// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {Staking} from "../src/Staking.sol";
import {Token} from "../src/Token.sol";

/// @notice Una cuenta que no acepta ETH: un contrato sin `receive`.
contract NoReceive {
    function stake(Staking staking, Token token, uint256 amount) external {
        token.approve(address(staking), amount);
        staking.stake(amount);
    }

    function claim(Staking staking) external {
        staking.claim();
    }
}

contract StakingTest is Test {
    Token internal token;
    Staking internal staking;
    address internal alice = makeAddr("alice");

    function setUp() public {
        token = new Token();
        staking = new Staking(IERC20(address(token)));
        vm.deal(address(staking), 1000 ether);
        token.mint(alice, 100 ether);
        vm.prank(alice);
        token.approve(address(staking), type(uint256).max);
    }

    function test_Paso1_RevertWhen_RewardIsRejected() public {
        NoReceive account = new NoReceive();
        token.mint(address(account), 100 ether);
        account.stake(staking, token, 100 ether);
        vm.warp(block.timestamp + 30 days);

        vm.expectRevert(Staking.TransferFailed.selector);
        account.claim(staking);
    }

    function test_Paso2_RewardAfterThirtyDays() public {
        vm.prank(alice);
        staking.stake(100 ether);
        vm.warp(block.timestamp + 30 days);

        // 100 tokens al 10 % anual durante 30 días: 10 ETH × 30 / 365.
        assertEq(staking.earned(alice), 0.821917808219178082 ether);
        vm.prank(alice);
        staking.claim();
        assertEq(alice.balance, 0.821917808219178082 ether);
    }

    function test_Paso3_RevertWhen_AmountDoesNotFit() public {
        uint256 huge = uint256(type(uint96).max) + 1;
        token.mint(alice, huge);

        vm.expectRevert(abi.encodeWithSelector(SafeCast.SafeCastOverflowedUintDowncast.selector, 96, huge));
        vm.prank(alice);
        staking.stake(huge);
    }

    function test_Paso4_UnstakePaysReward() public {
        vm.prank(alice);
        staking.stake(100 ether);
        vm.warp(block.timestamp + 365 days);

        vm.prank(alice);
        staking.unstake();
        assertEq(token.balanceOf(alice), 100 ether);
        assertEq(alice.balance, 10 ether);
    }
}
