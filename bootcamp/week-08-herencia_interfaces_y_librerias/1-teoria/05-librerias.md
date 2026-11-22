# Teoría 05 — Librerías

## 🎯 Objetivos

- Escribir una `library` con funciones `internal` y usarla desde un contrato.
- Adjuntar funciones de librería a un tipo con `using ... for`.
- Escribir funciones de librería que trabajan sobre el storage del contrato que las usa.
- Elegir entre librería, contrato padre y contrato aparte.

---

## 1. Qué problema resuelve

Algunas piezas de código no tienen estado propio ni dueño: limitar un número a un rango,
calcular un porcentaje, comprobar una etiqueta, buscar en un array. Las necesitan
contratos que no tienen nada que ver entre sí, y heredar de un contrato padre solo para
eso mete en la jerarquía algo que no es "un tipo de" tu contrato.

Una **librería** (*library*) es un bloque de funciones reutilizables, sin estado. Las
llamas por su nombre, `Clamp.clamp(x, 0, 100)`, o adjuntas sus funciones a un tipo y las
llamas como si fueran del valor: `x.clamp(0, 100)`.

## 2. Cómo se escribe

Crea `src/Scores.sol`, un contrato que guarda puntuaciones de 0 a 100 y su media:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

library Clamp {
    function clamp(uint256 value, uint256 low, uint256 high) internal pure returns (uint256) {
        if (value < low) return low;
        if (value > high) return high;
        return value;
    }
}

library Tally {
    struct Data {
        uint256 count;
        uint256 total;
    }

    error Empty();

    function add(Data storage self, uint256 value) internal {
        self.count++;
        self.total += value;
    }

    function average(Data storage self) internal view returns (uint256) {
        if (self.count == 0) revert Empty();
        return self.total / self.count;
    }
}

contract Scores {
    using Clamp for uint256;
    using Tally for Tally.Data;

    uint256 public constant MAX_SCORE = 100;

    Tally.Data private _scores;

    function record(uint256 score) external {
        _scores.add(score.clamp(0, MAX_SCORE));
    }

    function average() external view returns (uint256) {
        return _scores.average();
    }

    function count() external view returns (uint256) {
        return _scores.count;
    }
}
```

- `Clamp` es una librería de cálculo: `pure`, recibe valores y devuelve un valor.
- `Tally` declara un struct y trabaja **sobre el storage de quien la usa**: el parámetro
  `Data storage self` es una referencia (semana 06) a `_scores`, que vive en `Scores`. La
  librería no tiene estado; modifica el del contrato.
- `using Clamp for uint256;` adjunta las funciones de `Clamp` a todo `uint256`:
  `score.clamp(0, MAX_SCORE)` es lo mismo que `Clamp.clamp(score, 0, MAX_SCORE)`. El valor
  de la izquierda pasa como **primer** parámetro.

## 3. Cómo funciona

Con anvil recién arrancado, despliega `Scores`, pide la media sin datos y registra tres
puntuaciones, una por encima del tope:

```bash
PK=$(cast wallet private-key "test test test test test test test test test test test junk" 0)
forge create src/Scores.sol:Scores --private-key "$PK" --broadcast
S=0x5FbDB2315678afecb367f032d93F642f64180aa3
cast call $S "average()(uint256)"
```

```
Error: execution reverted: Empty
```

El error `Empty` de la librería sale de `Scores`: el código de la librería se ejecuta
dentro del contrato.

```bash
cast send $S "record(uint256)" 80 --private-key "$PK"
cast send $S "record(uint256)" 250 --private-key "$PK"
cast send $S "record(uint256)" 45 --private-key "$PK"
cast call $S "average()(uint256)"
cast call $S "count()(uint256)"
```

Tres recibos con `status 1 (success)`, `75` y `3`: el 250 entró como 100 y
`(80 + 100 + 45) / 3 = 75`.

Una sola dirección, como con la herencia: las funciones `internal` de una librería se
**copian** en el contrato que las usa al compilar. La librería no se despliega.

## 4. Lo que una librería no puede hacer

| Intento | `forge build` |
| ------- | ------------- |
| Una variable de estado, `uint256 public calls;` | `Error (9957): Library cannot have non-constant state variables` |
| Heredar de una librería, `library Tally is Clamp` | `Error (2571): Libraries cannot be inherited from.` |
| `score.clamp(...)` sin `using Clamp for uint256;` | `Error (9582): Member "clamp" not found or not visible after argument-dependent lookup in uint256.` |

Tampoco puede recibir ETH. Las constantes sí: `uint256 internal constant MAX = 32;` en
una librería se usa como `NombreLibreria.MAX`.

## 5. Funciones `public` y `external` en una librería

Si una función de librería es `public` o `external`, la librería **sí** se despliega
aparte, una vez, y tu contrato la llama con `delegatecall` (semana 10): su código se
ejecuta sobre el storage de tu contrato. Al desplegar hay que **enlazar** (*link*) la
dirección de la librería en el bytecode del contrato. Sirve para librerías grandes que no
caben en el contrato (un contrato tiene un tamaño máximo).

En este bootcamp las funciones de librería son `internal`: sin despliegues extra ni
enlaces, y el código que ejecutas es el que lees.

## 6. Librería, contrato padre o contrato aparte

| Necesitas | Usa |
| --------- | --- |
| Funciones sin estado propio, útiles para contratos sin relación | Librería |
| Estado y reglas que son parte de tu contrato (dueño, abierto o cerrado) | Contrato padre (teoría 01) |
| Algo que se despliega una vez y usan muchos contratos, con su propio estado | Contrato aparte, llamado por su interfaz (teoría 04) |

## 7. Antipatrones y riesgos

- **Fiarse de una librería sin leerla**: su código se ejecuta dentro de tu contrato, con
  tu storage y tu ETH. Una función de `Tally` podría escribir cualquier campo de `self`.
  Revisa una librería igual que tu propio código.
- **Redondeo**: `self.total / self.count` redondea hacia abajo. Con `80`, `100` y `46`, la
  media "real" es 75,33 y devuelve `75`. En cálculos de dinero, decide a favor de quién
  redondeas y **multiplica antes de dividir**: `a / b * c` pierde más que `a * c / b`. Lo
  ves en el ejercicio 03; la semana 22 lo trata como vulnerabilidad.
- **`unchecked` escondido**: una librería de cálculo que usa `unchecked` (semana 05) por
  ahorrar gas puede desbordar sin que lo veas desde tu contrato.
- **Librerías `public` sin necesidad**: añaden un despliegue, un enlace y un
  `delegatecall`, con sus riesgos. Si cabe en el contrato, `internal`.

## 8. Trucos

- `self` como nombre del primer parámetro dice "esta función se usa con `using for`".
- `using Libreria for Tipo global;` a nivel de archivo, junto a la definición del tipo,
  adjunta las funciones en todo archivo que importe el tipo.
- El error de una librería se nombra por la librería: `Tally.Empty.selector` en un test.

## ✅ Checklist

- [ ] Escribo una librería `internal` y la llamo por su nombre y con `using for`.
- [ ] Escribo una función de librería que modifica storage a través de `self`.
- [ ] Explico por qué una librería `internal` no tiene dirección propia.
- [ ] Elijo entre librería, padre o contrato aparte con un ejemplo de cada uno.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 04 — Interfaces](04-interfaces.md) | **Teoría 05 — Librerías** | [Ejercicio 01 — Herencia →](../2-practicas/ejercicio-01-herencia/README.md) |
