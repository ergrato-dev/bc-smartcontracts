# Ejercicio 01 — Leer la cadena

> Al terminar habrás hablado con un nodo de dos formas, con JSON-RPC a mano (`curl`) y con
> `cast`, y habrás leído el chain id, un saldo en wei y en ether, y el nonce y el código de
> una cuenta.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teorías 01 a 03](../../1-teoria/01-ethereum-y-anvil.md) leídas.

## Contexto

Mismo formato que en la semana 01: `pasos.sh` tiene una función por paso (`step1`,
`step2`...) y `test.sh` ejecuta cada una y compara su salida con la esperada.

La novedad: ahora los pasos hablan con un **nodo**. `test.sh` arranca su propio anvil en el
puerto 8546, uno nuevo para cada paso, y lo para al terminar. Para probar un paso suelto con
`bash pasos.sh N` necesitas tu anvil en el 8545.

`pasos.sh` trae dos variables escritas:

| Variable | Qué es |
| -------- | ------ |
| `RPC` | La URL del nodo: la de `ETH_RPC_URL` si existe (la pone `test.sh`), si no `http://localhost:8545` |
| `ADDR` | Dirección de la cuenta 0 de anvil |

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-02-ethereum_cuentas_transacciones_y_gas/2-practicas/ejercicio-01-leer-la-cadena/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
anvil --silent &
bash test.sh
```

**Verifica**: seis `❌` y `0 de 6 pasos correctos`. Cada `obtenido:` dice `TODO: Paso N`.

## Paso 1: JSON-RPC a mano

**Por qué**: ver el protocolo sin intermediarios. Todo lo que hace `cast` se reduce a
peticiones como esta.

```bash
step1() {
  curl -s -X POST -H 'Content-Type: application/json' \
    --data '{"jsonrpc":"2.0","id":1,"method":"eth_chainId","params":[]}' "$RPC"
}
```

**Abre** `pasos.sh`, borra la línea `todo "Paso 1"` y quita el `#> ` de las líneas del
paso.

**Verifica**: `bash pasos.sh 1` imprime `{"jsonrpc":"2.0","id":1,"result":"0x7a69"}` y
`bash test.sh` marca `✅ Paso 1`.

## Paso 2: El mismo dato con cast

**Por qué**: `cast chain-id` hace la misma petición y convierte el hex a decimal.

```bash
step2() {
  cast chain-id
}
```

**Verifica**: `✅ Paso 2` con `31337`. Comprueba a mano que `cast to-dec 0x7a69` da lo
mismo.

## Paso 3: Un método con parámetros

**Por qué**: la mayoría de métodos necesitan datos: aquí, la cuenta y el bloque. `jq -r
.result` se queda con el campo que importa.

```bash
step3() {
  curl -s -X POST -H 'Content-Type: application/json' \
    --data "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"eth_getBalance\",\"params\":[\"$ADDR\",\"latest\"]}" \
    "$RPC" | jq -r .result
}
```

| Pieza | Qué hace |
| ----- | -------- |
| `"...$ADDR..."` | Comillas dobles para que bash sustituya `$ADDR`; por eso las comillas del JSON van escapadas (`\"`) |
| `"latest"` | Lee el saldo en el último bloque minado |
| `jq -r .result` | Extrae `result` sin comillas |

**Verifica**: `✅ Paso 3` con `0x21e19e0c9bab2400000`.

## Paso 4: De hex a wei

**Por qué**: los nodos devuelven números en hex (Teoría 03); las personas y los scripts
los necesitan en decimal.

```bash
step4() {
  cast to-dec "$(step3)"
}
```

**Verifica**: `✅ Paso 4` con `10000000000000000000000`. Cuenta los ceros: 4 + 18, es
decir, 10 000 × 10¹⁸ wei.

## Paso 5: El saldo en ether

**Por qué**: para leer cantidades a ojo, ether; para operar, wei.

```bash
step5() {
  cast balance --ether "$ADDR"
}
```

**Verifica**: `✅ Paso 5` con `10000.000000000000000000`.

## Paso 6: Nonce y código

**Por qué**: los otros dos campos de una cuenta que se leen con `cast`. Una cuenta externa
sin transacciones tiene nonce 0 y no tiene código.

```bash
step6() {
  echo "$(cast nonce "$ADDR") $(cast code "$ADDR")"
}
```

**Verifica**: `✅ Paso 6` con `0 0x` y `6 de 6 pasos correctos`.

## ✅ Criterios de éxito

- `bash test.sh` termina con `6 de 6 pasos correctos`.
- Explicas qué hace `cast balance` por dentro (método, parámetros y conversión).
- Explicas por qué el nodo devuelve los números como texto hexadecimal.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 07 — La EVM y los contratos](../../1-teoria/07-la-evm-y-los-contratos.md) | **Ejercicio 01 — Leer la cadena** | [Ejercicio 02 — Una transacción paso a paso →](../ejercicio-02-una-transaccion-paso-a-paso/README.md) |
