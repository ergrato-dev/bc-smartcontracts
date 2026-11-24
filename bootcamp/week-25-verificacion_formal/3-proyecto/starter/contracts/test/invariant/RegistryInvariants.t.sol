// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {RegistryProperties} from "./RegistryProperties.sol";

// ¿Qué? Las invariantes del protocolo con el fuzzer de forge, sobre las mismas `property_` que
//   usa Medusa.
// ¿Impacto? Con fail-on-revert, una llamada del handler que revierte también es un fallo: o el
//   handler no sabe cuándo el registro rechaza una acción, o el registro rechaza una que debería
//   aceptar.
/// forge-config: default.invariant.fail-on-revert = true
contract RegistryInvariantsTest is Test {
    RegistryProperties props;

    function setUp() public {
        props = new RegistryProperties();
        targetContract(address(props));
    }

    function invariant_ActiveWithinCapacity() public view {
        assertTrue(props.property_activeWithinCapacity());
    }

    function invariant_ActiveMatchesRetired() public view {
        assertTrue(props.property_activeMatchesRetired());
    }

    function invariant_CertificatesMatchCount() public view {
        assertTrue(props.property_certificatesMatchCount());
    }

    function invariant_FeesAccounted() public view {
        assertTrue(props.property_feesAccounted());
    }

    function invariant_PointsAccounted() public view {
        assertTrue(props.property_pointsAccounted());
    }

    function invariant_PerAccountLimit() public view {
        assertTrue(props.property_perAccountLimit());
    }
}
