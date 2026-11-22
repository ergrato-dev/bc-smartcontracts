# Teoría 03 — Contratos abstractos

## 🎯 Objetivos

- Declarar un contrato `abstract` y explicar por qué no se puede desplegar.
- Dejar en el padre una función sin cuerpo que cada hijo completa.
- Escribir el patrón de plantilla: el padre fija los pasos, el hijo decide una pieza.
- Saber cuándo marcar `abstract` un contrato que sí tiene todo el código.

---

## 1. Qué problema resuelve

Quieres dos puertas de acceso a un evento. Las dos hacen lo mismo al entrar: comprobar si
la cuenta puede pasar, apuntarla, sumar una entrada y emitir un evento. Solo cambia
**quién** puede pasar: en una, cualquiera; en otra, una lista que lleva el dueño.

Con lo de la teoría 02 escribirías una puerta "por defecto" con una regla cualquiera y la
sustituirías en cada hijo. Pero esa regla por defecto no tiene sentido por sí sola, y si
alguien despliega la puerta base, tiene una puerta que nadie pidió. Lo que quieres decir
es: "aquí falta una pieza, y no se despliega hasta que alguien la ponga". Eso es un
**contrato abstracto** (*abstract contract*).

## 2. Cómo se escribe

Crea `src/Gate.sol`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

abstract contract Gate {
    uint256 public entries;
    mapping(address => bool) public inside;

    event Entered(address indexed account);

    error NotAllowed(address account);

    function enter() external {
        if (!_canEnter(msg.sender)) revert NotAllowed(msg.sender);
        inside[msg.sender] = true;
        entries++;
        emit Entered(msg.sender);
    }

    function _canEnter(address account) internal view virtual returns (bool);
}

contract OpenGate is Gate {
    function _canEnter(address) internal pure override returns (bool) {
        return true;
    }
}

contract ListGate is Gate {
    address public immutable OWNER;
    mapping(address => bool) public allowed;

    constructor() {
        OWNER = msg.sender;
    }

    function allow(address account) external {
        if (msg.sender != OWNER) revert NotAllowed(msg.sender);
        allowed[account] = true;
    }

    function _canEnter(address account) internal view override returns (bool) {
        return allowed[account];
    }
}
```

Tres piezas nuevas:

- `abstract contract Gate`: el contrato no se despliega solo.
- `_canEnter(...) ... returns (bool);`: una función **sin cuerpo**, solo la firma y un
  `;`. Tiene que ser `virtual`: está ahí para que un hijo la escriba.
- En `OpenGate`, `_canEnter(address)` sin nombre de parámetro: no lo usa, y así el
  compilador no avisa de un parámetro sin usar. Como no lee el estado, puede ser `pure`
  aunque la del padre sea `view` (un hijo puede prometer más, nunca menos).

## 3. Qué hace el compilador

Una función sin cuerpo en un contrato que no dice `abstract`:

```
Error (3656): Contract "Gate" should be marked as abstract.
```

Un hijo que no escribe la pieza que falta sigue siendo abstracto. Si borras `_canEnter`
de `OpenGate`:

```
Error (3656): Contract "OpenGate" should be marked as abstract.
```

Y otro contrato no puede crear uno abstracto con `new Gate()`:

```
Error (4614): Cannot instantiate an abstract contract.
```

`forge create` tampoco: Gate no tiene bytecode que desplegar. Con anvil recién arrancado:

```bash
PK=$(cast wallet private-key "test test test test test test test test test test test junk" 0)
forge create src/Gate.sol:Gate --private-key "$PK" --broadcast
```

```
Error: no bytecode found in bin object for Gate
```

## 4. El patrón de plantilla

`enter` es la **plantilla** (*template method*): fija los pasos y su orden, y deja un
hueco, `_canEnter`, que cada hijo rellena. Al hueco se le suele llamar *hook* (gancho).
El hijo no puede saltarse los pasos del padre: `ListGate` no tiene forma de entrar sin
sumar `entries` ni sin emitir `Entered`, porque `enter` no es `virtual`.

Despliega `ListGate` en el mismo anvil y prueba con la cuenta 1:

```bash
PK1=$(cast wallet private-key "test test test test test test test test test test test junk" 1)
forge create src/Gate.sol:ListGate --private-key "$PK" --broadcast
G=0x5FbDB2315678afecb367f032d93F642f64180aa3
cast send $G "enter()" --private-key "$PK1"
```

```
Error: Failed to estimate gas: server returned an error response: error code 3: execution reverted: custom error 0xfa5cd00f: 00000000000000000000000070997970c51812dc3a010c7d01b50e0d17dc79c8, data: "0xfa5cd00f00000000000000000000000070997970c51812dc3a010c7d01b50e0d17dc79c8": NotAllowed(0x70997970C51812dc3A010C7d01b50e0d17dc79C8)
```

(La dirección es la del primer despliegue porque el intento con `Gate` no llegó a enviar
nada.) El dueño la apunta en la lista y la cuenta 1 vuelve a intentarlo:

```bash
cast send $G "allow(address)" 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 --private-key "$PK"
cast send $G "enter()" --private-key "$PK1"
cast call $G "entries()(uint256)"
```

Dos recibos con `status 1 (success)` y `1`.

## 5. Abstracto con todo el código

Un contrato puede ser `abstract` aunque no le falte nada. Se hace con piezas que solo
tienen sentido dentro de otro, como el `Owned` de la teoría 01: desplegado solo, es un
contrato con dueño que no hace nada. Marcarlo `abstract` deja clara la intención y evita
que alguien lo despliegue por error.

También es abstracto el hijo que no da argumentos al constructor de su padre (el
`Error (3415)` de la teoría 01): los dará un nieto.

## 6. Antipatrones y riesgos

- **Hooks sin reglas**: el padre no controla qué hace el hijo dentro del hook. Un
  `_canEnter` que devuelve siempre `true` por error abre la puerta a todos y compila sin
  avisar. Lo que no se puede saltar va en la plantilla, no en el hook.
- **Plantilla `virtual`**: si `enter` fuera `virtual`, un hijo podría sustituirla entera
  y saltarse el evento o la cuenta. Deja `virtual` solo en los huecos.
- **Hooks que llaman fuera**: si el hook hace una llamada a otro contrato o envía ETH,
  la plantilla deja de seguir checks-effects-interactions sin que se note al leerla
  (semana 07). Los hooks de comprobación, `view`.
- **Hooks públicos**: un hook es una pieza interna. Hazlo `internal`; si fuera `public`,
  cualquiera podría llamarlo suelto.

## 7. Trucos

- Prefijo `_` para los hooks: `_canEnter`, `_beforeTransfer`. OpenZeppelin (semana 11)
  usa el mismo patrón en sus contratos.
- Pon la firma del hook con nombre de parámetro aunque no tenga cuerpo: documenta qué
  recibe.

## ✅ Checklist

- [ ] Declaro un contrato `abstract` con una función sin cuerpo.
- [ ] Escribo dos hijos que completan el hueco de forma distinta.
- [ ] Explico por qué la plantilla no es `virtual` y el hook sí.
- [ ] Digo cuándo marco `abstract` un contrato que tiene todo el código.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 02 — `virtual`, `override` y `super`](02-virtual-override-y-super.md) | **Teoría 03 — Contratos abstractos** | [Teoría 04 — Interfaces →](04-interfaces.md) |
