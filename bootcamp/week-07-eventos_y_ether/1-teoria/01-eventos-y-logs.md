# Teoría 01 — Eventos y logs

## 🎯 Objetivos

- Declarar un evento y emitirlo con `emit`.
- Leer los logs de una transacción en su recibo y con `cast logs`.
- Explicar qué son los topics, qué hace `indexed` y por qué hay como mucho tres.
- Saber qué no puede hacer un evento: leerse desde un contrato ni sobrevivir a un revert.

---

## 1. Qué problema resuelve

Hasta ahora, para saber qué pasó en tu contrato tenías que preguntarle con `cast call`:
"¿cuánto vale `count`?". Eso dice el estado **actual**, no la historia. Si alguien
registró tres recursos y retiró uno, `cast call` no te cuenta quién, cuándo ni en qué
orden.

Una dApp necesita la historia: mostrar "Alice registró el recurso 3 hace 5 minutos" o
avisar en cuanto alguien registra algo. Preguntar al contrato cada segundo sería lento y,
con el estado actual, ni siquiera bastaría.

Un **evento** es un aviso que el contrato deja escrito durante una transacción. La EVM lo
guarda como un **log** en el recibo de la transacción (el resumen que viste en la semana
02: estado, gas usado, logs). Quien está fuera de la cadena lee esos logs: `cast`, una
dApp (semana 17) o un indexador con base de datos (semana 19).

## 2. Cómo se escribe

Crea `src/Bell.sol` en un proyecto Foundry:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

contract Bell {
    uint256 public rings;

    event Rang(address indexed by, uint256 total);

    function ring() external {
        rings++;
        emit Rang(msg.sender, rings);
    }
}
```

- `event Rang(...)` **declara** el evento: su nombre y sus parámetros. Por convención, el
  nombre va en `PascalCase` y en pasado (`Rang`, `Registered`, `Withdrawn`): cuenta algo
  que ya ocurrió.
- `emit Rang(msg.sender, rings);` lo **emite**: escribe un log con esos valores.
- `indexed` marca un parámetro como buscable (sección 4).

Emitir un evento escribe en el recibo, así que es una modificación: no se puede emitir
desde una función `view`. Con un `emit` dentro de una `view`, el compilador responde:

```
Error (8961): Function cannot be declared as view because this expression (potentially) modifies the state.
 --> src/Bad.sol:9:14:
  |
9 |         emit Rang(msg.sender, rings);
  |              ^^^^^^^^^^^^^^^^^^^^^^^
```

## 3. Dónde queda: el recibo

Con `anvil --silent &` en marcha dentro del contenedor, despliega y llama a `ring()`:

```bash
PK=$(cast wallet private-key "test test test test test test test test test test test junk" 0)
forge create src/Bell.sol:Bell --private-key "$PK" --broadcast
C=0x5FbDB2315678afecb367f032d93F642f64180aa3
cast send $C "ring()" --private-key "$PK"
```

En el recibo aparece una línea `logs`. Para verla limpia, pide el recibo en JSON y quédate
con el primer log (`jq` viene en el contenedor):

```bash
cast send $C "ring()" --private-key "$PK" --json | jq '.logs[0] | {address, topics, data}'
```

```
{
  "address": "0x5fbdb2315678afecb367f032d93f642f64180aa3",
  "topics": [
    "0x568004d1c712e9de32b6bfbe7228d41026359611c76e4d6d4c27807fd7f68a94",
    "0x000000000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb92266"
  ],
  "data": "0x0000000000000000000000000000000000000000000000000000000000000002"
}
```

Un log tiene tres partes:

| Parte | Qué lleva | En el ejemplo |
| ----- | --------- | ------------- |
| `address` | El contrato que lo emitió | `Bell` |
| `topics` | Hasta 4 valores de 32 bytes por los que se puede buscar | El identificador del evento y `by` |
| `data` | El resto de parámetros, codificados en ABI | `total = 2` |

El **topic 0** es el identificador del evento: el keccak256 de su firma, con los tipos y
sin nombres ni `indexed`:

```bash
cast keccak "Rang(address,uint256)"
```

```
0x568004d1c712e9de32b6bfbe7228d41026359611c76e4d6d4c27807fd7f68a94
```

Coincide con `topics[0]`. Dentro de Solidity, ese mismo valor es `Rang.selector`. Cambia
el orden de los tipos y es otro evento: `cast keccak "Rang(uint256,address)"` da
`0xa631c5f0...`.

## 4. `indexed` y la búsqueda

Un parámetro `indexed` va a un topic; los demás, a `data`. La diferencia importa al buscar:
un nodo filtra logs por topic sin leer `data`. Pide todos los `Rang` del contrato:

```bash
cast logs --address $C "Rang(address indexed,uint256)"
```

```
- address: 0x5FbDB2315678afecb367f032d93F642f64180aa3
  ...
  data: 0x0000000000000000000000000000000000000000000000000000000000000001
  ...
  topics: [
  	0x568004d1c712e9de32b6bfbe7228d41026359611c76e4d6d4c27807fd7f68a94
  	0x000000000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb92266
  ]
  ...
  decoded:
  	param0: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
  	param1: 1
