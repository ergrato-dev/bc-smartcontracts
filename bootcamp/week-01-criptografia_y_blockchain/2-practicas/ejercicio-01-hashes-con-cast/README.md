# Ejercicio 01 — Hashes con cast

> Al terminar calcularás hashes keccak256 y SHA-256 desde la terminal, comprobarás el
> efecto avalancha, distinguirás texto de bytes y detectarás una alteración en una
> cadena de bloques.

**Duración estimada**: 2 h
**Prerrequisitos**: imagen `bc-smartcontracts-dev` construida
([Teoría 02](../../1-teoria/02-el-contenedor-y-cast.md)); [Teoría 03](../../1-teoria/03-funciones-hash.md)
y [Teoría 06](../../1-teoria/06-bloques-y-cadena.md) leídas.

## Contexto

Este ejercicio no usa Solidity: todo pasa en la terminal. El starter trae dos archivos:

| Archivo | Qué es |
| ------- | ------ |
| `pasos.sh` | Un script de bash con una función por paso (`step1`, `step2`...). Cada una tiene una línea `todo "Paso N"` y, comentada con `#> `, la solución |
| `test.sh` | Los tests: ejecuta cada paso y compara su salida con el resultado esperado. **No lo modifiques** |

En cada paso: lees el porqué, abres `pasos.sh`, **borras la línea `todo`**, **quitas el
`#> `** de las líneas de solución (deja la sangría de dos espacios) y ejecutas los tests.
Escribirlo tú en lugar de solo descomentar cuenta igual, siempre que la salida coincida.

## Paso 0: Entrar y ver el rojo

**Dónde**: en tu terminal, desde la raíz del repositorio `bc-smartcontracts`.

```bash
cd bootcamp/week-01-criptografia_y_blockchain/2-practicas/ejercicio-01-hashes-con-cast/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
```

Ya dentro del contenedor:

```bash
bash test.sh
```

**Verifica**: seis líneas que empiezan por `❌`, cada una con el esperado y
`obtenido: TODO: Paso N`, y al final:

```
0 de 6 pasos correctos
```

Puedes ejecutar un solo paso para ver qué imprime: `bash pasos.sh 1`.

## Paso 1: Tu primer hash

**Por qué**: keccak256 es la función hash de Ethereum. Todo lo demás de la semana se
apoya en ella.

```bash
step1() {
  cast keccak "hola"
}
```

**Abre** `pasos.sh`, busca `step1`, borra `todo "Paso 1"` y quita el `#> `.

**Verifica**: `bash test.sh` muestra `✅ Paso 1` y `1 de 6 pasos correctos`.

## Paso 2: SHA-256 no es keccak256

**Por qué**: comprobar con tus ojos que dos funciones hash distintas dan resultados
distintos para la misma entrada, aunque las dos midan 32 bytes.

```bash
step2() {
  printf 'hola' | sha256sum | cut -d ' ' -f 1
}
```

| Pieza | Qué hace |
| ----- | -------- |
| `printf 'hola'` | Escribe los 4 bytes de `hola`, **sin** salto de línea |
| `\| sha256sum` | Calcula su SHA-256; imprime `<hash>  -` |
| `\| cut -d ' ' -f 1` | Corta por espacios y se queda con el primer campo: el hash |

**Verifica**: `✅ Paso 2`. Prueba a cambiar `printf` por `echo` y ejecuta
`bash pasos.sh 2`: el hash cambia porque `echo` añade un `\n`. Vuelve a `printf`.

## Paso 3: Efecto avalancha

**Por qué**: un solo carácter distinto cambia todo el hash. Por eso un hash detecta
cualquier alteración.

```bash
step3() {
  cast keccak "Hola"
}
```

**Verifica**: `✅ Paso 3`. Compara a ojo los hashes de los pasos 1 y 3: no comparten
ningún patrón.

## Paso 4: Texto y bytes

**Por qué**: `cast keccak` hashea bytes. Si le das texto, primero lo convierte a bytes
UTF-8. Hacer la conversión tú y hashear los bytes debe dar el mismo resultado que el
paso 1.

```bash
step4() {
  local bytes
  bytes=$(cast from-utf8 "hola")
  cast keccak "$bytes"
}
```

`local` declara una variable que solo existe dentro de la función. `$(...)` guarda en
ella lo que imprime el comando: `0x686f6c61`.

**Verifica**: `✅ Paso 4`, con el mismo hash que el paso 1.

## Paso 5: El hash de un bloque

**Por qué**: así se calcula, de forma simplificada, el hash de un bloque: el hash del
anterior pegado a los datos, y todo hasheado. El primer bloque usa 32 bytes a cero.

```bash
step5() {
  cast keccak "$(cast concat-hex "$(cast hash-zero)" "$(cast from-utf8 "Ana paga 5 a Luis")")"
}
```

Léelo de dentro hacia fuera:

1. `cast hash-zero` → `0x000...000` (32 bytes a cero).
2. `cast from-utf8 "Ana paga 5 a Luis"` → los bytes del texto.
3. `cast concat-hex A B` → los pega en un solo valor hex.
4. `cast keccak` → el hash del conjunto.

**Verifica**: `✅ Paso 5` con `0xb1795d5e...93b3c`, el `B0` de la Teoría 06.

## Paso 6: Detectar una alteración

**Por qué**: es lo que hace cada nodo con cada bloque que recibe. Recalcula el hash y lo
compara con el guardado.

La función `block` ya está escrita al principio de `pasos.sh`: hace lo mismo que el
paso 5 con cualquier hash anterior y cualquier texto. `stored` es el hash que tenía el
bloque 1 con su dato original (`"Eva paga 2 a Raúl"`).

```bash
step6() {
  local stored=0xed68955907020f56007bca4fd8c55e23438f0191b094064d056313a94269fd54
  local recalculated
  recalculated=$(block "$(step5)" "Eva paga 9 a Raúl")
  if [[ "$recalculated" == "$stored" ]]; then echo "intacto"; else echo "alterado"; fi
}
```

**Verifica**: `✅ Paso 6` y, al final, `6 de 6 pasos correctos`. Para comprobar que la
lógica funciona en los dos sentidos, cambia temporalmente `9` por `2` y ejecuta
`bash pasos.sh 6`: debe imprimir `intacto`. Déjalo otra vez en `9`.

## ✅ Criterios de éxito

- `bash test.sh` termina con `6 de 6 pasos correctos`.
- Explicas por qué los pasos 1 y 4 dan el mismo hash.
- Explicas por qué el paso 6 detecta el cambio sin necesidad de conocer el dato original.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 06 — Bloques y cadena](../../1-teoria/06-bloques-y-cadena.md) | **Ejercicio 01 — Hashes con cast** | [Ejercicio 02 — Claves y direcciones →](../ejercicio-02-claves-y-direcciones/README.md) |
