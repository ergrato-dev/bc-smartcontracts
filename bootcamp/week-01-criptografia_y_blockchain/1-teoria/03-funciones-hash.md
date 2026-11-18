# Teoría 03 — Funciones hash

## 🎯 Objetivos

- Definir qué es una función hash criptográfica y sus cuatro propiedades.
- Calcular hashes keccak256 y SHA-256 desde la terminal.
- Distinguir entre hashear un **texto** y hashear unos **bytes** dados en hex.
- Explicar para qué usa Ethereum los hashes: identificadores, integridad y compromisos.

---

## 1. Qué problema resuelve

Quieres comprobar que un archivo de 2 GB que te enviaron es idéntico al original, sin
volver a enviarlo entero. O quieres demostrar mañana que hoy ya conocías una respuesta,
sin revelarla hoy. Las dos cosas se resuelven con una **huella digital** corta que
identifica los datos: un **hash**.

## 2. Cómo funciona

Una **función hash** recibe datos de cualquier tamaño y devuelve un resultado de tamaño
fijo, llamado **hash** o *digest*. Ethereum usa **keccak256**: su salida siempre son
32 bytes (64 dígitos hex).

Para que sirva en criptografía, la función debe cumplir cuatro propiedades:

| Propiedad | Qué significa | Para qué sirve |
| --------- | ------------- | -------------- |
| **Determinista** | La misma entrada da siempre el mismo hash, en cualquier máquina | Que todos los nodos calculen lo mismo |
| **Efecto avalancha** | Cambiar un solo bit de la entrada cambia el hash por completo | Detectar cualquier alteración, por pequeña que sea |
| **Resistencia a preimagen** | Dado un hash, es imposible en la práctica encontrar una entrada que lo produzca | Que el hash no revele los datos |
| **Resistencia a colisiones** | Es imposible en la práctica encontrar dos entradas distintas con el mismo hash | Que el hash identifique los datos de forma única |

"Imposible en la práctica" significa que, con todos los ordenadores del mundo, tardaría
más que la edad del universo. No es magia: hay 2²⁵⁶ hashes posibles, un número de 78
cifras (el `cast max-uint` de la [Teoría 02](02-el-contenedor-y-cast.md) más uno).

## 3. Cómo se calcula

**Dónde**: dentro del contenedor (`docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev`).

### Determinista

```bash
cast keccak "hola"
cast keccak "hola"
```

Salida, idéntica las dos veces y en cualquier máquina:

```
0x8aca9664752dbae36135fd0956c956fc4a370feeac67485b49bcd4b99608ae41
0x8aca9664752dbae36135fd0956c956fc4a370feeac67485b49bcd4b99608ae41
```

### Efecto avalancha

Cambia solo la `h` por `H`:

```bash
cast keccak "Hola"
```

```
0x98d72beb4bd8117253d41e6075451e4c62e8f4cb6538536ef1fc13333c7a4085
```

No se parece en nada al anterior. Lo mismo con un punto al final:

```bash
cast keccak "hola mundo"
cast keccak "hola mundo."
```

```
0x525b2909f95f2f15aaeff2980b06f2be6f4f49180840b46801915ea87f963aa5
0x1a1b01304bd71eaaf556d6fd143e982b3cdded3a9b3178a8b96af9c295f14a44
```

### Tamaño fijo

El texto vacío también tiene hash, y 100 000 letras `a` producen un hash del mismo
tamaño:

```bash
cast keccak ""
cast keccak "$(head -c 100000 /dev/zero | tr '\0' a)"
```

```
0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470
0x84951c56a2220986aeb29d9f422f5c4df8642a8c7d09aff518cfa8d71ae83979
```

(`head -c 100000 /dev/zero` produce 100 000 bytes a cero y `tr` los cambia por `a`.)

## 4. Texto frente a bytes

`cast keccak` mira su argumento:

- Si empieza por `0x`, lo interpreta como **bytes en hex**.
- Si no, lo interpreta como **texto** y hashea sus bytes UTF-8.

