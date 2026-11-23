# Ejercicio 02 — Keystore y broadcast

> Al terminar habrás guardado una clave en un keystore cifrado, mirado qué hay dentro, firmado
> con él un `forge script` simulado y otro emitido, y leído el registro de la ejecución.

**Duración estimada**: 2 h
**Prerrequisitos**: [Ejercicio 01](../ejercicio-01-primer-script/README.md) terminado;
[Teoría 02 — Claves y keystores](../../1-teoria/02-claves-y-keystores.md) leída.

## Contexto

Ejercicio de terminal, como los de las semanas 02 y 03: cada paso es una función de `pasos.sh`
con `todo "Paso N"` y la solución en líneas `#> `. Resolver un paso es borrar la línea `todo` y
quitar el `#> `.

| Archivo | Qué es |
| ------- | ------ |
| `pasos.sh` | Los seis pasos. Aquí trabajas. Trae `PK`, la clave de la cuenta 3 de anvil |
| `test.sh` | Ejecuta cada paso y compara su salida. **No lo modifiques** |
| `contrato/` | El proyecto del ejercicio 01, ya resuelto: `Box` y `DeployBox` |

`pasos.sh` crea en cada ejecución una carpeta temporal para los keystores (`KEYSTORES`) y un
archivo con la contraseña (`PASSWORD_FILE`), y los borra al terminar. Así no toca tu
`~/.foundry/keystores` y cada paso empieza sin keystores. Por eso los pasos que necesitan el
keystore llaman antes a `step1`.

