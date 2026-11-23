# Teoría 04 — UUPS y transparent

## 🎯 Objetivos

- Explicar el choque de selectores entre un proxy y su implementación.
- Explicar cómo lo resuelven el proxy **transparent** y el patrón **UUPS**, y en qué se
  diferencian.
- Escribir `_authorizeUpgrade` y actualizar con `upgradeToAndCall`.
- Decidir quién puede actualizar y reconocer cómo se rompe para siempre un proxy UUPS.

---

## 1. Qué problema resuelve

Un proxy tiene que poder actualizarse: alguna función tiene que cambiar el slot de la
implementación. En el ejercicio 01, esa función es `upgradeTo`, en el propio proxy. Funciona,
pero tiene un fallo de diseño: el **choque de selectores**.

Una llamada llega con un selector de 4 bytes (semana 10). Si el proxy tiene una función con
ese selector, la ejecuta él; si no, la reenvía. Si la implementación tiene una función con el
mismo selector que una del proxy, nadie puede llamarla: el proxy gana siempre. No hace falta
que se llamen igual: hay firmas distintas con el mismo selector, porque 4 bytes son pocos.

OpenZeppelin tiene dos respuestas: que el proxy no reenvíe nunca a quien actualiza
(**transparent**), o que el proxy no tenga ninguna función (**UUPS**).

![A la izquierda, el proxy transparent: el ProxyAdmin solo puede llamar a upgradeToAndCall en el proxy, y cualquier otra cuenta llega siempre a la implementación; a la derecha, UUPS: el ERC1967Proxy solo reenvía, y upgradeToAndCall está en la implementación, protegida por _authorizeUpgrade](../0-assets/02-transparent-frente-a-uups.svg)

## 2. Proxy transparent

`TransparentUpgradeableProxy` separa a quien llama por su dirección:

- **El administrador** solo puede llamar a `upgradeToAndCall`, que está en el proxy. Cualquier
  otra llamada suya revierte con `ProxyDeniedAdminAccess`.
- **Cualquier otra cuenta** llega siempre a la implementación, también si llama a
  `upgradeToAndCall`: el proxy no le enseña su función.

Así no hay choque: para cada cuenta, cada selector va a un solo sitio. Para que el
administrador sea una cuenta dedicada, el proxy crea en su constructor un contrato
`ProxyAdmin`, con dueño la dirección que le pasas, y lo guarda en el slot de administrador de
EIP-1967. Tú actualizas a través del `ProxyAdmin`:

```solidity
// En el setUp del ejercicio 02: `owner` es el dueño del ProxyAdmin, no el administrador.
new TransparentUpgradeableProxy(address(v1), owner, abi.encodeCall(ClubV1.initialize, (owner, "Chess")));

// Para actualizar, el dueño llama al ProxyAdmin.
proxyAdmin.upgradeAndCall(ITransparentUpgradeableProxy(address(club)), address(v2), data);
```

La implementación no sabe nada de actualizaciones: es un contrato con `initialize`.

## 3. UUPS

**UUPS** (Universal Upgradeable Proxy Standard, ERC-1822) pone la función de actualizar en la
**implementación**. El proxy es un `ERC1967Proxy`: un constructor y un `fallback`, sin ninguna
función más, así que no puede chocar con nada. La implementación hereda de `UUPSUpgradeable`,
que trae `upgradeToAndCall(newImplementation, data)`, y tú escribes quién puede usarla:

```solidity
contract NotesV1 is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    // ...
    function _authorizeUpgrade(address) internal view override onlyOwner {}
}
```

`upgradeToAndCall`, ejecutada con `delegatecall` sobre el storage del proxy, hace cuatro cosas:

1. **`onlyProxy`**: revierte con `UUPSUnauthorizedCallContext` si no se llama a través de un
   proxy. Así nadie actualiza la implementación misma.
2. **`_authorizeUpgrade(newImplementation)`**: tu comprobación. Si revierte, no se actualiza.
3. **Comprueba la nueva implementación**: le pide `proxiableUUID()`, que tiene que devolver el
   slot de la implementación de EIP-1967. Un contrato sin UUPS no tiene esa función, y la
   actualización revierte con `ERC1967InvalidImplementation`.
4. **Escribe el slot, emite `Upgraded`** y, si `data` no está vacío, llama a la nueva
   implementación con `data` (por ejemplo, `initializeV2`).

En el registro del proyecto, la comprobación es un rol:

```solidity
function _authorizeUpgrade(address) internal view override onlyRole(DEFAULT_ADMIN_ROLE) {}
```

Tras el traspaso de la semana 13, `DEFAULT_ADMIN_ROLE` es el timelock: cada actualización se
programa, espera su plazo y cualquiera puede verla venir.

## 4. Cuál elegir

| | Transparent | UUPS |
| - | ----------- | ---- |
| Dónde está `upgradeToAndCall` | En el proxy | En la implementación |
| Quién actualiza | El dueño del `ProxyAdmin` | Lo que diga `_authorizeUpgrade` |
| Contratos por despliegue | Implementación, proxy y `ProxyAdmin` | Implementación y proxy |
| La implementación sabe de actualizaciones | No | Sí: hereda de `UUPSUpgradeable` |
| Se puede dejar de actualizar | Renunciando al `ProxyAdmin` | Actualizando a una versión sin `UUPSUpgradeable` |
| Riesgo propio | El administrador no puede usar el contrato | Una V2 sin `_authorizeUpgrade` bien escrito |