Por eso estas dos líneas dan el mismo hash: `0x686f6c61` son los bytes de `hola`.

```bash
cast from-utf8 "hola"
cast keccak 0x686f6c61
```

```
0x686f6c61
0x8aca9664752dbae36135fd0956c956fc4a370feeac67485b49bcd4b99608ae41
```

Y un `0x` con caracteres que no son hex es un error:

```bash
cast keccak 0xzz
```

```
Error: invalid character 'z' at position 0
```

## 5. keccak256 no es SHA-256

Hay muchas funciones hash. **SHA-256** es la de Bitcoin y la que trae Linux
(`sha256sum`). **keccak256** es la de Ethereum. Las dos dan 32 bytes, pero son algoritmos
distintos y dan resultados distintos para la misma entrada:

```bash
printf 'hola' | sha256sum
```

```
b221d9dbb083a7f33428d7c2a3c3198ae925614d70210e28716ccaa7cd4ddb79  -
```

`printf` (a diferencia de `echo`) no añade salto de línea, así que hashea exactamente
los 4 bytes de `hola`. `sha256sum` no pone `0x` y termina con `  -` (significa "leído de
la entrada estándar").

Ojo con la confusión de nombres: keccak256 es la versión **original** del algoritmo que
ganó el concurso SHA-3; el estándar oficial SHA3-256 cambió un detalle y da otros
resultados. En Ethereum, "keccak256" y "SHA3" en documentos antiguos se refieren a lo
mismo: keccak256.

## 6. Para qué los usa Ethereum

| Uso | Ejemplo | Dónde lo verás |
| --- | ------- | -------------- |
| Identificar | Cada transacción y cada bloque se identifica por su hash | Semana 02 |
| Encadenar | Cada bloque guarda el hash del anterior | [Teoría 06](06-bloques-y-cadena.md) |
| Derivar direcciones | Tu dirección sale del hash de tu clave pública | [Teoría 04](04-claves-y-direcciones.md) |
| Comprometerse | Publicas el hash de tu voto hoy y el voto mañana (*commit-reveal*) | Semana 14 |
| Seleccionar funciones | Los 4 primeros bytes del hash de `transfer(address,uint256)` identifican esa función | Semana 10 |

## 7. Antipatrones y riesgos

- ❌ **Usar un hash para "cifrar" algo adivinable.** Un hash no se invierte, pero si la
  entrada es corta o predecible se prueban todas: el hash de `"sí"` o de un número de
  teléfono se encuentra probando. Se añade un valor aleatorio secreto (*salt*) antes de
  hashear.
- ❌ **Hashear con `echo`** para comparar con un hash de Ethereum: `echo` añade `\n` y
  el hash es de otros bytes. Usa `printf` o `cast keccak`.
- ❌ **Pasar texto que empieza por `0x`** esperando que se trate como texto: `cast keccak`
  lo interpreta como hex.
- ❌ **Comparar keccak256 con SHA-256** y concluir que "los datos cambiaron".

## 8. Trucos

- Para comprobar que dos hashes son iguales, no los leas a ojo: compáralos en la shell,
  `[ "$h1" = "$h2" ] && echo iguales`.
- `cast hash-zero` imprime el hash "vacío" de 32 bytes a cero: se usa como hash anterior
  del primer bloque de una cadena.

## ✅ Checklist

- [ ] Recito las cuatro propiedades de una función hash criptográfica y para qué sirve cada una.
- [ ] Calculo un keccak256 de un texto y de unos bytes en hex.
- [ ] Explico por qué `cast keccak "hola"` y `cast keccak 0x686f6c61` coinciden.
- [ ] Sé que keccak256 y SHA-256 son algoritmos distintos.
- [ ] Sé por qué el hash de un dato predecible no lo protege.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 02 — El contenedor y cast](02-el-contenedor-y-cast.md) | **Teoría 03 — Funciones hash** | [Teoría 04 — Claves y direcciones →](04-claves-y-direcciones.md) |
