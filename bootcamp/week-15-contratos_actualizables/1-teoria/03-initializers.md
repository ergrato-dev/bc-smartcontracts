# Teoría 03 — Initializers

## 🎯 Objetivos

- Explicar por qué el constructor de una implementación no inicializa el proxy.
- Sustituir el constructor por `initialize` con `Initializable` y las bases upgradeable de
  OpenZeppelin.
- Cerrar la implementación con `_disableInitializers` e inicializar una V2 con
  `reinitializer`.
- Reconocer los ataques a contratos sin inicializar y qué pasa con las variables `immutable`.

---

## 1. Qué problema resuelve

Un constructor se ejecuta una sola vez, al desplegar, y escribe en el storage **del contrato
que se despliega**. Al desplegar la implementación, su constructor escribe en el storage de la
implementación. El proxy se despliega después, con su propio storage vacío, y nunca ejecuta
ese constructor.

Con `Ownable(msg.sender)` en el constructor de la implementación, la implementación tiene
dueño y el proxy no: `owner()` a través del proxy devuelve `address(0)`. Lo mismo con el
nombre, la capacidad o cualquier valor inicial.

La solución es una función normal que hace lo que haría el constructor: `initialize`. El
proxy la llama con `delegatecall`, así que escribe en el storage del proxy. Pero una función
normal se puede llamar más de una vez, y cualquiera puede llamarla: hace falta un guardián.

## 2. Cómo funciona

`Initializable`, de OpenZeppelin, guarda en el storage del proxy un contador de versión
inicializada (en un slot de ERC-7201, teoría 02) y trae tres modificadores:

| Modificador | Qué permite |
| ----------- | ----------- |
| `initializer` | Ejecutar la función una sola vez, si el contrato aún no está inicializado |
| `reinitializer(n)` | Ejecutarla una vez, si la versión inicializada es menor que `n`. Para V2, V3… |
| `onlyInitializing` | Llamarla solo desde dentro de una función con uno de los dos anteriores |

Y `_disableInitializers()`, que pone la versión en el máximo (`type(uint64).max`): ningún
`initializer` ni `reinitializer` vuelve a funcionar en ese storage.

Las bases de OpenZeppelin para proxies están en otro paquete,
`@openzeppelin/contracts-upgradeable`, con el mismo nombre y `Upgradeable` al final:
`OwnableUpgradeable`, `AccessControlUpgradeable`, `PausableUpgradeable`… No tienen
constructor: cada una trae una función `__Nombre_init` con `onlyInitializing`, que tu
`initialize` llama.

## 3. Cómo se escribe

El club del ejercicio 02, completo:

```solidity
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract ClubV1 is Initializable, OwnableUpgradeable {
    string public name;
    // ...

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner, string calldata clubName) external initializer {
        __Ownable_init(initialOwner);
        name = clubName;
    }
}
```

Tres cosas:

- **El constructor sigue existiendo**, pero solo cierra la implementación. El comentario
  `@custom:oz-upgrades-unsafe-allow constructor` lo leen las herramientas de OpenZeppelin que
  revisan contratos actualizables: dice que ese constructor es intencionado.
- **`__Ownable_init(initialOwner)`** hace lo que hacía `Ownable(initialOwner)` en la cabecera
  del constructor. Si heredas de varias bases, llama a todos sus `__X_init`, en el orden de la
  herencia. Algunos no hacen nada (`__AccessControl_init`), pero llamarlos te protege si una
  versión futura de la base sí inicializa algo.
- **El dueño se pasa como parámetro**, no se toma de `msg.sender`. Con un proxy desplegado y
  ya inicializado en la misma transacción, `msg.sender` es quien despliega; pero un parámetro
  deja claro quién queda de dueño.

### Inicializar en el mismo despliegue

Si despliegas el proxy en una transacción y llamas a `initialize` en otra, entre las dos el
proxy existe sin dueño, y cualquiera que vea tu transacción en el mempool puede adelantarse,
llamar a `initialize` y quedarse el contrato. Los proxies de OpenZeppelin reciben la llamada a
`initialize` en su constructor, como `bytes`, y la ejecutan allí mismo:

```solidity
new TransparentUpgradeableProxy(address(v1), owner, abi.encodeCall(ClubV1.initialize, (owner, "Chess")));
new ERC1967Proxy(address(implementation), abi.encodeCall(NotesV1.initialize, (owner)));
```