- address: 0x5FbDB2315678afecb367f032d93F642f64180aa3
  ...
  	param1: 2
```

(Los `...` sustituyen líneas de hash y número de bloque.) Los dos timbrazos, con quién y
qué total. Si añades una dirección después de la firma, `cast logs` filtra por ese topic y
solo devuelve los timbrazos de esa cuenta.

Las reglas de `indexed`:

- **Como mucho tres parámetros `indexed`.** El topic 0 ya ocupa uno de los cuatro. Con
  cuatro, el compilador se niega:

  ```
  Error (7249): More than 3 indexed arguments for event.
  ```

- **Indexa lo que se busca**: cuentas e identificadores (`address indexed by`,
  `uint256 indexed id`). Las cantidades suelen ir en `data`.
- **Un `string` o `bytes` `indexed` se guarda como su hash keccak256**, no como el texto:
  sirve para filtrar por un valor exacto, pero desde el log ya no puedes recuperar el
  texto. Si lo necesitas leer, déjalo sin `indexed`.

## 5. Lo que un evento no hace

- **Un contrato no puede leer logs**, ni los suyos ni los de otros. Si tu lógica necesita
  un dato, guárdalo en storage. El evento es para quien está fuera.
- **Si la transacción revierte, no queda ningún log.** El revert deshace el estado y
  también los eventos emitidos antes. Un evento solo prueba que la transacción terminó
  bien.
- **No es gratis, pero es barato**: escribir un log cuesta mucho menos gas que guardar el
  mismo dato en storage. Por eso la historia de un protocolo va en eventos y solo el estado
  que la lógica necesita va en storage.

## 6. Antipatrones y riesgos

- **Cambiar estado sin evento**: si `setOpen` cambia una regla y no emite nada, nadie fuera
  del contrato se entera. Una dApp mostraría datos viejos y un usuario no vería que el
  dueño cerró el registro. Todo cambio de estado que importe a alguien emite su evento.
- **Emitir datos que no corresponden**: un evento que dice `Edited(id, viejo, nuevo)` pero
  lee el "viejo" después de sobrescribirlo publica `nuevo` dos veces. Los indexadores se lo
  creen. Lee los valores antes de cambiarlos (lo pruebas en el ejercicio 01).
- **Fiarse de un evento sin mirar quién lo emitió**: cualquier contrato puede declarar un
  evento llamado igual y con los mismos parámetros, y su topic 0 es el mismo. Quien lee
  logs filtra siempre por `address`, no solo por el nombre del evento.

## 7. Trucos

- `cast keccak "Evento(tipos)"` te da el topic 0 para filtrar a mano o comprobar un log.
- `emit` va al final de la función, cuando el cambio ya está hecho: así el evento cuenta lo
  que de verdad quedó guardado.
- En los tests, `vm.expectEmit()` seguido de un `emit` con los valores esperados comprueba
  que la siguiente llamada emite exactamente ese evento (la usan los tests de esta
  semana).

## ✅ Checklist

- [ ] Declaro un evento y lo emito al final de una función.
- [ ] Encuentro el log en el recibo y explico `address`, `topics` y `data`.
- [ ] Calculo el topic 0 con `cast keccak` y sé que es `Evento.selector`.
- [ ] Sé por qué hay como mucho tres `indexed` y qué indexar.
- [ ] Explico por qué un contrato no lee logs y por qué un revert los borra.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Semana 07](../README.md) | **Teoría 01 — Eventos y logs** | [Teoría 02 — Unidades y variables globales →](02-unidades-y-variables-globales.md) |
