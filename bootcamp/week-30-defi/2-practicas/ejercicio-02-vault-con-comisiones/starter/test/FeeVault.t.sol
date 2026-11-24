// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {FeeVault} from "../src/FeeVault.sol";
import {Token} from "../src/Token.sol";

// ¿Qué? Los tests del ejercicio 02: tres de comportamiento, en verde desde el principio, y los de
//   cada paso, que miran lo que el estándar promete.
// ¿Para qué? Que una comisión o un tope no dejen `preview*` y `max*` diciendo algo distinto de lo
//   que hacen `deposit`, `withdraw` y `redeem`.
contract FeeVaultTest is Test {
    Token token;
    FeeVault vault;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address carol = makeAddr("carol");

    function setUp() public {
        token = new Token("Token", "TKN");
        vault = new FeeVault(token, 1000 ether);
        address[3] memory users = [alice, bob, carol];
        for (uint256 i = 0; i < users.length; i++) {
            token.mint(users[i], 1000 ether);
            vm.prank(users[i]);
            token.approve(address(vault), type(uint256).max);
        }
    }

    function _deposit(address who, uint256 assets) internal returns (uint256 shares) {
        vm.prank(who);
        shares = vault.deposit(assets, who);
    }

    function test_DepositMintsSharesWorthTheAssets() public {
        uint256 shares = _deposit(alice, 100 ether);
        assertEq(vault.balanceOf(alice), shares);
        assertEq(vault.convertToAssets(shares), 100 ether);
        assertEq(vault.totalAssets(), 100 ether);
    }

    function testFuzz_RoundTripNeverProfits(uint256 assets) public {
        assets = bound(assets, 1, 500 ether);
        uint256 shares = _deposit(alice, assets);
        vm.prank(alice);
        uint256 received = vault.redeem(shares, alice, alice);
        assertLe(received, assets);
    }

    function test_Paso1_DonationAttackDoesNotPay() public {
        // `carol` deposita 1 wei y regala 100 tokens al vault antes de que `alice` deposite.
        _deposit(carol, 1);
        vm.prank(carol);
        assertTrue(token.transfer(address(vault), 100 ether));

        uint256 shares = _deposit(alice, 100 ether);
        assertGe(vault.convertToAssets(shares), 99.9 ether, "alice pierde su deposito");
        // Y `carol` no recupera lo que regaló: el ataque le cuesta dinero.
        assertLt(vault.convertToAssets(vault.balanceOf(carol)), 100 ether);
    }

    function test_Paso2_RedeemChargesExitFee() public {
        uint256 shares = _deposit(alice, 101 ether);
        vm.prank(alice);
        uint256 received = vault.redeem(shares, alice, alice);
        // 100 para alice y el 1 % de 100 para el vault.
        assertEq(received, 100 ether);
        assertEq(vault.totalAssets(), 1 ether);
    }

    function test_Paso2_ExitFeeStaysWithHolders() public {
        uint256 aliceShares = _deposit(alice, 100 ether);
        uint256 bobShares = _deposit(bob, 100 ether);
        vm.prank(alice);
        vault.redeem(aliceShares, alice, alice);
        assertGt(vault.convertToAssets(bobShares), 100 ether);
    }

    function test_Paso3_WithdrawChargesExitFee() public {
        _deposit(alice, 100 ether);
        uint256 bobShares = _deposit(bob, 100 ether);
        vm.prank(alice);
        vault.withdraw(50 ether, alice, alice);
        assertEq(token.balanceOf(alice), 950 ether);
        // Alice recibe 50 justos y paga 0,5 más en shares: parte de eso es ahora de bob.
        assertGt(vault.convertToAssets(bobShares), 100 ether);
    }

    function testFuzz_WithdrawMaxBurnsEveryShare(uint256 assets) public {
        _deposit(bob, 100 ether);
        assets = bound(assets, 1 ether, 500 ether);
        _deposit(alice, assets);
        // `maxWithdraw` es lo que da `redeem` de todas tus shares: retirarlo cuesta todas, salvo
        // las que valen menos de 1 wei por el redondeo.
        uint256 max = vault.maxWithdraw(alice);
        vm.prank(alice);
        vault.withdraw(max, alice, alice);
        assertLe(vault.convertToAssets(vault.balanceOf(alice)), 1);
    }

    function test_Paso4_RevertWhen_DepositAboveCap() public {
        _deposit(alice, 900 ether);
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(ERC4626.ERC4626ExceededMaxDeposit.selector, bob, 200 ether, 100 ether));
        vault.deposit(200 ether, bob);
    }

    function test_Paso4_MaxMintMatchesTheCap() public {
        _deposit(alice, 900 ether);
        assertEq(vault.maxMint(bob), vault.previewDeposit(100 ether));
        uint256 max = vault.maxMint(bob);
        vm.prank(bob);
        vault.mint(max, bob);
        assertEq(vault.maxDeposit(bob), 0);
    }
}