Con `cast`, esos `bytes` salen de `cast calldata "initialize(address,string)" $A0 Chess`
(ejercicio 02).

### Inicializar una V2

Las variables nuevas de una V2 empiezan a 0, y el proxy ya está inicializado: `initializer`
ya no vale. `reinitializer(2)` sí, una vez:

```solidity
contract ClubV2 is ClubV1 {
    uint256 public maxMembers;

    function initializeV2(uint256 newMaxMembers) external reinitializer(2) {
        maxMembers = newMaxMembers;
    }
}
```

La actualización y la llamada van juntas: `upgradeAndCall(proxy, v2, data)` en el transparent,
`upgradeToAndCall(v2, data)` en UUPS (teoría 04). Si van en dos transacciones, el mismo
problema de antes: alguien puede llamar a `initializeV2` primero, con sus valores.

## 4. Las variables `immutable`

Una variable `immutable` no está en el storage: el constructor escribe su valor **dentro del
código** de la implementación (semana 04). El proxy ejecuta ese código, así que ve el valor…
pero es el que fijó el constructor de la implementación, no uno propio del proxy.

- Las **constantes** (`constant`) no tienen problema: son parte del código y no dependen del
  constructor.
- Una `immutable` fijada en el constructor de la implementación es la misma para todos los
  proxies que la usen, y **cambia con cada implementación**: la V2 tendrá que fijarla otra
  vez en su constructor, al mismo valor.
- Un contrato que la implementación crea en su constructor (con `new`) tiene como creador a la
  implementación, no al proxy.

Por eso el proyecto pasa la capacidad, el token y el certificado del registro de `immutable`
a variables de storage que se escriben en `initialize`.

## 5. Antipatrones y riesgos

- ❌ **Implementación sin cerrar.** Su `initialize` es `external`: cualquiera lo llama sobre la
  implementación y se hace su dueño. En noviembre de 2017, alguien inicializó la biblioteca
  que usaban todas las wallets multifirma de Parity, se hizo su dueño y la destruyó con
  `selfdestruct`: unos 513.000 ETH quedaron bloqueados para siempre en las wallets que
  dependían de ella. En 2022, Wormhole pagó una recompensa de 10 millones de dólares a quien
  encontró su implementación UUPS sin inicializar. `_disableInitializers()` en el constructor
  lo evita.
- ❌ **`initialize` en otra transacción.** Quien llega antes se queda el contrato. Pasa la
  llamada en el constructor del proxy.
- ❌ **Olvidar un `__X_init`.** Compila, y la base queda sin inicializar: sin `__EIP712_init`,
  el dominio EIP-712 no tiene nombre y ninguna firma coincide (lo verás en el proyecto).
- ❌ **Mezclar paquetes.** `Ownable` de `@openzeppelin/contracts` tiene constructor y guarda
  `_owner` en un slot secuencial, delante de tus variables; `OwnableUpgradeable`, no. En un contrato detrás de un proxy, todas las
  bases con estado tienen que ser las upgradeable.
- ❌ **`initializer` en una V2.** No se ejecuta: el proxy ya está inicializado. Usa
  `reinitializer(2)`, `reinitializer(3)`…

## 6. Trucos

- El evento `Initialized(version)` sale cada vez que se inicializa: `1` con `initialize`,
  `2` con `reinitializer(2)` y `18446744073709551615` (`type(uint64).max`) al cerrar la
  implementación.
- Un test que intente llamar a `initialize` sobre la implementación, y otro que lo intente dos
  veces sobre el proxy, cubren los dos ataques: los dos esperan `InvalidInitialization`.

## ✅ Checklist

- [ ] Explico por qué el proxy no ve lo que escribe el constructor de la implementación.
- [ ] Convierto un constructor en `initialize` con `initializer` y los `__X_init` de sus bases.
- [ ] Cierro la implementación con `_disableInitializers` y explico qué ataque evita.
- [ ] Inicializo una V2 con `reinitializer(2)` en la misma transacción que la actualización.
- [ ] Explico qué pasa con una variable `immutable` detrás de un proxy.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 02 — Storage layout](02-storage-layout.md) | **Teoría 03 — Initializers** | [Teoría 04 — UUPS y transparent →](04-uups-y-transparent.md) |
