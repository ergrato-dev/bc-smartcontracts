# Teoría 01 — Ethereum y anvil

## 🎯 Objetivos

- Explicar qué añade Ethereum a la idea de blockchain de la semana 01.
- Distinguir red, nodo y cliente.
- Arrancar **anvil**, una blockchain local, dentro del contenedor.
- Leer su salida de arranque: cuentas, claves, chain id, base fee y gas limit.
- Dejar anvil en segundo plano y trabajar en la misma terminal.

---

## 1. Qué problema resuelve Ethereum

La semana 01 terminó con un registro compartido: bloques encadenados por hashes, firmados
por quien envía cada operación. Bitcoin usa esa estructura para una sola cosa: llevar la
cuenta de quién tiene cuántas monedas.

Ethereum generaliza la idea. En lugar de un registro de saldos, mantiene un **estado**
compartido: una gran tabla que, para cada dirección, guarda su saldo y, si la dirección es
un programa, su código y sus datos. Cada bloque contiene **transacciones**, y cada
transacción es una petición firmada para cambiar ese estado: mover ETH, crear un programa
o ejecutar uno que ya existe.

Esos programas son los **smart contracts** (contratos inteligentes): código que vive en la
blockchain, que cualquiera puede llamar y que se ejecuta igual en todos los nodos. Nadie
puede cambiar su resultado ni apagarlo. Escribirás el primero en la semana 03.

> **ETH** (ether) es la moneda nativa de Ethereum. Sirve para dos cosas: tener valor y
> pagar por usar la red (el *gas*, Teoría 06).

## 2. Red, nodo y cliente

| Término | Qué es |
| ------- | ------ |
| **Red** | El conjunto de computadoras que guardan la misma cadena. *Mainnet* es la red principal, donde el ETH tiene valor real |
| **Nodo** | Una computadora de la red: guarda la cadena, valida bloques y atiende peticiones |
| **Cliente** | Un programa que habla con un nodo para leer datos o enviarle transacciones. `cast` es un cliente |
| **Testnet** | Una red pública de pruebas (por ejemplo Sepolia): funciona como mainnet, pero su ETH no vale nada. La usarás en la semana 16 |

Tu programa nunca toca la cadena directamente: le pide cosas a un nodo. Para aprender no
necesitas una red entera; te basta **un nodo local** que se comporte como Ethereum.

## 3. anvil: Ethereum en tu máquina

**anvil** es el nodo local de Foundry. Simula una blockchain Ethereum completa en un solo
proceso:

- Arranca en menos de un segundo con 10 cuentas con 10 000 ETH de prueba cada una.
- **Mina** (crea un bloque nuevo) en cuanto recibe una transacción: no esperas 12 segundos
  como en mainnet.
- Al cerrarlo, todo se pierde. Cada arranque empieza desde cero, siempre igual.

Eso último es lo que permite que los tests de esta semana comparen salidas exactas: misma
cadena inicial y mismas transacciones dan los mismos hashes.

## 4. Arrancar anvil

**Dónde**: en el contenedor, desde cualquier carpeta.

```bash
docker run --rm -it bc-smartcontracts-dev
anvil
```

La salida empieza con el logo y la versión, y sigue con las cuentas:

```
Available Accounts
==================

(0) 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 (10000.000000000000000000 ETH)
(1) 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 (10000.000000000000000000 ETH)
(2) 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC (10000.000000000000000000 ETH)
(3) 0x90F79bf6EB2c4f870365E785982E1f101E93b906 (10000.000000000000000000 ETH)
...
```

Son las mismas direcciones que derivaste en la semana 01 desde la frase
`test test ... junk`. Más abajo están sus claves privadas y la frase:

```
Private Keys
==================

(0) 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
...

Wallet
==================
Mnemonic:          test test test test test test test test test test test junk
Derivation path:   m/44'/60'/0'/0/
```

Y al final, los datos de la cadena:

```
Chain ID
==================

31337

Base Fee
==================

1000000000

Gas Limit
==================

30000000
...
Listening on 0.0.0.0:8545
```

