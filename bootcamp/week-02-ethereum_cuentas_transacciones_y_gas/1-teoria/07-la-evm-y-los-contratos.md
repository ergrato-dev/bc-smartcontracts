# Teoría 07 — La EVM y los contratos

## 🎯 Objetivos

- Explicar qué es la EVM y qué es el bytecode de un contrato.
- Crear un contrato con una transacción sin destino y predecir su dirección.
- Distinguir el código de creación del código que queda desplegado.
- Llamar a un contrato sin transacción (`cast call`) y con transacción (`cast send`).
- Leer los campos principales de un bloque.

---

## 1. Qué problema resuelve la EVM

Un contrato es un programa que ejecutan todos los nodos, y todos tienen que obtener
**exactamente** el mismo resultado, con el mismo gas consumido. Eso no lo garantiza
ejecutar Python o JavaScript en máquinas distintas: cambian las versiones, los números en
coma flotante, el acceso a archivos y a la red.

La **EVM** (*Ethereum Virtual Machine*, máquina virtual de Ethereum) es una computadora
simulada, idéntica en todos los nodos. Ejecuta **bytecode**: una secuencia de bytes donde
cada byte es una instrucción, un **opcode** (código de operación), con un coste de gas
fijo. Sin reloj, sin azar, sin archivos ni red: solo el estado de la cadena y los datos de
la transacción. Por eso es determinista.

Nadie escribe bytecode a mano. Desde la semana 03 escribirás Solidity y el compilador lo
traducirá a bytecode. Hoy lo ves en crudo una vez para entender qué se despliega.

## 2. Un contrato de 10 bytes

Este bytecode es un contrato completo que, al llamarlo, devuelve el número 42:

```
602a60005260206000f3
```

`cast disassemble` lo traduce a opcodes legibles.

**Dónde**: en el contenedor (no necesita anvil).

```bash
cast disassemble 0x602a60005260206000f3
```

```
00000000: PUSH1 0x2a
00000002: PUSH1 0x00
00000004: MSTORE
00000005: PUSH1 0x20
00000007: PUSH1 0x00
00000009: RETURN
```

| Opcodes | Qué hacen |
| ------- | --------- |
| `PUSH1 0x2a`, `PUSH1 0x00` | Ponen 42 y 0 en la **pila** (*stack*), la zona de trabajo de la EVM |
| `MSTORE` | Guarda 42 en la **memoria** temporal, en la posición 0 (ocupa 32 bytes) |
| `PUSH1 0x20`, `PUSH1 0x00`, `RETURN` | Devuelven 32 bytes (0x20) desde la posición 0 |

La semana 27 entra en la pila, la memoria y los opcodes a fondo. Hoy basta con la idea:
un contrato es una lista de instrucciones que la EVM ejecuta una tras otra.

## 3. Crear un contrato

Una transacción **sin `to`** crea un contrato. Su `input` no es el contrato en sí, sino el
**código de creación** (*init code*): un programa que se ejecuta una sola vez y **devuelve**
el código que quedará guardado, el **código desplegado** (*runtime code*).

```bash
cast disassemble 0x600a600c600039600a6000f3602a60005260206000f3
```

```
00000000: PUSH1 0x0a
00000002: PUSH1 0x0c
00000004: PUSH1 0x00
00000006: CODECOPY
00000007: PUSH1 0x0a
00000009: PUSH1 0x00
0000000b: RETURN
0000000c: PUSH1 0x2a
...
```

Las 7 primeras instrucciones copian 10 bytes (0x0a) desde la posición 12 (0x0c) del
propio código a la memoria y los devuelven. Desde la posición 12 está, entero, el contrato
de 10 bytes de la sección 2. En Solidity, el código de creación también ejecuta el
**constructor** (semana 04).

## 4. La dirección del contrato

Un contrato no tiene clave privada, así que su dirección no puede salir de una clave
(Teoría 02). Se calcula a partir de **quién lo crea y con qué nonce**: el keccak256 de la
dirección del creador y su nonce, quedándose con 20 bytes. Se puede conocer antes de
desplegar.

**Dónde**: en el contenedor, con anvil recién arrancado (`anvil --silent &`).

```bash
cast compute-address --nonce 0 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
```

```
0x5FbDB2315678afecb367f032d93F642f64180aa3
```

Ahora despliega con `--create`, que envía una transacción sin `to` con ese `input`:

```bash
PK=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
cast send --private-key "$PK" --create 0x600a600c600039600a6000f3602a60005260206000f3
```

Líneas del recibo:

```
contractAddress      0x5FbDB2315678afecb367f032d93F642f64180aa3
gasUsed              55330
status               1 (success)
```

