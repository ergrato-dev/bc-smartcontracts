// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {GuildPass} from "../src/GuildPass.sol";
import {Owned} from "../src/Owned.sol";

// Un contrato sin onERC721Received: no sabe recibir NFTs.
contract Locker {}

contract GuildPassTest is Test {
    GuildPass pass;
    address guild = makeAddr("guild");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        vm.prank(guild);
        pass = new GuildPass();
    }

    function _issue(address to) internal returns (uint256) {
        vm.prank(guild);
        return pass.issue(to);
    }

    function test_Step1_IssueWithIncreasingIds() public {
        vm.warp(1_000_000);
        assertEq(_issue(alice), 1);
        assertEq(_issue(bob), 2);
        assertEq(pass.ownerOf(1), alice);
        assertEq(pass.balanceOf(bob), 1);
        assertEq(pass.joinedAt(1), 1_000_000);
    }

    function test_Step1_RevertWhen_StrangerIssues() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Owned.NotOwner.selector, alice));
        pass.issue(alice);
    }

    function test_Step1_RevertWhen_ReceiverCannotHold() public {
        Locker locker = new Locker();
        vm.prank(guild);
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721InvalidReceiver.selector, address(locker)));
        pass.issue(address(locker));
    }

    function test_Step2_Revoke() public {
        uint256 id = _issue(alice);
        vm.prank(guild);
        pass.revoke(id);
        assertEq(pass.balanceOf(alice), 0);
        assertEq(pass.joinedAt(id), 0);
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, id));
        pass.ownerOf(id);
    }

    function test_Step3_TokenURI() public {
        vm.warp(1_000_000);
        uint256 id = _issue(alice);
        string memory json =
            '{"name":"Guild Pass #1","attributes":[{"trait_type":"joined","display_type":"date","value":1000000}]}';
        assertEq(pass.tokenURI(id), string.concat("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    function test_Step3_RevertWhen_TokenURIOfMissing() public {
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, 7));
        pass.tokenURI(7);
    }

    function test_Step4_RevertWhen_Transfer() public {
        uint256 id = _issue(alice);
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(GuildPass.Soulbound.selector, id));
        pass.transferFrom(alice, bob, id);
    }

    // Ni con permiso: la regla está en `_update`, por donde pasan todas las transferencias.
    function test_Step4_RevertWhen_ApprovedTransfers() public {
        uint256 id = _issue(alice);
        vm.prank(alice);
        pass.setApprovalForAll(bob, true);
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(GuildPass.Soulbound.selector, id));
        pass.safeTransferFrom(alice, bob, id);
    }

    function test_Inherited_SupportsInterface() public view {
        assertTrue(pass.supportsInterface(0x80ac58cd)); // IERC721
        assertTrue(pass.supportsInterface(0x5b5e139f)); // IERC721Metadata
        assertTrue(pass.supportsInterface(0x01ffc9a7)); // IERC165
    }
}