| Dato | Qué significa | Dónde se explica |
| ---- | ------------- | ---------------- |
| Chain ID `31337` | Número que identifica la red. Mainnet es `1`; anvil usa `31337` | Teoría 05 |
| Base Fee `1000000000` | Precio mínimo del gas en el primer bloque, en wei | Teoría 06 |
| Gas Limit `30000000` | Trabajo máximo que cabe en un bloque | Teoría 06 |
| `Listening on 0.0.0.0:8545` | anvil espera peticiones en el puerto 8545 | Teoría 03 |

La terminal queda ocupada: anvil sigue corriendo hasta que pulsas `Ctrl+C`. Púlsalo ahora.

## 5. anvil en segundo plano

Necesitas anvil corriendo **y** una terminal libre para enviarle comandos. En bash, un `&`
al final de un comando lo lanza en **segundo plano** (*background*):

**Dónde**: en el contenedor.

```bash
anvil --silent &
cast block-number
```

Salida de `cast block-number`:

```
0
```

| Pieza | Qué hace |
| ----- | -------- |
| `--silent` | anvil no escribe nada en la terminal (si no, sus mensajes se mezclan con los tuyos) |
| `&` | Lanza el proceso en segundo plano y te devuelve el prompt |
| `cast block-number` | Pregunta al nodo en qué bloque va la cadena: `0`, el bloque inicial o **génesis** |

`cast` busca el nodo en `http://localhost:8545` si no le dices otra cosa. Para pararlo:

```bash
jobs        # lista los procesos en segundo plano: [1]+  Running  anvil --silent &
kill %1     # termina el proceso número 1
```

**Volver a empezar** es lo mismo que parar y arrancar: `kill %1` y `anvil --silent &`. Lo
harás a menudo para partir de una cadena limpia.

> Si abres otra terminal y entras con otro `docker run`, es **otro contenedor**: no ve el
> anvil del primero. Para una segunda terminal sobre el mismo contenedor usa
> `docker exec -it <id> bash` (el `<id>` sale en `docker ps`).

## 6. Los tests usan su propio anvil

Los `test.sh` de esta semana arrancan **otro** anvil en el puerto 8546 antes de cada paso
y lo paran al terminar. Así cada paso parte de la cadena recién creada y no toca el anvil
que tengas abierto en el 8545. Lo hacen exportando la variable de entorno
`ETH_RPC_URL=http://localhost:8546`, que `cast` lee sola.

## 7. Antipatrones y riesgos

- ❌ **Usar las cuentas de anvil fuera de anvil.** Sus claves están publicadas en todas
  partes. Hay programas que vigilan mainnet y vacían al instante cualquier ETH que llegue
  a esas direcciones.
- ❌ **Dar por hecho que mainnet se comporta como anvil.** anvil mina al instante y no
  tiene competencia por entrar en un bloque. En una red real una transacción puede tardar,
  quedarse atascada o no entrar nunca (Teorías 05 y 06).
- ❌ **Guardar algo importante en anvil.** Al pararlo se pierde todo.

## 8. Trucos

- `anvil --help` lista todas sus opciones. Algunas útiles: `--balance 5` (saldo inicial de
  cada cuenta, en ETH), `--block-time 2` (mina un bloque cada 2 segundos en lugar de al
  instante), `--port 8546` (otro puerto).
- `cast rpc anvil_mine 3` mina 3 bloques vacíos. Comprueba con `cast block-number`.

## ✅ Checklist

- [ ] Explico qué añade Ethereum a un registro de saldos.
- [ ] Distingo red, nodo, cliente y testnet.
- [ ] Arranco anvil en segundo plano y lo paro con `kill %1`.
- [ ] Sé qué significan chain id, base fee y gas limit en la salida de anvil.
- [ ] Explico por qué las claves de anvil nunca deben recibir ETH real.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Semana 02](../README.md) | **Teoría 01 — Ethereum y anvil** | [Teoría 02 — Cuentas y unidades →](02-cuentas-y-unidades.md) |
