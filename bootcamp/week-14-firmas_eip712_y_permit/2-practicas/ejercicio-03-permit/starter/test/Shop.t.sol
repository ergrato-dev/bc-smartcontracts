// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {PointsToken} from "../src/PointsToken.sol";
import {Shop} from "../src/Shop.sol";

contract ShopTest is Test {
    bytes32 constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    PointsToken token;
    Shop shop;
    address buyer;
    uint256 buyerKey;
    uint256 malloryKey;
    address mallory;
    uint256 price;
    uint256 deadline;

    function setUp() public {
        (buyer, buyerKey) = makeAddrAndKey("buyer");
        (mallory, malloryKey) = makeAddrAndKey("mallory");
        token = new PointsToken(1000 ether);
        shop = new Shop(token);
        price = shop.PRICE();
        deadline = block.timestamp + 1 hours;
        token.transfer(buyer, 200 ether);
    }

    // Firma un Permit de `owner` para la tienda por `value`, con el nonce actual de `owner`.
    function _permit(uint256 key, address owner, uint256 value) internal view returns (uint8, bytes32, bytes32) {
        bytes32 structHash =
            keccak256(abi.encode(PERMIT_TYPEHASH, owner, address(shop), value, token.nonces(owner), deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", token.DOMAIN_SEPARATOR(), structHash));
        return vm.sign(key, digest);
    }

    function _insufficient(uint256 allowance) internal view returns (bytes memory) {
        return abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, address(shop), allowance, price);
    }

    function test_Inherited_PermitSetsAllowance() public {
        (uint8 v, bytes32 r, bytes32 s) = _permit(buyerKey, buyer, price);
        vm.prank(mallory);
        token.permit(buyer, address(shop), price, deadline, v, r, s);
        assertEq(token.allowance(buyer, address(shop)), price);
        assertEq(token.nonces(buyer), 1);
    }

    function test_Inherited_RevertWhen_PermitSignedByOther() public {
        (uint8 v, bytes32 r, bytes32 s) = _permit(malloryKey, buyer, price);
        vm.expectRevert(abi.encodeWithSelector(ERC20Permit.ERC2612InvalidSigner.selector, mallory, buyer));
        token.permit(buyer, address(shop), price, deadline, v, r, s);
    }

    function test_Step1_BuyAfterApprove() public {
        vm.startPrank(buyer);
        token.approve(address(shop), price);
        vm.expectEmit(address(shop));
        emit Shop.Purchased(buyer, price);
        shop.buy();
        vm.stopPrank();
        assertEq(shop.purchases(buyer), 1);
        assertEq(token.balanceOf(address(shop)), price);
        assertEq(token.allowance(buyer, address(shop)), 0);
    }

    function test_Step1_RevertWhen_NoAllowance() public {
        vm.prank(buyer);
        vm.expectRevert(_insufficient(0));
        shop.buy();
    }

    function test_Step2_BuyWithPermitInOneTransaction() public {
        (uint8 v, bytes32 r, bytes32 s) = _permit(buyerKey, buyer, price);
        vm.prank(buyer);
        shop.buyWithPermit(deadline, v, r, s);
        assertEq(shop.purchases(buyer), 1);
        assertEq(token.balanceOf(buyer), 200 ether - price);
        assertEq(token.nonces(buyer), 1);
    }

    // Mallory ve la firma en el mempool y la envía antes al token. Sin el try, la compra de
    // buyer revertiría por un nonce ya gastado; con el try, usa la allowance que dejó Mallory.
    function test_Step2_FrontRunPermitDoesNotBlockTheBuy() public {
        (uint8 v, bytes32 r, bytes32 s) = _permit(buyerKey, buyer, price);
        vm.prank(mallory);
        token.permit(buyer, address(shop), price, deadline, v, r, s);
        vm.prank(buyer);
        shop.buyWithPermit(deadline, v, r, s);
        assertEq(shop.purchases(buyer), 1);
    }

    // Ignorar el fallo del permit no regala nada: sin allowance, el cobro revierte.
    function test_Step2_RevertWhen_PermitIsForged() public {
        (uint8 v, bytes32 r, bytes32 s) = _permit(malloryKey, buyer, price);
        vm.prank(buyer);
        vm.expectRevert(_insufficient(0));
        shop.buyWithPermit(deadline, v, r, s);
    }

    function test_Step2_RevertWhen_PermitIsReplayed() public {
        (uint8 v, bytes32 r, bytes32 s) = _permit(buyerKey, buyer, price);
        vm.startPrank(buyer);
        shop.buyWithPermit(deadline, v, r, s);
        vm.expectRevert(_insufficient(0));
        shop.buyWithPermit(deadline, v, r, s);
        vm.stopPrank();
    }

    function test_Step2_RevertWhen_PermitExpired() public {
        (uint8 v, bytes32 r, bytes32 s) = _permit(buyerKey, buyer, price);
        vm.warp(deadline + 1);
        vm.prank(buyer);
        vm.expectRevert(_insufficient(0));
        shop.buyWithPermit(deadline, v, r, s);
    }

    // El permit es para buyer: Mallory no puede usarlo para comprar a su nombre.
    function test_Step2_RevertWhen_OtherSendsBuyersPermit() public {
        (uint8 v, bytes32 r, bytes32 s) = _permit(buyerKey, buyer, price);
        vm.prank(mallory);
        vm.expectRevert(_insufficient(0));
        shop.buyWithPermit(deadline, v, r, s);
        assertEq(token.allowance(buyer, address(shop)), 0);
    }
}