`test.sh` arranca su propio anvil en el puerto 8546, nuevo para cada paso. Para probar un paso a
mano, `bash pasos.sh N` con tu anvil en el 8545 (`anvil --silent &`); desde el paso 5, reinícialo
entre prueba y prueba (`kill %1` y `anvil --silent &`), o las direcciones cambian.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-16-despliegue_y_verificacion/2-practicas/ejercicio-02-keystore-y-broadcast/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
bash test.sh
```

**Verifica**: seis `❌` y `0 de 6 pasos correctos`.

## Paso 1: Guardar la clave en un keystore

**Por qué**: a partir de aquí, la clave solo existe cifrada en un archivo. Para firmar, `cast` y
`forge` la descifran en memoria con la contraseña.

```bash
step1() {
  cast wallet import dev --private-key "$PK" --keystore-dir "$KEYSTORES" \
    --unsafe-password "$(cat "$PASSWORD_FILE")" >/dev/null
  cast wallet address --keystore "$KEYSTORES/dev" --password-file "$PASSWORD_FILE"
}
```

`--keystore-dir` elige la carpeta (sin él, `~/.foundry/keystores`) y `--keystore <archivo>` dice
qué keystore abrir. Con los de `~/.foundry/keystores` usarías `--account dev`.

**Abre** `pasos.sh` y resuelve `step1`.

**Verifica**: `✅ Paso 1` con `0x90F79bf6EB2c4f870365E785982E1f101E93b906`, la dirección de la
cuenta 3, sacada del keystore y no de la clave.

## Paso 2: Qué hay dentro

**Por qué**: comprobar con tus ojos que el archivo no guarda la clave en claro, y con qué la
protege.

```bash
step2() {
  step1 >/dev/null
  jq -r '.crypto.kdf + " " + .crypto.cipher' "$KEYSTORES/dev"
  grep -c "${PK#0x}" "$KEYSTORES/dev"
}
```

`${PK#0x}` es la clave sin el `0x`; `grep -c` cuenta las líneas en las que aparece.

**Verifica**: `✅ Paso 2` con `scrypt aes-128-ctr` y `0`. El archivo entero es como el de la
teoría 02, con otra sal, otro `iv` y otro `ciphertext`: cambian en cada importación.

## Paso 3: Otra contraseña

**Por qué**: el campo `mac` detecta una contraseña equivocada sin descifrar nada.

```bash
step3() {
  step1 >/dev/null
  cast wallet address --keystore "$KEYSTORES/dev" --password otra 2>&1 | grep -o "Mac Mismatch"
}
```

**Verifica**: `✅ Paso 3` con `Mac Mismatch`. El error completo es
`Error: Failed to decrypt keystore` seguido de `- Mac Mismatch`.

## Paso 4: Simular con el keystore

**Por qué**: el mismo comando que emitirá, sin `--broadcast`. Comprueba que el keystore abre y
que el script no revierte, y no gasta nada.

```bash
step4() {
  local me
  me=$(step1)
  forge script --root contrato contrato/script/DeployBox.s.sol --rpc-url "$RPC" \
    --keystore "$KEYSTORES/dev" --password-file "$PASSWORD_FILE" >/dev/null
  echo "$(cast nonce "$me" --rpc-url "$RPC")" \
    "$(jq '.transactions | length' contrato/broadcast/DeployBox.s.sol/31337/dry-run/run-latest.json)"
}
```

`--root contrato` hace que `forge` trabaje sobre esa carpeta; la ruta del script se da desde
donde estás. No hace falta `--sender`: forge saca la dirección del keystore.

**Verifica**: `✅ Paso 4` con `0 2`. Nonce 0, porque no se envió nada, y dos transacciones
preparadas en `dry-run/run-latest.json`.

## Paso 5: Emitir

**Por qué**: ahora sí. Con `--broadcast`, forge firma con el keystore y envía.

```bash
step5() {
  local me box
  me=$(step1)
  forge script --root contrato contrato/script/DeployBox.s.sol --rpc-url "$RPC" \
    --keystore "$KEYSTORES/dev" --password-file "$PASSWORD_FILE" --broadcast >/dev/null
  box=$(jq -r '.transactions[0].contractAddress' contrato/broadcast/DeployBox.s.sol/31337/run-latest.json)
  echo "$(cast nonce "$me" --rpc-url "$RPC") $(cast call "$box" "value()(uint256)" --rpc-url "$RPC")"
}
```

La dirección de la Box no se copia de la salida: se lee del registro de la ejecución.

**Verifica**: `✅ Paso 5` con `2 1`. Dos transacciones enviadas y el número por defecto, 1.

## Paso 6: Leer el registro

**Por qué**: `run-latest.json` es la lista de lo que hiciste en una red: qué se creó, qué se
llamó, con qué argumentos y cómo acabó cada transacción. En el proyecto, el de Sepolia irá a tu
repositorio.

```bash
step6() {
  step1 >/dev/null
  INITIAL_VALUE=42 forge script --root contrato contrato/script/DeployBox.s.sol --rpc-url "$RPC" \
    --keystore "$KEYSTORES/dev" --password-file "$PASSWORD_FILE" --broadcast >/dev/null
  jq -r '.transactions[] | "\(.transactionType) \(.function // .contractName) \(.arguments | join(","))"' \
    contrato/broadcast/DeployBox.s.sol/31337/run-latest.json
  jq -r '[.receipts[].status] | join(" ")' contrato/broadcast/DeployBox.s.sol/31337/run-latest.json
}
```

`.function // .contractName` da la función si es una llamada y el contrato si es una creación.

**Verifica**: `✅ Paso 6` con:

```
CREATE Box 0x90F79bf6EB2c4f870365E785982E1f101E93b906
CALL store(uint256) 42
0x1 0x1
```

El argumento del constructor (el dueño), el de `store` y dos recibos con estado `0x1`, éxito.
Y `6 de 6 pasos correctos`.

## Qué aprendiste

- `cast wallet import` cifra una clave; `--keystore`/`--account` firman con ella.
- Un keystore guarda `scrypt`, `aes-128-ctr` y un `mac`, nunca la clave en claro.
- La misma orden simula sin `--broadcast` y emite con él.
- Las direcciones de un despliegue se leen de `run-latest.json`, no de la pantalla.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 01 — Primer script](../ejercicio-01-primer-script/README.md) | **Ejercicio 02 — Keystore y broadcast** | [Ejercicio 03 — Verificación por dentro →](../ejercicio-03-verificacion-por-dentro/README.md) |
