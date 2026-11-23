# Ejercicio 03 — Verificación por dentro

> Al terminar habrás comparado el código de una Box desplegada con el que da el compilador,
> encontrado el immutable y los metadatos, sacado los argumentos del constructor de la
> transacción de creación y visto el JSON que forge envía a un verificador.

**Duración estimada**: 2 h
**Prerrequisitos**: [Ejercicio 02](../ejercicio-02-keystore-y-broadcast/README.md) terminado;
[Teoría 04 — Verificación](../../1-teoria/04-verificacion.md) leída.

## Contexto

Un verificador hace, con tu código, lo que harás aquí a mano: compilar, comparar con la cadena y
explicar cada diferencia. Todo en anvil: no se envía nada a ningún verificador.

Ejercicio de terminal: cada paso es una función de `pasos.sh` con `todo "Paso N"` y la solución
en líneas `#> `.

| Archivo | Qué es |
| ------- | ------ |
| `pasos.sh` | Los siete pasos. Trae `deploy`, que despliega la Box con el script del ejercicio 01 e imprime su dirección |
| `test.sh` | Ejecuta cada paso y compara su salida. **No lo modifiques** |
| `contrato/` | El proyecto del ejercicio 01, resuelto |

Aquí se firma con `--private-key`: es anvil y la clave es la pública de la cuenta 3. Como en el
ejercicio 02, `test.sh` usa su anvil del puerto 8546 y `bash pasos.sh N` el tuyo del 8545.

