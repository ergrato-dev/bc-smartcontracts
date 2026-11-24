// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Points} from "../src/Points.sol";
import {Shop} from "../src/Shop.sol";
import {Deploy} from "../script/Deploy.s.sol";
import {CheckDeployment} from "../script/CheckDeployment.s.sol";

// ¿Qué? Los tests del despliegue de la tienda: que el script deje cada rol donde debe y que
//   CheckDeployment rechace cada despliegue mal hecho con su error.
// ¿Para qué? Un despliegue malo casi nunca falla: la tienda vende, los puntos se acuñan, y el
//   problema (quien desplegó sigue de administrador) solo se ve cuando alguien lo usa.
contract DeploymentTest is Test {
    Deploy script;
    CheckDeployment checker;
    Deploy.Deployment d;

    // En un test, quien firma con vm.startBroadcast() es el remitente por defecto de forge.
    address deployer = DEFAULT_SENDER;
    address dao = makeAddr("dao");
    address buyer = makeAddr("buyer");
    address attacker = makeAddr("attacker");

    function setUp() public {
        script = new Deploy();
        checker = new CheckDeployment();
        vm.deal(buyer, 1 ether);
    }

    function _deploy() internal {
        d = script.deploy(0.01 ether, 2 days, dao);
    }

    function _asTimelock() internal {
        vm.prank(address(d.timelock));
    }

    // ---------- Paso 1: conectar ----------

    function test_Paso1_ShopMintsPoints() public {
        d = script.deployContracts(0.01 ether, 2 days, dao);
        script.wire(d);
        vm.prank(buyer);
        d.shop.buy{value: 0.01 ether}();
        assertEq(d.points.balanceOf(buyer), 10e18, "Paso 1: la compra da los puntos");
    }

    function test_Paso1_RevertWhen_NotWired() public {
        d = script.deployContracts(0.01 ether, 2 days, dao);
        vm.prank(buyer);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, address(d.shop), d.points.MINTER_ROLE()
            )
        );
        d.shop.buy{value: 0.01 ether}();
    }

    // ---------- Paso 2: traspasar ----------

    function test_Paso2_TimelockOwnsEverything() public {
        _deploy();
        assertEq(d.shop.owner(), address(d.timelock), "Paso 2: la tienda es del timelock");
        assertTrue(d.points.hasRole(d.points.DEFAULT_ADMIN_ROLE(), address(d.timelock)), "Paso 2: admin");
        assertFalse(d.points.hasRole(d.points.DEFAULT_ADMIN_ROLE(), deployer), "Paso 2: quien despliega renuncia");
    }

    function test_Paso2_RevertWhen_DeployerWithdraws() public {
        _deploy();
        vm.prank(deployer);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, deployer));
        d.shop.withdraw(payable(deployer));
    }

    // ---------- Paso 3: quién administra ----------

    function test_Paso3_RevertWhen_DeployerStillAdmin() public {
        _deploy();
        bytes32 admin = d.points.DEFAULT_ADMIN_ROLE();
        _asTimelock();
        d.points.grantRole(admin, deployer);
        vm.expectRevert(abi.encodeWithSelector(CheckDeployment.DeployerStillAdmin.selector, address(d.points)));
        checker.check(d, deployer);
    }

    function test_Paso3_RevertWhen_DeployerAdministersTheTimelock() public {
        _deploy();
        bytes32 admin = d.timelock.DEFAULT_ADMIN_ROLE();
        _asTimelock();
        d.timelock.grantRole(admin, deployer);
        vm.expectRevert(abi.encodeWithSelector(CheckDeployment.DeployerStillAdmin.selector, address(d.timelock)));
        checker.check(d, deployer);
    }

    function test_Paso3_RevertWhen_TimelockIsNotAdmin() public {
        d = script.deployContracts(0.01 ether, 2 days, dao);
        script.wire(d);
        vm.expectRevert(
            abi.encodeWithSelector(CheckDeployment.NotAdmin.selector, address(d.points), address(d.timelock))
        );
        checker.check(d, deployer);
    }

    // ---------- Paso 4: nadie más ----------

    function test_Paso4_RevertWhen_AnExtraMinter() public {
        _deploy();
        bytes32 minter = d.points.MINTER_ROLE();
        _asTimelock();
        d.points.grantRole(minter, attacker);
        vm.expectRevert(abi.encodeWithSelector(CheckDeployment.UnexpectedMembers.selector, minter, 2));
        checker.check(d, deployer);
    }

    function test_Paso4_RevertWhen_AnExtraAdmin() public {
        _deploy();
        bytes32 admin = d.points.DEFAULT_ADMIN_ROLE();
        _asTimelock();
        d.points.grantRole(admin, dao);
        vm.expectRevert(abi.encodeWithSelector(CheckDeployment.UnexpectedMembers.selector, admin, 2));
        checker.check(d, deployer);
    }

    function test_Paso4_RevertWhen_TheMinterIsNotTheShop() public {
        _deploy();
        bytes32 minter = d.points.MINTER_ROLE();
        vm.startPrank(address(d.timelock));
        d.points.revokeRole(minter, address(d.shop));
        d.points.grantRole(minter, attacker);
        vm.stopPrank();
        vm.expectRevert(abi.encodeWithSelector(CheckDeployment.NotMinter.selector, address(d.shop)));
        checker.check(d, deployer);
    }

    // ---------- Paso 5: conexiones ----------

    function test_Paso5_ChecksAGoodDeployment() public {
        _deploy();
        checker.check(d, deployer);
    }

    function test_Paso5_RevertWhen_TheShopHasAnotherOwner() public {
        _deploy();
        _asTimelock();
        d.shop.transferOwnership(attacker);
        vm.expectRevert(abi.encodeWithSelector(CheckDeployment.WrongOwner.selector, attacker));
        checker.check(d, deployer);
    }

    function test_Paso5_RevertWhen_TheShopMintsOtherPoints() public {
        _deploy();
        // Otra tienda, del timelock y con el rol de minter, pero de otros puntos.
        Points other = new Points();
        Shop wrong = new Shop(other, 0.01 ether);
        wrong.transferOwnership(address(d.timelock));
        bytes32 minter = d.points.MINTER_ROLE();
        vm.startPrank(address(d.timelock));
        d.points.revokeRole(minter, address(d.shop));
        d.points.grantRole(minter, address(wrong));
        vm.stopPrank();
        d.shop = wrong;
        vm.expectRevert(abi.encodeWithSelector(CheckDeployment.WrongPoints.selector, address(other)));
        checker.check(d, deployer);
    }

    function test_Paso5_RevertWhen_TheDelayIsTooShort() public {
        d = script.deploy(0.01 ether, 1 hours, dao);
        vm.expectRevert(abi.encodeWithSelector(CheckDeployment.DelayTooShort.selector, 1 hours));
        checker.check(d, deployer);
    }

    function test_Paso5_RunDeploysAndChecks() public {
        vm.setEnv("PROPOSER", vm.toString(dao));
        Deploy.Deployment memory r = script.run();
        assertEq(r.shop.price(), 0.01 ether, "Paso 5: run usa el precio por defecto");
        assertEq(r.shop.owner(), address(r.timelock), "Paso 5: run deja la tienda al timelock");
    }
}
