# Ejercicio 03 — Firmar y verificar

> Al terminar firmarás un mensaje, comprobarás que la verificación detecta un mensaje
> alterado y una dirección equivocada, separarás la firma en sus partes y recalcularás a
> mano el hash que se firma de verdad.

**Duración estimada**: 2 h
**Prerrequisitos**: [Ejercicio 02](../ejercicio-02-claves-y-direcciones/README.md)
terminado; [Teoría 05](../../1-teoria/05-firmas-digitales.md) leída.

## Contexto

Mismo formato que los ejercicios anteriores. `pasos.sh` trae tres variables ya escritas:

| Variable | Qué es |
| -------- | ------ |
| `PK` | Clave privada de la cuenta 0 de prueba: la que firma |
| `ADDR` | Dirección de la cuenta 0 |
| `OTHER` | Dirección de la cuenta 1: otra persona |

Resuelve los pasos **en orden**: del 2 al 5 usan la firma del paso 1 llamando a
`$(step1)`.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-01-criptografia_y_blockchain/2-practicas/ejercicio-03-firmar-y-verificar/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
bash test.sh
```

**Verifica**: seis `❌` y `0 de 6 pasos correctos`.

## Paso 1: Firmar

**Por qué**: así autoriza algo el dueño de una cuenta sin revelar su clave.

```bash
step1() {
  cast wallet sign --private-key "$PK" "hola"
}
```

**Verifica**: `✅ Paso 1`. Ejecuta `bash pasos.sh 1` dos veces: la firma es idéntica.
Las firmas de Ethereum son deterministas.

## Paso 2: Verificar el caso correcto

**Por qué**: es lo que hace cualquiera —un nodo, un contrato, un servidor— para aceptar
una orden firmada. Solo necesita datos públicos.

```bash
step2() {
  cast wallet verify --address "$ADDR" "hola" "$(step1)"
}
```

**Verifica**: `✅ Paso 2`. La salida es
`Validation succeeded. Address 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 signed this message.`

## Paso 3: Un mensaje alterado

**Por qué**: comprobar que cambiar un solo carácter invalida la firma. En un programa no
se lee el mensaje de error: se usa el **código de salida** del comando.

```bash
step3() {
  if cast wallet verify --address "$ADDR" "Hola" "$(step1)" >/dev/null 2>&1; then
    echo "aceptada"
  else
    echo "rechazada"
  fi
}
```

| Pieza | Qué hace |
| ----- | -------- |
| `if comando; then` | Entra en el `then` si el comando terminó con código 0 (éxito) |
| `>/dev/null` | Descarta la salida normal |
| `2>&1` | Manda también los errores al mismo sitio (descartados) |

**Verifica**: `✅ Paso 3` con `rechazada`.

## Paso 4: Otra dirección

**Por qué**: una firma válida no basta; tiene que ser **de quien esperas**. Con la
dirección de otra cuenta, la misma firma se rechaza.

```bash
step4() {
  if cast wallet verify --address "$OTHER" "hola" "$(step1)" >/dev/null 2>&1; then
    echo "aceptada"
  else
    echo "rechazada"
  fi
}
```

**Verifica**: `✅ Paso 4` con `rechazada`.

## Paso 5: El byte v

**Por qué**: reconocer la estructura de 65 bytes `r` + `s` + `v`. El byte `v` es el que
permite recuperar quién firmó (lo usarás con `ecrecover` en la semana 14).

```bash
step5() {
  local sig
  sig=$(step1)
  echo "0x${sig:130:2}"
}
```

`${sig:130:2}` toma 2 caracteres desde la posición 130: `0x` ocupa las posiciones 0-1,
`r` las 2-65, `s` las 66-129 y `v` las 130-131.

**Verifica**: `✅ Paso 5` con `0x1c` (28 en decimal).

## Paso 6: El hash EIP-191 a mano

**Por qué**: `cast wallet sign` no firma `"hola"` a secas: firma el hash de
`"\x19Ethereum Signed Message:\n4hola"`. Recalcularlo tú demuestra qué se firma de verdad.

```bash
step6() {
  local prefix
  prefix=$(cast from-utf8 "$(printf '\x19Ethereum Signed Message:\n4')")
  cast keccak "$(cast concat-hex "$prefix" "$(cast from-utf8 "hola")")"
}
```

| Pieza | Qué hace |
| ----- | -------- |
| `printf '\x19...\n4'` | Escribe el byte `0x19`, el texto, un salto de línea y `4` (la longitud de `hola`) |
| `cast from-utf8` | Convierte el prefijo a hex |
| `cast concat-hex` | Pega prefijo y mensaje |
| `cast keccak` | Hash del conjunto |

**Verifica**: `✅ Paso 6`, `6 de 6 pasos correctos`, y que coincide con
`cast hash-message "hola"`.

## ✅ Criterios de éxito

- `bash test.sh` termina con `6 de 6 pasos correctos`.
- Explicas por qué los pasos 3 y 4 se rechazan por motivos distintos.
- Explicas qué ataque evita el prefijo del paso 6.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 02 — Claves y direcciones](../ejercicio-02-claves-y-direcciones/README.md) | **Ejercicio 03 — Firmar y verificar** | [Proyecto — Ficha criptográfica →](../../3-proyecto/README.md) |