En bash, `${texto:inicio:longitud}` corta un trozo de un texto y `$((16#ff))` convierte
hexadecimal a decimal. El código de `cast code` es texto: `0x` y dos caracteres por byte, así
que el byte `n` empieza en el carácter `2 + n * 2`.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-16-despliegue_y_verificacion/2-practicas/ejercicio-03-verificacion-por-dentro/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
bash test.sh
```

**Verifica**: siete `❌` y `0 de 7 pasos correctos`.

## Paso 1: La cadena frente al compilador

**Por qué**: es la comparación que hace todo verificador. `forge inspect ... deployedBytecode`
da el código que queda desplegado (*runtime*), sin el constructor.

```bash
step1() {
  local chain compiled
  chain=$(cast code "$(deploy)" --rpc-url "$RPC")
  compiled=$(forge inspect --root contrato Box deployedBytecode)
  echo "${#chain} ${#compiled}"
  [[ "$chain" == "$compiled" ]] && echo iguales || echo distintos
}
```

**Verifica**: `✅ Paso 1` con `1260 1260` y `distintos`. Mismo tamaño, contenido distinto: algo
que el compilador no sabía lo escribió el constructor.

## Paso 2: El immutable

**Por qué**: `OWNER` es `immutable` (semana 04): su valor no va al storage, sino dentro del
código, y lo pone el constructor. El artefacto de forge dice dónde: `immutableReferences`, con
la posición en bytes de cada hueco.

```bash
step2() {
  local chain
  chain=$(cast code "$(deploy)" --rpc-url "$RPC")
  jq -c '[.deployedBytecode.immutableReferences[][] | .start]' contrato/out/Box.sol/Box.json
  echo "${chain:2+157*2:64}"
}
```

**Verifica**: `✅ Paso 2` con `[157,198]` y
`00000000000000000000000090f79bf6eb2c4f870365e785982e1f101e93b906`. `OWNER` se lee en dos
sitios del código (el getter y `store`), así que tiene dos huecos, y en la cadena los dos llevan
la dirección de la cuenta 3.

## Paso 3: Comparar sin los immutables

**Por qué**: el verificador pone a cero esos huecos antes de comparar. Si el resto coincide, el
código es el mismo.

```bash
step3() {
  local chain compiled start zeros
  chain=$(cast code "$(deploy)" --rpc-url "$RPC")
  compiled=$(forge inspect --root contrato Box deployedBytecode)
  zeros=$(printf '0%.0s' {1..64})
  for start in $(jq -r '.deployedBytecode.immutableReferences[][] | .start' contrato/out/Box.sol/Box.json); do
    chain="${chain:0:2+start*2}${zeros}${chain:2+start*2+64}"
  done
  [[ "$chain" == "$compiled" ]] && echo iguales || echo distintos
}
```

**Verifica**: `✅ Paso 3` con `iguales`.

## Paso 4: Los metadatos

**Por qué**: el final del bytecode no es código. Es el bloque CBOR de metadatos que añade solc,
y sus dos últimos bytes dicen cuánto mide. Los tres bytes anteriores a esos dos son la versión de
solc.

```bash
step4() {
  local chain len cbor v
  chain=$(cast code "$(deploy)" --rpc-url "$RPC")
  len=$((16#${chain: -4}))
  cbor=${chain: -$((len * 2 + 4)):$((len * 2))}
  v=${cbor: -6}
  echo "$len $((16#${v:0:2})).$((16#${v:2:2})).$((16#${v:4:2}))"
}
```

**Verifica**: `✅ Paso 4` con `51 0.8.38`. Imprime `$cbor` para verlo entero: empieza por
`a2 64 69706673` (un mapa CBOR de dos entradas cuya primera clave es el texto `ipfs`) y termina
por `64 736f6c63 43 000826` (la clave `solc` y los bytes `0`, `8`, `38`).

## Paso 5: Los argumentos del constructor

**Por qué**: el código desplegado no los lleva. Están al final de la transacción de creación,
detrás del bytecode de creación, codificados en ABI. Es lo que forge envía como
`--constructor-args`.

```bash
step5() {
  local hash input
  deploy >/dev/null
  hash=$(jq -r '.transactions[0].hash' "$RUN")
  input=$(cast tx "$hash" input --rpc-url "$RPC")
  echo "${input: -64}"
  cast abi-encode "constructor(address)" "$ME"
}
```

**Verifica**: `✅ Paso 5` con los mismos 32 bytes dos veces: los últimos de la transacción y los
que da `cast abi-encode`. Un `address` ocupa una palabra de 32 bytes.

## Paso 6: El JSON para el verificador

**Por qué**: `--show-standard-json-input` imprime lo que forge enviaría, sin enviarlo. Aquí van
los ajustes que el verificador usará para compilar.

```bash
step6() {
  local box
  box=$(deploy)
  forge verify-contract --root contrato "$box" src/Box.sol:Box --show-standard-json-input \
    --constructor-args "$(cast abi-encode "constructor(address)" "$ME")" |
    jq -r '[.language, (.sources | keys[0]), .settings.evmVersion, .settings.optimizer.enabled] | join(" ")'
}
```

**Verifica**: `✅ Paso 6` con `Solidity src/Box.sol osaka false`. La versión de solc no está en
el JSON: forge la envía aparte, sacada de `foundry.toml`.

## Paso 7: Otros ajustes, otro bytecode

**Por qué**: demostrar que verificar con ajustes distintos de los del despliegue falla, aunque
el `.sol` sea el mismo.

```bash
step7() {
  local default optimized
  default=$(forge inspect --root contrato Box deployedBytecode)
  optimized=$(forge inspect --root contrato Box deployedBytecode --optimize)
  echo "${#default} ${#optimized}"
}
```

**Verifica**: `✅ Paso 7` con `1260 678`, y `7 de 7 pasos correctos`. Con el optimizador, la
Box mide casi la mitad: un verificador con esos ajustes no encontraría lo que hay en la cadena.

## Qué aprendiste

- El código desplegado es el runtime del compilador más los immutables que escribe el
  constructor.
- solc añade al final unos metadatos con el hash de los ajustes y su versión.
- Los argumentos del constructor van al final de la transacción de creación.
- Verificar es compilar con los mismos ajustes y comparar.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 02 — Keystore y broadcast](../ejercicio-02-keystore-y-broadcast/README.md) | **Ejercicio 03 — Verificación por dentro** | [Proyecto — Despliegue en Sepolia →](../../3-proyecto/README.md) |
