# Ejercicio 03 — Desplegar y llamar

> Al terminar habrás calculado un selector, compilado un proyecto y leído su ABI,
> desplegado el contador en anvil, leído su estado con `cast call`, cambiado con
> `cast send` y comprobado el cambio en el storage.

**Duración estimada**: 2 h
**Prerrequisitos**: [Ejercicio 02](../ejercicio-02-tests-con-forge/README.md) terminado;
[Teoría 05](../../1-teoria/05-desplegar-y-llamar.md) leída.

## Contexto

Ejercicio de terminal, como los de la semana 02: cada paso es una función de `pasos.sh`
con `todo "Paso N"` y la solución en líneas `#> `. Resolver un paso es borrar la línea
`todo` y quitar el `#> `.

| Archivo | Qué es |
| ------- | ------ |
| `pasos.sh` | Los seis pasos. Aquí trabajas. Trae `PK`, la clave de la cuenta 0 de anvil |
| `test.sh` | Ejecuta cada paso y compara su salida. **No lo modifiques** |
| `contrato/` | Proyecto Foundry con el `Counter` del ejercicio 01 (solo `number`, `get`, `increment` y `set`) |

Los comandos de `forge` reciben `--root contrato`: trabajan sobre esa carpeta sin que
tengas que entrar en ella.

`test.sh` arranca su propio anvil en el puerto 8546, nuevo para cada paso: todos empiezan
sin contratos y con la cuenta 0 en nonce 0. Para probar un paso a mano con
`bash pasos.sh N` necesitas tu anvil en el 8545 (`anvil --silent &`). Desde el paso 3, cada
ejecución despliega otro contrato y el nonce avanza: la dirección cambia. Reinicia anvil
entre prueba y prueba (`kill %1` y `anvil --silent &`).

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-03-primer_contrato_con_foundry/2-practicas/ejercicio-03-desplegar-y-llamar/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
bash test.sh
```

**Verifica**: seis `❌` y `0 de 6 pasos correctos`.

## Paso 1: El selector

**Por qué**: es lo primero que lleva toda llamada a `increment()`. Lo calculas sin
compilar nada: solo depende de la firma.

```bash
step1() {
  cast sig "increment()"
}
```

**Verifica**: `✅ Paso 1` con `0xd09de08a`.

## Paso 2: Compilar y leer la ABI

**Por qué**: la ABI es lo que permite a `cast` saber qué funciones tiene el contrato.
Sale del artefacto que deja `forge build`.

```bash
step2() {
  forge build --root contrato --silent
  jq -r '[.abi[].name] | join(" ")' contrato/out/Counter.sol/Counter.json
}
```

| Pieza | Qué hace |
| ----- | -------- |
| `--silent` | No imprime el progreso de la compilación |
| `[.abi[].name]` | Lista con el nombre de cada entrada de la ABI |
| `join(" ")` | Las une en una línea separadas por espacios |

**Verifica**: `✅ Paso 2` con `get increment set`.

## Paso 3: Desplegar

**Por qué**: publicar el contrato en la red. Con `--json` la salida es fácil de procesar.

```bash
step3() {
  forge create --root contrato src/Counter.sol:Counter \
    --private-key "$PK" --broadcast --json 2>/dev/null | jq -r .deployedTo
}
```

`2>/dev/null` descarta los avisos que `forge` pudiera escribir en la salida de errores:
`test.sh` también compara esa salida, y el paso tiene que imprimir solo la dirección.

**Verifica**: `✅ Paso 3` con `0x5FbDB2315678afecb367f032d93F642f64180aa3`, la dirección que
corresponde a la cuenta 0 con nonce 0.

## Paso 4: Leer

**Por qué**: un contrato recién desplegado tiene el storage a cero. Leerlo no necesita
transacción.

```bash
step4() {
  local counter
  counter=$(step3)
  cast call "$counter" "get()(uint256)"
}
```

**Verifica**: `✅ Paso 4` con `0`.

## Paso 5: Cambiar y comprobar el storage

**Por qué**: una transacción que escribe deja el cambio en la cadena. Lo ves de dos
formas: con la función del contrato y leyendo el slot directamente.

```bash
step5() {
  local counter
  counter=$(step3)
  cast send "$counter" "increment()" --private-key "$PK" >/dev/null
  echo "$(cast call "$counter" "get()(uint256)") $(cast storage "$counter" 0)"
}
```

**Verifica**: `✅ Paso 5` con
`1 0x0000000000000000000000000000000000000000000000000000000000000001`: `number` está en el
slot 0 (Teoría 03).

## Paso 6: `call` no guarda

**Por qué**: comprobar que `cast call` a una función que escribe no cambia nada. Es el
error más común al empezar.

```bash
step6() {
  local counter
  counter=$(step3)
  cast send "$counter" "set(uint256)" 42 --private-key "$PK" >/dev/null
  cast call "$counter" "set(uint256)" 7 >/dev/null
  cast call "$counter" "get()(uint256)"
}
```

**Verifica**: `✅ Paso 6` con `42` y `6 de 6 pasos correctos`. El `set(7)` se ejecutó en
una copia del estado y se descartó.

## ✅ Criterios de éxito

- `bash test.sh` termina con `6 de 6 pasos correctos`.
- Explicas por qué el paso 3 da siempre la misma dirección en un anvil nuevo.
- Explicas qué cambiaría en el paso 6 si el `set(7)` se enviara con `cast send`.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 02 — Tests con forge](../ejercicio-02-tests-con-forge/README.md) | **Ejercicio 03 — Desplegar y llamar** | [Proyecto — Contrato registro →](../../3-proyecto/README.md) |
