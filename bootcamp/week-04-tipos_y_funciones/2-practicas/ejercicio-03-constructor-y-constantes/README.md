# Ejercicio 03 — Constructor y constantes

> Al terminar habrás desplegado un contrato con argumentos de constructor, leído sus
> getters, comprobado qué variables ocupan storage, leído una variable `private`,
> encontrado un valor `immutable` dentro del bytecode y medido lo que cuesta leer cada una.

**Duración estimada**: 2 h
**Prerrequisitos**: [Ejercicio 02](../ejercicio-02-visibilidad/README.md) terminado;
[Teoría 05](../../1-teoria/05-constructor-constant-e-immutable.md) leída.

## Contexto

Ejercicio de terminal, como el ejercicio 03 de la semana 03: cada paso es una función de
`pasos.sh` con `todo "Paso N"` y la solución en líneas `#> `.

| Archivo | Qué es |
| ------- | ------ |
| `pasos.sh` | Los seis pasos. Aquí trabajas. Trae `PK`, la clave de la cuenta 0 de anvil |
| `test.sh` | Ejecuta cada paso en un anvil nuevo (puerto 8546) y compara su salida. **No lo modifiques** |
| `contrato/` | Proyecto Foundry con `Config`: una `constant`, una `immutable`, una variable `public` y una `private` |

**Abre** `contrato/src/Config.sol` y léelo antes de empezar: cada paso pregunta dónde vive
uno de sus valores.

Para probar un paso a mano con `bash pasos.sh N` necesitas tu anvil en el 8545
(`anvil --silent &`) y reiniciarlo entre pruebas, como en la semana 03.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-04-tipos_y_funciones/2-practicas/ejercicio-03-constructor-y-constantes/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
bash test.sh
```

**Verifica**: seis `❌` y `0 de 6 pasos correctos`.

## Paso 1: Desplegar con argumentos

**Por qué**: el constructor de `Config` pide el límite inicial. Sin él, el despliegue
falla.

```bash
step1() {
  forge create --root contrato src/Config.sol:Config \
    --private-key "$PK" --broadcast --json --constructor-args 100 2>/dev/null | jq -r .deployedTo
}
```

`--constructor-args` va **al final**: se queda con todo lo que tiene detrás.

**Verifica**: `✅ Paso 1` con `0x5FbDB2315678afecb367f032d93F642f64180aa3`. Es la misma
dirección que el `Counter` de la semana 03: depende de quién despliega y de su nonce, no
del contrato.

## Paso 2: Los getters

**Por qué**: comprobar justo después de desplegar que el constructor recibió lo que
debía.

```bash
step2() {
  local config
  config=$(step1)
  echo "$(cast call "$config" "limit()(uint256)") $(cast call "$config" "OWNER()(address)")"
}
```

**Verifica**: `✅ Paso 2` con `100 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`: el límite
que pasaste y la cuenta 0, que es quien desplegó (`msg.sender` en el constructor).

## Paso 3: Qué ocupa storage

**Por qué**: el compilador decide el layout. Preguntárselo no necesita desplegar nada.

```bash
step3() {
  forge inspect --root contrato Config storageLayout --json | jq -r '[.storage[].label] | join(" ")'
}
```

**Verifica**: `✅ Paso 3` con `limit secret`. Ni `MAX_LIMIT` ni `OWNER` aparecen: viven en
el bytecode.

## Paso 4: Leer lo `private`

**Por qué**: comprobar con tus manos que `private` no oculta nada.

```bash
step4() {
  local config
  config=$(step1)
  cast storage "$config" 1 | cast to-dec
}
```

`secret` es la segunda variable de storage: slot 1. `cast to-dec` pasa los 32 bytes a
decimal.

**Verifica**: `✅ Paso 4` con `7`. Prueba también
`cast call "$config" "secret()(uint256)"`: revierte, porque no hay getter. El dato se lee
igual.

## Paso 5: El `immutable` dentro del código

**Por qué**: si `OWNER` no está en el storage, tiene que estar en el código desplegado.

```bash
step5() {
  local config
  config=$(step1)
  cast code "$config" | grep -o f39fd6e51aad88f6f4ce6ab8827279cfffb92266 | wc -l
}
```

`cast code` devuelve el bytecode en hexadecimal y en minúsculas; `grep -o` saca cada
aparición de la dirección del dueño y `wc -l` las cuenta.

**Verifica**: `✅ Paso 5` con `1`: el constructor escribió la dirección dentro del código
desplegado.

## Paso 6: Lo que cuesta leer

**Por qué**: medir en lugar de creer. `cast estimate` dice cuánto gas gastaría una
transacción a esa función.

```bash
step6() {
  local config
  config=$(step1)
  echo "$(cast estimate "$config" "MAX_LIMIT()") $(cast estimate "$config" "limit()")"
}
```

**Verifica**: `✅ Paso 6` con `21367 23532` y `6 de 6 pasos correctos`. La diferencia es la
lectura de un slot del storage.

## ✅ Criterios de éxito

- `bash test.sh` termina con `6 de 6 pasos correctos`.
- Explicas por qué `MAX_LIMIT` y `OWNER` no salen en el paso 3 y dónde están.
- Explicas qué cambiaría en los pasos 2 y 5 si desplegara la cuenta 1.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 02 — Visibilidad](../ejercicio-02-visibilidad/README.md) | **Ejercicio 03 — Constructor y constantes** | [Proyecto — Registro configurable →](../../3-proyecto/README.md) |
