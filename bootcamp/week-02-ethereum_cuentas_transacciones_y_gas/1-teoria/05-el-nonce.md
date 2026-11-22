# Teoría 05 — El nonce

## 🎯 Objetivos

- Explicar qué ataque evita el nonce y por qué tiene que ser consecutivo.
- Predecir qué hace el nodo con un nonce repetido, con un hueco y con un reemplazo.
- Explicar para qué sirve el chain id en la firma.
- Reconocer los errores `nonce too low`, `replacement transaction underpriced` e
  `invalid chain id for signer`.

---

## 1. Qué problema resuelve el nonce

Una transacción firmada es pública: está en el mempool y en la cadena. Si solo llevara
"envía 1 ETH a Bob" y una firma válida, cualquiera podría copiarla y enviarla otra vez, y
otra, hasta vaciar tu cuenta. Es el **ataque de repetición** (*replay attack*).

El **nonce** (de *number used once*, "número que se usa una vez") lo impide. Cada cuenta
externa tiene un contador (el campo `nonce` de la Teoría 02) y cada transacción lleva el
número que le toca. La regla del nodo:

> Una transacción solo se ejecuta si su nonce es **exactamente** el nonce actual de la
> cuenta. Al ejecutarse, el nonce de la cuenta sube en 1.

Una transacción ya ejecutada lleva un nonce viejo: repetirla no sirve. Y como el nonce está
dentro de lo firmado, cambiarlo invalida la firma.

La regla también fija el **orden**: la transacción 3 de una cuenta nunca se ejecuta antes
que la 2.

## 2. El nonce sube con cada transacción

**Dónde**: en el contenedor, con anvil recién arrancado (`anvil --silent &`). En los
bloques siguientes, `PK` y `TO` son la clave de la cuenta 0 y la dirección de la cuenta 1:

```bash
PK=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
TO=0x70997970C51812dc3A010C7d01b50e0d17dc79C8
cast send --private-key "$PK" "$TO" --value 1ether >/dev/null
cast nonce 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
```

```
1
```

`cast send` pidió al nodo el nonce (`0`), lo puso en la transacción y, al minarse, la
cuenta pasó a `1`. El nonce de la cuenta es siempre **el de la próxima transacción** y, a
la vez, cuántas lleva enviadas.

## 3. Nonce repetido: rechazado

Fuerza el nonce `0`, que ya se usó:

```bash
cast send --private-key "$PK" "$TO" --value 1 --nonce 0
```

```
Error: server returned an error response: error code -32003: nonce too low
```

El nodo ni siquiera la guarda en el mempool. Es la protección contra la repetición en
acción.

## 4. Un hueco: la transacción espera

Ahora un nonce **adelantado**. La cuenta está en `1`; envía una con nonce `5`.
`--async` hace que `cast` no espere el recibo, que no va a llegar:

```bash
cast send --async --private-key "$PK" "$TO" --value 1 --nonce 5
cast nonce 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
cast rpc txpool_status
```

```
0x508ad408044dfb2e3214880d020da24ad1cdba41ff8feb583486c84d25ad68a6
1
{"pending":"0x0","queued":"0x1"}
```

La transacción es válida (tiene hash) pero no se ejecuta: faltan las de nonce 1, 2, 3 y 4.
El nodo la deja **en cola** (*queued*) en el mempool. `txpool_status` cuenta las que están
listas para minarse (`pending`) y las que esperan un hueco (`queued`).

Cuando llegan las que faltan, las de la cola se ejecutan solas, en orden. Lo compruebas en
el ejercicio 03.

## 5. Reemplazar una transacción

Mientras una transacción no se ha minado, puedes **reemplazarla**: envías otra con el
**mismo nonce**. Solo una de las dos llegará a ejecutarse. El nodo exige que la nueva pague
más; si no, cualquiera podría inundarlo de reemplazos gratis:

```bash
cast send --async --private-key "$PK" "$TO" --value 2 --nonce 5
```

```
Error: server returned an error response: error code -32003: replacement transaction underpriced
```

Con precios más altos (los precios del gas se explican en la Teoría 06):

```bash
cast send --async --private-key "$PK" "$TO" --value 2 --nonce 5 \
  --gas-price 10gwei --priority-gas-price 5gwei
cast rpc txpool_status
```

```
0x2969d0c21804a2d801a984ec6de215c86dca5e5a44835d2f9507878e9befc3be
{"pending":"0x0","queued":"0x1"}
```

Hay un hash nuevo y sigue habiendo **una** en cola: la nueva sustituyó a la vieja. Así se
**acelera** una transacción atascada (mismo contenido, más precio) o se **cancela**
(una transferencia de 0 ETH a ti mismo con el mismo nonce).

## 6. El chain id: no vale en otra red

El nonce protege dentro de una red. Pero la cuenta 0 existe en todas las redes Ethereum,
con nonces distintos en cada una. Sin más protección, una transacción firmada para una
testnet podría repetirse en mainnet cuando el nonce coincidiera.

Por eso la transacción lleva el **chain id** dentro de lo firmado
([EIP-155](https://eips.ethereum.org/EIPS/eip-155)). Firma una para mainnet (`--chain 1`)
y envíala a anvil (31337):

```bash
RAW=$(cast mktx --private-key "$PK" "$TO" --value 1 \
  --nonce 1 --gas-limit 21000 --gas-price 2gwei --priority-gas-price 1gwei --chain 1)
cast publish "$RAW"
```

```
Error: server returned an error response: error code -32003: invalid chain id for signer
```

El nonce `1` era el correcto; la red, no.

## 7. Antipatrones y riesgos

- ❌ **Calcular el nonce a mano en un programa que envía varias transacciones a la vez.**
  Dos envíos que leen el mismo nonce producen dos transacciones con el mismo número: una
  reemplaza a la otra o se rechaza. Usa un solo emisor por cuenta, o pide el nonce
  `pending` y llévalo tú en orden.
- ❌ **Ignorar una transacción atascada.** Con un hueco o un precio demasiado bajo, todas
  las siguientes de la cuenta quedan detrás. Reemplázala.
- ❌ **Firmar sin chain id.** Las transacciones antiguas (anteriores al EIP-155) no lo
  llevan y se pueden repetir en cualquier red. `cast` siempre lo incluye.
- ❌ **Confundir el nonce de una transacción con el nonce del bloque.** El bloque también
  tiene un campo `nonce` (herencia de la prueba de trabajo, hoy siempre cero). No tienen
  nada que ver.

## 8. Trucos

- `cast nonce --block pending DIR` cuenta también las transacciones del mempool listas para
  minarse: es el nonce que debe llevar la siguiente.
- `cast rpc txpool_content` muestra las transacciones en espera, agrupadas por cuenta y
  nonce.
- Si te lías con nonces en anvil, reinícialo: todo vuelve a 0.

## ✅ Checklist

- [ ] Explico el ataque de repetición y cómo lo evita el nonce.
- [ ] Sé qué hace el nodo con un nonce usado, uno adelantado y uno repetido con más precio.
- [ ] Acelero o cancelo una transacción atascada reemplazándola.
- [ ] Explico por qué el chain id va dentro de lo firmado.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 04 — Transacciones](04-transacciones.md) | **Teoría 05 — El nonce** | [Teoría 06 — Gas y EIP-1559 →](06-gas-y-eip-1559.md) |