La dirección coincide con la calculada. Verás `0x5FbDB2315678afecb367f032d93F642f64180aa3`
muchas veces: es el primer contrato que despliega la cuenta 0 en cualquier anvil nuevo.

Crear cuesta mucho más que transferir (55 330 frente a 21 000): se paga la creación, los
bytes del código y guardar el código en el estado.

## 5. Una cuenta de contrato

```bash
C=0x5FbDB2315678afecb367f032d93F642f64180aa3
cast code "$C"
cast nonce "$C"
```

```
0x602a60005260206000f3
1
```

Ahora `cast code` no devuelve `0x`: es una cuenta de contrato, con el código desplegado
(solo los 10 bytes, no el de creación). Los contratos empiezan con nonce 1; en ellos el
nonce cuenta los contratos que crean.

## 6. Llamar sin transacción y con transacción

`cast call` pide al nodo que **ejecute** el contrato en su copia local y le devuelva el
resultado (método `eth_call`). No firma nada, no se mina, no cuesta gas ni cambia el
estado:

```bash
cast call "$C"
cast to-dec "$(cast call "$C")"
```

```
0x000000000000000000000000000000000000000000000000000000000000002a
42
```

Los 32 bytes de la sección 2, con el 42 (0x2a) al final.

`cast send` al contrato, en cambio, es una transacción: se firma, se mina y se paga.

```bash
H=$(cast send --private-key "$PK" "$C" --json | jq -r .transactionHash)
cast receipt "$H" gasUsed
```

```
21018
```

21 000 de base más 18 de ejecutar los seis opcodes. Lo que el contrato devuelve no queda
en el recibo: una transacción sirve para **cambiar** estado, y para **leer** se usa
`cast call`.

## 7. Los bloques

Un bloque agrupa transacciones ya ejecutadas. Campos que importan desde ya:

```bash
cast block 1 --field number
cast block 1 --field gasUsed
cast block 1 --field baseFeePerGas
```

```
1
55330
1000000000
```

El bloque 1 contiene solo la creación del contrato: su gas usado es el de esa transacción.

| Campo | Qué es |
| ----- | ------ |
| `number` | Posición en la cadena |
| `parentHash` | Hash del bloque anterior: el enlace de la semana 01 |
| `timestamp` | Hora del bloque, en segundos desde 1970. La fija quien lo construye |
| `gasLimit`, `gasUsed` | Capacidad del bloque y cuánta se usó (Teoría 06) |
| `baseFeePerGas` | Base fee del bloque (Teoría 06) |
| `miner` | Quién recibe las propinas (en anvil, la dirección cero) |
| `transactions` | Hashes de las transacciones, en el orden en que se ejecutaron |

`cast block 1` muestra todos. En mainnet sale un bloque cada 12 segundos; anvil, por
defecto, mina uno por transacción.

## 8. Antipatrones y riesgos

- ❌ **Creer que un contrato desplegado se puede corregir.** El código desplegado no cambia
  nunca. Un error en él es para siempre (la semana 15 enseña cómo se diseña para poder
  actualizar, y sus riesgos).
- ❌ **Enviar ETH a una dirección de contrato sin saber qué hace.** Puede rechazarlo, o
  aceptarlo sin forma de sacarlo. Semana 07.
- ❌ **Usar `cast send` para leer.** Pagas gas y no obtienes el valor devuelto. Para leer,
  `cast call`.
- ❌ **Desplegar bytecode que no entiendes.** Un contrato hace exactamente lo que dice su
  bytecode, no lo que dice su nombre. Desde la semana 16 aprenderás a verificar el código
  fuente de un contrato publicado.

## 9. Trucos

- `cast compute-address --nonce N DIR` predice la dirección del contrato que `DIR` creará
  con su transacción de nonce `N`.
- Si `cast code DIR` devuelve `0x`, en esa dirección no hay contrato (todavía).
- [evm.codes](https://www.evm.codes/) lista cada opcode con su gas y permite ejecutar
  bytecode paso a paso.

## ✅ Checklist

- [ ] Explico qué es la EVM y por qué tiene que ser determinista.
- [ ] Distingo código de creación y código desplegado.
- [ ] Predigo la dirección de un contrato antes de crearlo.
- [ ] Sé cuándo usar `cast call` y cuándo `cast send`.
- [ ] Leo los campos principales de un bloque.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 06 — Gas y EIP-1559](06-gas-y-eip-1559.md) | **Teoría 07 — La EVM y los contratos** | [Ejercicio 01 — Leer la cadena →](../2-practicas/ejercicio-01-leer-la-cadena/README.md) |
