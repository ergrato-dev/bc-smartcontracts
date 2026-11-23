// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Coupons} from "../src/Coupons.sol";

contract CouponsTest is Test {
    // Orden del grupo de la curva secp256k1: los `s` válidos van de 1 a N - 1.
    uint256 constant N = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;

    Coupons coupons;
    address issuer;
    uint256 issuerKey;
    address mallory;
    uint256 malloryKey;
    address alice = makeAddr("alice");
    address relayer = makeAddr("relayer");

    function setUp() public {
        (issuer, issuerKey) = makeAddrAndKey("issuer");
        (mallory, malloryKey) = makeAddrAndKey("mallory");
        coupons = new Coupons(issuer);
    }

    // Firma como lo hace `cast wallet sign`: prefijo EIP-191 sobre el hash del cupón.
    function _sign(uint256 key, bytes32 hash) internal pure returns (bytes memory) {
        bytes32 digest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(key, digest);
        return abi.encodePacked(r, s, v);
    }

    function _coupon(uint256 amount, uint256 id) internal view returns (bytes memory) {
        return _sign(issuerKey, coupons.couponHash(alice, amount, id));
    }

    function test_Step1_HashIsTheEncodedCoupon() public view {
        bytes32 expected = keccak256(abi.encode(address(coupons), block.chainid, alice, 50, 1));
        assertEq(coupons.couponHash(alice, 50, 1), expected);
    }

    function test_Step1_HashDependsOnContractAndChain() public {
        bytes32 here = coupons.couponHash(alice, 50, 1);
        Coupons other = new Coupons(issuer);
        assertNotEq(other.couponHash(alice, 50, 1), here);
        vm.chainId(1);
        assertNotEq(coupons.couponHash(alice, 50, 1), here);
    }

    function test_Step2_AnyoneRedeemsForAlice() public {
        bytes memory sig = _coupon(50, 1);
        vm.prank(relayer);
        coupons.redeem(alice, 50, 1, sig);
        assertEq(coupons.points(alice), 50);
        assertEq(coupons.points(relayer), 0);
    }

    function test_Step2_EmitsRedeemed() public {
        bytes memory sig = _coupon(50, 1);
        vm.expectEmit(address(coupons));
        emit Coupons.Redeemed(coupons.couponHash(alice, 50, 1), alice, 50);
        coupons.redeem(alice, 50, 1, sig);
    }

    function test_Step2_RevertWhen_SignedByOtherKey() public {
        bytes memory sig = _sign(malloryKey, coupons.couponHash(alice, 50, 1));
        vm.expectRevert(abi.encodeWithSelector(Coupons.InvalidSigner.selector, mallory));
        coupons.redeem(alice, 50, 1, sig);
    }

    // Cambiar un campo cambia el hash: ecrecover devuelve otra dirección, no un error.
    function test_Step2_RevertWhen_AmountIsChanged() public {
        bytes memory sig = _coupon(50, 1);
        vm.expectPartialRevert(Coupons.InvalidSigner.selector);
        coupons.redeem(alice, 5000, 1, sig);
    }

    function test_Step2_RevertWhen_SignatureIsNot65Bytes() public {
        vm.expectRevert(abi.encodeWithSelector(ECDSA.ECDSAInvalidSignatureLength.selector, 3));
        coupons.redeem(alice, 50, 1, hex"010203");
    }

    // La misma firma con `s` reflejado (N - s) y `v` cambiado también la acepta ecrecover.
    // ECDSA de OpenZeppelin la rechaza: solo vale la versión con `s` en la mitad baja.
    function test_Step2_RevertWhen_SignatureIsMalleated() public {
        bytes32 hash = coupons.couponHash(alice, 50, 1);
        bytes32 digest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(issuerKey, digest);
        bytes32 highS = bytes32(N - uint256(s));
        uint8 otherV = v == 27 ? 28 : 27;
        assertEq(ecrecover(digest, otherV, r, highS), issuer);
        vm.expectRevert(abi.encodeWithSelector(ECDSA.ECDSAInvalidSignatureS.selector, highS));
        coupons.redeem(alice, 50, 1, abi.encodePacked(r, highS, otherV));
    }

    function test_Step3_RevertWhen_RedeemedTwice() public {
        bytes memory sig = _coupon(50, 1);
        coupons.redeem(alice, 50, 1, sig);
        vm.expectRevert(abi.encodeWithSelector(Coupons.CouponUsed.selector, coupons.couponHash(alice, 50, 1)));
        coupons.redeem(alice, 50, 1, sig);
        assertEq(coupons.points(alice), 50);
    }

    function test_Step3_SameAmountWithNewIdIsANewCoupon() public {
        coupons.redeem(alice, 50, 1, _coupon(50, 1));
        coupons.redeem(alice, 50, 2, _coupon(50, 2));
        assertEq(coupons.points(alice), 100);
        assertTrue(coupons.used(coupons.couponHash(alice, 50, 2)));
    }

    function test_Step2_RevertWhen_ReplayedInOtherDeployment() public {
        bytes memory sig = _coupon(50, 1);
        coupons.redeem(alice, 50, 1, sig);
        Coupons other = new Coupons(issuer);
        vm.expectPartialRevert(Coupons.InvalidSigner.selector);
        other.redeem(alice, 50, 1, sig);
    }
}