¿Cuánto cuesta cada uno? En un proyecto con el `foundry.toml` del ejercicio 03, crea
`test/Gas.t.sol`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test, console} from "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract Counter is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    uint256 public count;

    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) external initializer {
        __Ownable_init(initialOwner);
    }

    function increment() external {
        count++;
    }

    function _authorizeUpgrade(address) internal view override onlyOwner {}
}

contract GasTest is Test {
    function test_ProxyGas() public {
        Counter implementation = new Counter();
        bytes memory init = abi.encodeCall(Counter.initialize, (address(this)));

        uint256 before = gasleft();
        Counter uups = Counter(address(new ERC1967Proxy(address(implementation), init)));
        console.log("deploy ERC1967Proxy:", before - gasleft());
        before = gasleft();
        Counter transparent =
            Counter(address(new TransparentUpgradeableProxy(address(implementation), address(this), init)));
        console.log("deploy TransparentUpgradeableProxy:", before - gasleft());

        before = gasleft();
        implementation.increment();
        console.log("increment directo:", before - gasleft());
        before = gasleft();
        uups.increment();
        console.log("increment por ERC1967Proxy:", before - gasleft());
        before = gasleft();
        transparent.increment();
        console.log("increment por TransparentUpgradeableProxy:", before - gasleft());
    }
}
```

```bash
forge test --match-contract GasTest -vv
```

```
  deploy ERC1967Proxy: 232232
  deploy TransparentUpgradeableProxy: 1107618
  increment directo: 46417
  increment por ERC1967Proxy: 51385
  increment por TransparentUpgradeableProxy: 51475
```

`increment` sobre la implementación es la referencia. A través de cualquiera de los dos
proxies cuesta unos 5.000 de gas más: leer el slot de la implementación y el `delegatecall`.
Entre los dos proxies apenas hay 90 de diferencia, porque en OpenZeppelin 5 el transparent
guarda su administrador como `immutable`. Donde se separan es al desplegar: el transparent
crea además su `ProxyAdmin`, y cuesta casi cinco veces más.

Esta semana usarás los dos: transparent en el ejercicio 02 y UUPS en el ejercicio 03 y en el
proyecto. El proyecto usa UUPS porque el registro ya tiene roles: `_authorizeUpgrade` reutiliza
`DEFAULT_ADMIN_ROLE` y el timelock de la semana 13, sin un `ProxyAdmin` con otro dueño.

Hay un tercer patrón, el **beacon**: muchos proxies leen la implementación de un mismo
contrato `UpgradeableBeacon`, y actualizar el beacon actualiza todos a la vez. Sirve cuando
despliegas muchas copias del mismo contrato, una por usuario por ejemplo.

## 5. Antipatrones y riesgos

- ❌ **`_authorizeUpgrade` vacío o sin control.** Compila, porque es tuyo, y deja que
  cualquiera actualice tu contrato a un código que se lleve los fondos. Es el error más grave
  de UUPS: un test con una cuenta sin permisos que intenta actualizar lo detecta.
- ❌ **Actualizar a una implementación sin `UUPSUpgradeable`.** El proxy apuntaría a un código
  sin `upgradeToAndCall` y no se podría actualizar nunca más. OpenZeppelin lo impide
  comprobando `proxiableUUID`, pero una V2 que hereda de `UUPSUpgradeable` con un
  `_authorizeUpgrade` que siempre revierte tiene el mismo efecto.
- ❌ **Implementación UUPS sin cerrar.** En OpenZeppelin 4.1 a 4.3.1 había un fallo crítico:
  quien inicializaba la implementación podía llamar a `upgradeToAndCall` sobre ella con una
  llamada a `selfdestruct` y dejar sin código a todos los proxies que la usaban. Se corrigió en
  la 4.3.2 con `onlyProxy`, pero `_disableInitializers()` (teoría 03) cierra la puerta igual.
- ❌ **El administrador del transparent usando el contrato.** Revierte con
  `ProxyDeniedAdminAccess`. El `ProxyAdmin` es un contrato aparte justo para que eso no te pase
  con tu cuenta.
- ❌ **Una sola clave que actualiza al instante.** Quien la robe cambia todo el código. Pon las
  actualizaciones detrás de un timelock (semana 13) o de una multifirma, para que los usuarios
  vean una actualización antes de que llegue y puedan irse.

## 6. Trucos

- `cast call <implementación> "proxiableUUID()(bytes32)"` dice si una implementación es UUPS:
  devuelve el slot de EIP-1967. A través del proxy, la misma llamada revierte.
- `upgradeToAndCall(v2, 0x)` actualiza sin llamada extra: `0x` son datos vacíos.
- Antes de actualizar, en un test: despliega la V2, actualiza un proxy recién creado con
  estado de prueba y comprueba que todo sigue. Es lo que hace `RegistryUpgrade.t.sol`.

## ✅ Checklist

- [ ] Explico el choque de selectores y cómo lo evitan transparent y UUPS.
- [ ] Explico por qué el administrador de un transparent no puede usar el contrato.
- [ ] Escribo `_authorizeUpgrade` con un rol y actualizo con `upgradeToAndCall`.
- [ ] Explico qué comprueba `upgradeToAndCall` antes de cambiar el slot.
- [ ] Digo quién puede actualizar mi registro y cuánto tarda en hacerlo.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 03 — Initializers](03-initializers.md) | **Teoría 04 — UUPS y transparent** | [Ejercicio 01 — Proxy a mano →](../2-practicas/ejercicio-01-proxy-a-mano/README.md) |
