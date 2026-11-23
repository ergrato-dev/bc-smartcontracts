// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Vm} from "forge-std/Vm.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Registry} from "../src/Registry.sol";
import {IRegistry} from "../src/IRegistry.sol";
import {LoyaltyToken} from "../src/LoyaltyToken.sol";
import {Certificate} from "../src/Certificate.sol";

// ¿Qué? Despliega el registro como en anvil: la implementación, el token y el certificado
//   (con la dirección que tendrá el proxy) y el ERC1967Proxy, que llama a `initialize` en su
//   constructor. Devuelve el proxy visto como un Registry.
// ¿Para qué? Que todos los tests usen el registro a través del proxy, como se despliega de verdad.
// ¿Impacto? Quien despliega los cuatro contratos queda como administrador.
abstract contract DeployRegistry {
    Vm private constant CHEATS = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    // El registro desplegado por el propio contrato de test.
    function deployRegistry(uint256 capacity) internal returns (Registry) {
        return deployRegistryFrom(address(this), capacity);
    }

    function deployRegistryFrom(address deployer, uint256 capacity) internal returns (Registry registry) {
        CHEATS.startPrank(deployer);
        Registry implementation = new Registry();
        // El proxy es el tercer contrato que `deployer` crea a partir de aquí: token, certificado, proxy.
        address proxy = CHEATS.computeCreateAddress(deployer, CHEATS.getNonce(deployer) + 2);
        LoyaltyToken token = new LoyaltyToken(proxy);
        Certificate nft = new Certificate(IRegistry(proxy));
        bytes memory init = abi.encodeCall(Registry.initialize, (capacity, token, nft));
        registry = Registry(address(new ERC1967Proxy(address(implementation), init)));
        CHEATS.stopPrank();
    }
}
