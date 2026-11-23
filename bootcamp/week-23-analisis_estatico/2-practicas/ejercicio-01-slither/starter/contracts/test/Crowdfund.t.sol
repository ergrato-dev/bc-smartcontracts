// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Crowdfund} from "../src/Crowdfund.sol";
import {Token, FalseToken, RefundAttacker, Phisher} from "./helpers/Helpers.sol";

contract CrowdfundTest is Test {
    Token internal token;
    Crowdfund internal crowdfund;
    address internal owner = makeAddr("owner");
    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");

    function setUp() public {
        token = new Token();
        vm.prank(owner);
        crowdfund = new Crowdfund(IERC20(address(token)), 10 ether, 7 days);
        token.mint(address(crowdfund), 10 ether * crowdfund.REWARD_PER_WEI());
        vm.deal(alice, 20 ether);
        vm.deal(bob, 20 ether);
    }

    function test_ReachGoalAndWithdraw() public {
        vm.prank(alice);
        crowdfund.contribute{value: 6 ether}();
        vm.prank(bob);
        crowdfund.contribute{value: 4 ether}();
        assertTrue(crowdfund.goalReached());

        vm.prank(owner);
        crowdfund.withdraw();
        assertEq(owner.balance, 10 ether);

        vm.prank(alice);
        crowdfund.claimReward();
        assertEq(token.balanceOf(alice), 600 ether);
    }

    function test_Paso1_RefundIsNotReentrant() public {
        RefundAttacker attacker = new RefundAttacker(crowdfund);
        vm.prank(alice);
        crowdfund.contribute{value: 3 ether}();
        attacker.contribute{value: 1 ether}();
        vm.warp(block.timestamp + 7 days);

        attacker.attack();

        assertEq(address(attacker).balance, 1 ether, "the attacker only gets its own ether back");
        assertEq(address(crowdfund).balance, 3 ether, "alice's ether stays in the campaign");
    }

    function test_Paso2_RevertWhen_RewardTransferFails() public {
        FalseToken bad = new FalseToken();
        Crowdfund campaign = new Crowdfund(IERC20(address(bad)), 1 ether, 7 days);
        vm.prank(alice);
        campaign.contribute{value: 1 ether}();

        vm.expectRevert(abi.encodeWithSelector(SafeERC20.SafeERC20FailedOperation.selector, address(bad)));
        vm.prank(alice);
        campaign.claimReward();
    }

    function test_Paso3_GoalReachedWhenOvershooting() public {
        vm.prank(alice);
        crowdfund.contribute{value: 11 ether}();
        assertTrue(crowdfund.goalReached());
    }

    function test_Paso4_RevertWhen_OwnerIsPhished() public {
        Phisher phisher = new Phisher();
        vm.expectRevert(Crowdfund.NotOwner.selector);
        vm.prank(owner, owner);
        phisher.claimGift(crowdfund);
    }

    function test_Paso5_RevertWhen_NewOwnerIsZero() public {
        vm.expectRevert(Crowdfund.ZeroAddress.selector);
        vm.prank(owner, owner);
        crowdfund.setOwner(address(0));
    }
}
