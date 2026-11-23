// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Registry} from "../src/Registry.sol";
import {DeployRegistry} from "./DeployRegistry.sol";
import {IRegistry} from "../src/IRegistry.sol";
import {Certificate} from "../src/Certificate.sol";

// ¿Qué? El certificado de cada recurso: quién lo emite, qué dice su metadata y quién
//   puede retirar el recurso.
// ¿Para qué? Comprobar la capa de la semana 12 sin repetir los tests de OpenZeppelin.
// ¿Impacto? No los modifiques: son el contrato de esta capa.
contract RegistryCertificateTest is Test, DeployRegistry {
    using Strings for uint256;

    Registry registry;
    Certificate certificate;
    uint256 fee;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        registry = deployRegistry(10);
        certificate = registry.certificate();
        fee = registry.REGISTRATION_FEE();
        vm.deal(alice, 1 ether);
    }

    function _register(string memory label) internal returns (uint256 id) {
        vm.prank(alice);
        id = registry.register{value: fee}(label);
    }

    // El JSON que tiene que devolver tokenURI, ya decodificado.
    function _json(string memory label, uint256 id, string memory status, uint256 timestamp)
        internal
        pure
        returns (string memory)
    {
        return string.concat(
            '{"name":"',
            label,
            '","description":"Certificate #',
            id.toString(),
            '","attributes":[{"trait_type":"status","value":"',
            status,
            '"},{"trait_type":"registeredAt","display_type":"date","value":',
            timestamp.toString(),
            "}]}"
        );
    }

    function _uri(string memory json) internal pure returns (string memory) {
        return string.concat("data:application/json;base64,", Base64.encode(bytes(json)));
    }

    function test_CertificateIsDeployedByTheRegistry() public view {
        assertEq(address(certificate.REGISTRY()), address(registry));
        assertGt(bytes(certificate.name()).length, 0);
        assertGt(bytes(certificate.symbol()).length, 0);
        assertTrue(certificate.supportsInterface(0x80ac58cd)); // IERC721
        assertTrue(certificate.supportsInterface(0x5b5e139f)); // IERC721Metadata
    }

    function test_RegisterMintsCertificate() public {
        uint256 id = _register("north");
        assertEq(certificate.ownerOf(id), alice);
        assertEq(certificate.balanceOf(alice), 1);
    }

    function test_BatchMintsOneCertificatePerItem() public {
        string[] memory labels = new string[](3);
        labels[0] = "a";
        labels[1] = "b";
        labels[2] = "c";
        vm.prank(alice);
        uint256 firstId = registry.registerBatch{value: 3 * fee}(labels);
        assertEq(certificate.balanceOf(alice), 3);
        assertEq(certificate.ownerOf(firstId + 2), alice);
    }

    function test_RevertWhen_StrangerMints() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Certificate.NotRegistry.selector, alice));
        certificate.mint(alice, 99);
    }

    function test_TokenURIShowsLabelAndStatus() public {
        uint256 id = _register("north");
        assertEq(certificate.tokenURI(id), _uri(_json("north", id, "Active", block.timestamp)));
    }

    function test_TokenURIFollowsRetire() public {
        uint256 id = _register("north");
        vm.prank(alice);
        registry.retire(id);
        assertEq(certificate.tokenURI(id), _uri(_json("north", id, "Retired", block.timestamp)));
    }

    // Una etiqueta con comillas no puede añadir campos al JSON.
    function test_TokenURIEscapesLabel() public {
        uint256 id = _register('x","description":"fake');
        string memory escaped = 'x\\",\\"description\\":\\"fake';
        assertEq(certificate.tokenURI(id), _uri(_json(escaped, id, "Active", block.timestamp)));
    }

    function test_RevertWhen_TokenURIOfMissingCertificate() public {
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, 99));
        certificate.tokenURI(99);
    }

    // Quien tiene el certificado es quien puede retirar: el registrante original ya no.
    function test_HolderRetiresAfterTransfer() public {
        uint256 id = _register("north");
        vm.prank(alice);
        certificate.transferFrom(alice, bob, id);

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IRegistry.NotRegistrant.selector, alice, id));
        registry.retire(id);

        vm.prank(bob);
        registry.retire(id);
        assertEq(uint256(registry.getItem(id).status), uint256(IRegistry.Status.Retired));
    }

    function test_RegisterWithPointsMintsCertificate() public {
        registry.setHook(address(registry.loyalty()));
        string[] memory labels = new string[](3);
        labels[0] = "a";
        labels[1] = "b";
        labels[2] = "c";
        vm.startPrank(alice);
        registry.registerBatch{value: 3 * fee}(labels);
        registry.loyalty().approve(address(registry), registry.POINTS_PRICE());
        uint256 id = registry.registerWithPoints("d");
        vm.stopPrank();
        assertEq(certificate.ownerOf(id), alice);
        assertEq(certificate.balanceOf(alice), 4);
    }
}
