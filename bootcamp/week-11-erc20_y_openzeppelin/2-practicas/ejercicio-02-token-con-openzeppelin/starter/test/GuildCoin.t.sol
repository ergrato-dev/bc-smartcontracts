// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {ERC20Capped} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import {GuildCoin} from "../src/GuildCoin.sol";
import {Owned} from "../src/Owned.sol";

contract GuildCoinTest is Test {
    GuildCoin coin;
    address guild = makeAddr("guild");
    address alice = makeAddr("alice");
    address shop = makeAddr("shop");

    function setUp() public {
        vm.prank(guild);
        coin = new GuildCoin(1000 ether);
    }

    function test_Step1_Metadata() public view {
        assertEq(coin.name(), "Guild Coin");
        assertEq(coin.symbol(), "GLD");
        assertEq(coin.decimals(), 18);
        assertEq(coin.cap(), 1_000_000 ether);
        assertEq(coin.totalSupply(), 1000 ether);
        assertEq(coin.balanceOf(guild), 1000 ether);
    }

    function test_Step2_OwnerMints() public {
        vm.prank(guild);
        coin.mint(alice, 50 ether);
        assertEq(coin.balanceOf(alice), 50 ether);
        assertEq(coin.totalSupply(), 1050 ether);
    }

    function test_Step2_RevertWhen_StrangerMints() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Owned.NotOwner.selector, alice));
        coin.mint(alice, 50 ether);
    }

    function test_Step3_RevertWhen_SentToTheCoin() public {
        vm.prank(guild);
        vm.expectRevert(GuildCoin.SelfTransfer.selector);
        coin.transfer(address(coin), 1 ether);
    }

    function test_Inherited_RevertWhen_CapExceeded() public {
        vm.prank(guild);
        vm.expectRevert(abi.encodeWithSelector(ERC20Capped.ERC20ExceededCap.selector, 1_000_001 ether, 1_000_000 ether));
        coin.mint(alice, 999_001 ether);
    }

    function test_Inherited_BurnLowersSupply() public {
        vm.prank(guild);
        coin.burn(400 ether);
        assertEq(coin.totalSupply(), 600 ether);
    }

    function test_Inherited_BurnFromNeedsAllowance() public {
        vm.prank(shop);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, shop, 0, 10 ether));
        coin.burnFrom(guild, 10 ether);

        vm.prank(guild);
        coin.approve(shop, 10 ether);
        vm.prank(shop);
        coin.burnFrom(guild, 10 ether);
        assertEq(coin.balanceOf(guild), 990 ether);
        assertEq(coin.allowance(guild, shop), 0);
    }

    function test_Inherited_RevertWhen_TransferToZero() public {
        vm.prank(guild);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InvalidReceiver.selector, address(0)));
        coin.transfer(address(0), 1 ether);
    }
}
