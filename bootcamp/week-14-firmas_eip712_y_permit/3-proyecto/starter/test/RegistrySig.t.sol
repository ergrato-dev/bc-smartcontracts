// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {Registry} from "../src/Registry.sol";
import {IRegistry} from "../src/IRegistry.sol";

// ¿Qué? Las altas con una orden EIP-712: `member` firma fuera de la cadena y `sponsor`
//   envía la orden y paga la tasa.
// ¿Para qué? Comprobar que la orden la firmó quien dice, que vale una vez, hasta su plazo,
//   solo en este registro y en esta red, y que el recurso es de quien firmó.
// ¿Impacto? No los modifiques: son el contrato de esta capa.
contract RegistrySigTest is Test {
    Registry registry;
    uint256 fee;
    address member;
    uint256 memberKey;
    address mallory;
    uint256 malloryKey;
    address sponsor = makeAddr("sponsor");
    uint256 deadline;

    function setUp() public {
        (member, memberKey) = makeAddrAndKey("member");
        (mallory, malloryKey) = makeAddrAndKey("mallory");
        registry = new Registry(3);
        registry.setHook(address(registry.LOYALTY()));
        fee = registry.REGISTRATION_FEE();
        deadline = block.timestamp + 1 hours;
        vm.deal(sponsor, 1 ether);
    }

    // El digest EIP-712 montado a mano: dominio del registro + struct Registration.
    function _digest(Registry target, address registrant, string memory label, uint256 nonce)
        internal
        view
        returns (bytes32)
    {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(target.PROTOCOL_NAME())),
                keccak256("1"),
                block.chainid,
                address(target)
            )
        );
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Registration(address registrant,string label,uint256 nonce,uint256 deadline)"),
                registrant,
                keccak256(bytes(label)),
                nonce,
                deadline
            )
        );
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }

    function _sign(uint256 key, string memory label) internal view returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(key, _digest(registry, member, label, registry.nonces(member)));
        return abi.encodePacked(r, s, v);
    }

    function _sendAsSponsor(string memory label, bytes memory sig) internal returns (uint256) {
        vm.prank(sponsor);
        return registry.registerBySig{value: fee}(member, label, deadline, sig);
    }

    function test_DomainNameIsTheProtocol() public view {
        (, string memory name, string memory version, uint256 chainId, address verifyingContract,,) =
            registry.eip712Domain();
        assertEq(name, registry.PROTOCOL_NAME());
        assertEq(version, "1");
        assertEq(chainId, block.chainid);
        assertEq(verifyingContract, address(registry));
    }

    function test_SponsorRegistersForMember() public {
        vm.expectEmit(address(registry));
        emit IRegistry.ItemRegistered(1, member, "north");
        uint256 id = _sendAsSponsor("north", _sign(memberKey, "north"));

        assertEq(id, 1);
        assertEq(registry.getItem(1).registrant, member);
        assertEq(registry.idsOf(member).length, 1);
        assertEq(registry.idsOf(sponsor).length, 0);
        assertEq(registry.CERTIFICATE().ownerOf(1), member);
        assertEq(registry.LOYALTY().balanceOf(member), registry.LOYALTY().REWARD());
        assertEq(registry.nonces(member), 1);
        assertEq(address(registry).balance, fee);
        assertEq(sponsor.balance, 1 ether - fee);
    }

    function test_MemberCanRetireWhatTheSponsorPaid() public {
        _sendAsSponsor("north", _sign(memberKey, "north"));
        vm.prank(member);
        registry.retire(1);
        assertEq(registry.activeCount(), 0);
    }

    function test_RevertWhen_SignedByOtherKey() public {
        bytes memory sig = _sign(malloryKey, "north");
        vm.prank(sponsor);
        vm.expectRevert(abi.encodeWithSelector(Registry.InvalidSigner.selector, mallory, member));
        registry.registerBySig{value: fee}(member, "north", deadline, sig);
    }

    function test_RevertWhen_LabelIsChanged() public {
        bytes memory sig = _sign(memberKey, "north");
        vm.prank(sponsor);
        vm.expectPartialRevert(Registry.InvalidSigner.selector);
        registry.registerBySig{value: fee}(member, "south", deadline, sig);
    }

    function test_RevertWhen_OrderIsReplayed() public {
        bytes memory sig = _sign(memberKey, "north");
        _sendAsSponsor("north", sig);
        vm.prank(sponsor);
        vm.expectPartialRevert(Registry.InvalidSigner.selector);
        registry.registerBySig{value: fee}(member, "north", deadline, sig);
        assertEq(registry.count(), 1);
    }

    function test_RevertWhen_OrderIsSentToOtherRegistry() public {
        bytes memory sig = _sign(memberKey, "north");
        Registry other = new Registry(3);
        vm.prank(sponsor);
        vm.expectPartialRevert(Registry.InvalidSigner.selector);
        other.registerBySig{value: fee}(member, "north", deadline, sig);
    }

    function test_RevertWhen_OrderIsSentOnOtherChain() public {
        bytes memory sig = _sign(memberKey, "north");
        vm.chainId(1);
        vm.prank(sponsor);
        vm.expectPartialRevert(Registry.InvalidSigner.selector);
        registry.registerBySig{value: fee}(member, "north", deadline, sig);
    }

    function test_RevertWhen_OrderExpired() public {
        bytes memory sig = _sign(memberKey, "north");
        vm.warp(deadline + 1);
        vm.prank(sponsor);
        vm.expectRevert(abi.encodeWithSelector(Registry.ExpiredSignature.selector, deadline));
        registry.registerBySig{value: fee}(member, "north", deadline, sig);
    }

    function test_RevertWhen_SignatureIsMalformed() public {
        vm.prank(sponsor);
        vm.expectRevert(abi.encodeWithSelector(ECDSA.ECDSAInvalidSignatureLength.selector, 64));
        registry.registerBySig{value: fee}(member, "north", deadline, new bytes(64));
    }

    // Una orden fallida no gasta el nonce: el revert deshace `_useNonce`.
    function test_RevertWhen_WrongFeeKeepsTheNonce() public {
        bytes memory sig = _sign(memberKey, "north");
        vm.prank(sponsor);
        vm.expectRevert(abi.encodeWithSelector(IRegistry.WrongFee.selector, fee, 0));
        registry.registerBySig(member, "north", deadline, sig);
        assertEq(registry.nonces(member), 0);
        _sendAsSponsor("north", sig);
    }

    function test_RevertWhen_RegisterBySigWhilePaused() public {
        registry.grantRole(registry.PAUSER_ROLE(), address(this));
        registry.pause();
        bytes memory sig = _sign(memberKey, "north");
        vm.prank(sponsor);
        vm.expectRevert(Pausable.EnforcedPause.selector);
        registry.registerBySig{value: fee}(member, "north", deadline, sig);
    }

    function test_RevertWhen_RegisterBySigWhileFull() public {
        vm.deal(address(this), 1 ether);
        string[] memory labels = new string[](3);
        labels[0] = "a";
        labels[1] = "b";
        labels[2] = "c";
        registry.registerBatch{value: 3 * fee}(labels);
        bytes memory sig = _sign(memberKey, "north");
        vm.prank(sponsor);
        vm.expectRevert(abi.encodeWithSelector(IRegistry.RegistryFull.selector, 3));
        registry.registerBySig{value: fee}(member, "north", deadline, sig);
    }

    function test_SecondOrderUsesTheNextNonce() public {
        _sendAsSponsor("north", _sign(memberKey, "north"));
        _sendAsSponsor("south", _sign(memberKey, "south"));
        assertEq(registry.nonces(member), 2);
        assertEq(registry.idsOf(member).length, 2);
    }
}
