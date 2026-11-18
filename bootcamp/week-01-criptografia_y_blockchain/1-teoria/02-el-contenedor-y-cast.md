# Teoría 02 — El contenedor y cast

## 🎯 Objetivos

- Construir la imagen de desarrollo del bootcamp y entrar en un contenedor.
- Saber qué es Foundry y para qué sirve cada una de sus cuatro herramientas.
- Leer y escribir números y textos en **hexadecimal**, el formato de todo en Ethereum.
- Ejecutar tus primeros comandos de `cast` y entender su salida.

---

## 1. Qué problema resuelve el contenedor

Para trabajar con smart contracts necesitas un compilador de Solidity, una blockchain
local para pruebas y herramientas para hablar con ella. Instalar todo a mano en cada
máquina produce versiones distintas y errores que "a mí me funcionan".

Un **contenedor** es un entorno aislado (un Linux pequeño) que se crea a partir de una
**imagen**, una plantilla con todo instalado. El bootcamp trae su imagen definida en
[`docker/Dockerfile`](../../../docker/Dockerfile): Ubuntu 24.04 con las versiones exactas
de [`docs/stack-versions.md`](../../../docs/stack-versions.md). Tu máquina solo necesita
Docker y git ([`docs/setup.md`](../../../docs/setup.md)).

## 2. Construir la imagen y entrar

**Dónde**: en tu terminal, en la raíz del repositorio clonado `bc-smartcontracts`.

```bash
docker build -t bc-smartcontracts-dev docker
```

| Parte | Significado |
| ----- | ----------- |
| `docker build` | Construye una imagen a partir de un `Dockerfile` |
| `-t bc-smartcontracts-dev` | Le pone nombre (*tag*) a la imagen |
| `docker` | Carpeta donde está el `Dockerfile` |

Tarda unos minutos la primera vez; después usa el caché. Comprueba:

```bash
docker run --rm bc-smartcontracts-dev forge --version
```

Salida (las líneas 2-4 identifican la compilación exacta):

```
forge Version: 1.9.0
Commit SHA: 6056c5845d34205a83cf7108042adb137325c9df
Build Timestamp: 2026-11-02T20:28:32.434285913Z (1793651312)
Build Profile: dist
```

Para trabajar **dentro** del contenedor con tu carpeta actual montada:

```bash
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
```

El prompt cambia a `ubuntu@<id>:/workspace$`. Lo que guardes en `/workspace` aparece en
tu carpeta real, y viceversa: editas con tu editor fuera y ejecutas dentro. Para salir:
`exit`. En [`docs/setup.md`](../../../docs/setup.md) tienes el alias `scdev` para no
escribir el comando entero.

## 3. Foundry: cuatro herramientas

**Foundry** es el kit de herramientas para smart contracts que usa este bootcamp. Está
escrito en Rust, es muy rápido y trae cuatro programas:

| Herramienta | Para qué | Desde la semana |
| ----------- | -------- | --------------- |
| `cast` | Navaja suiza de terminal: hashes, claves, firmas, conversiones y hablar con una blockchain | 01 |
| `anvil` | Una blockchain local en tu máquina, con cuentas llenas de ETH de prueba | 02 |
| `forge` | Compilar, probar y desplegar contratos Solidity | 03 |
| `chisel` | Consola interactiva para probar fragmentos de Solidity | 04 |

Esta semana solo usas `cast`.

## 4. Hexadecimal: el idioma de Ethereum

Un **byte** son 8 bits: un número entre 0 y 255. Todo en Ethereum —hashes, claves,
direcciones, datos de transacciones— son secuencias de bytes, y se escriben en
**hexadecimal** (base 16): dígitos `0-9` y letras `a-f`, donde `a`=10 ... `f`=15.

- Cada byte se escribe con **exactamente dos** dígitos hex: `0` es `00`, `255` es `ff`.
- El prefijo `0x` avisa de que lo que sigue es hex: `0xff`.
- Una cadena de 32 bytes ocupa 64 dígitos hex (más el `0x`).
- Mayúsculas y minúsculas valen lo mismo: `0xFF` = `0xff`.

`cast` convierte entre formatos. **Dónde**: dentro del contenedor.

```bash
cast to-hex 255
cast to-dec 0xff
cast to-base 255 2
```

Salida:

```
0xff
255
0b11111111
```

El texto también son bytes: cada carácter se codifica en **UTF-8**. Las letras sin
tilde ocupan 1 byte; la `ñ` y las vocales con tilde, 2.

```bash
cast from-utf8 "Hola"
cast from-utf8 "ñ"
cast to-ascii 0x486f6c61
```

Salida:

```
0x486f6c61
0xc3b1
Hola
```

Léelo así: `48` es la `H`, `6f` la `o`, `6c` la `l`, `61` la `a`. Cuatro letras, cuatro
bytes, ocho dígitos hex.

## 5. Números grandes

Ethereum trabaja con enteros de **256 bits** (32 bytes). El más grande que cabe:

```bash
cast max-uint
```

Salida:

```
115792089237316195423570985008687907853269984665640564039457584007913129639935
```

Un número de 78 cifras. En la semana 04 verás por qué los contratos usan este tamaño.

## 6. Antipatrones y riesgos

- ❌ **Ejecutar `cast` o `forge` fuera del contenedor** con una versión instalada a mano.
  Las salidas que compara cada test se obtuvieron con las versiones fijadas.
- ❌ **Lanzar el contenedor con `--user root`**: los archivos que crees en `/workspace`
  quedarán a nombre de `root` en tu máquina.
- ❌ **Pegar en la terminal claves privadas reales.** El historial de la shell las guarda
  en texto plano. En este bootcamp solo usas claves de prueba públicas.
- ❌ **Contar caracteres de un texto para saber sus bytes.** `"ñ"` es 1 carácter y 2 bytes.

## 7. Trucos

- `cast --help` lista todos los subcomandos; `cast <subcomando> --help` explica uno.
- Casi todos los subcomandos tienen alias corto: `cast keccak` es `cast k`. En el bootcamp
  se usa siempre el nombre largo, que se entiende al leerlo.
- `docker images bc-smartcontracts-dev` confirma que la imagen existe y cuánto ocupa.

## ✅ Checklist

- [ ] La imagen `bc-smartcontracts-dev` está construida y `forge --version` imprime `1.9.0`.
- [ ] Entro y salgo del contenedor con mi carpeta montada en `/workspace`.
- [ ] Sé para qué sirven `cast`, `anvil`, `forge` y `chisel`.
- [ ] Convierto entre decimal, hex y texto con `cast`.
- [ ] Explico por qué un byte se escribe con dos dígitos hex.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 01 — Qué problema resuelve una blockchain](01-que-problema-resuelve-una-blockchain.md) | **Teoría 02 — El contenedor y cast** | [Teoría 03 — Funciones hash →](03-funciones-hash.md) |
