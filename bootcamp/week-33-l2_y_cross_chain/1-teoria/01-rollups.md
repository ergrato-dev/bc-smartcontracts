# Teoría 01 — Rollups

## 🎯 Objetivos

- Explicar por qué Ethereum no ejecuta él mismo todas las transacciones y qué es una L2.
- Describir las piezas de un rollup: secuenciador, lotes en L1 y raíces de estado.
- Distinguir un rollup optimista de uno ZK por cómo demuestran que su estado es correcto.
- Saber qué paga una transacción en una L2 y por qué los bytes cuentan más que la ejecución.
- Reconocer los riesgos de una L2: secuenciador caído o que censura, confirmaciones que aún no
  están en L1 y contratos del rollup que alguien puede actualizar.

## Qué problema resuelve

Ethereum produce un bloque cada 12 segundos, y cada bloque tiene un límite de gas (semana 02).
Todos los nodos ejecutan todas las transacciones: así nadie tiene que fiarse de nadie, pero la
cadena entera va al ritmo de un solo ordenador. Cuando muchos quieren entrar en el mismo bloque,
sube la base fee y una transferencia de tokens pasa a costar dólares.

Una **L2** (capa 2) es otra cadena que ejecuta las transacciones fuera de Ethereum y usa Ethereum
(la **L1**, capa 1) para lo que no se puede delegar: guardar los datos y decidir qué estado es el
bueno. Un **rollup** es la L2 que publica en L1 los datos de todas sus transacciones. Con esos
datos, cualquiera puede reconstruir el estado de la L2 sin pedir permiso al rollup.

La seguridad no sale gratis: una L2 hereda la de Ethereum solo en lo que Ethereum comprueba. Esta
teoría es para saber qué comprueba y qué no.

## Cómo funciona

![Los usuarios envían transacciones al secuenciador, que produce bloques de L2 cada dos segundos; el batcher publica lotes en blobs de L1; el proposer publica raíces de estado en L1, que se pueden disputar durante siete días en un rollup optimista o se demuestran con una prueba en uno ZK](../0-assets/01-un-rollup-por-dentro.svg)

### El secuenciador

El **secuenciador** (sequencer) es el nodo que recibe las transacciones de la L2, las ordena y
produce los bloques. En OP Mainnet y en Base hay un bloque cada 2 segundos. Hoy, en casi todos los
rollups, el secuenciador es uno solo y lo opera el equipo del rollup: decide el orden (y con él, el
MEV de la semana 22) y puede caerse.

Cuando el secuenciador te devuelve el recibo, tu transacción tiene una **confirmación blanda**: el
secuenciador promete que estará en ese bloque, pero L1 todavía no sabe nada de ella.

### Los lotes en L1

Cada pocos minutos, otro proceso (en el OP Stack, el **batcher**) comprime las transacciones de
muchos bloques de L2 y las publica en L1. Desde marzo de 2024 (EIP-4844) las publica en **blobs**:
bloques de datos de 128 KiB que viajan con una transacción de L1, mucho más baratos que el
`calldata`, que los contratos no pueden leer y que los nodos borran a las dos semanas y pico.
Basta con que hayan estado disponibles ese tiempo: es la **disponibilidad de datos** (data
availability), la garantía de que cualquiera pudo descargarlos.

Una vez el lote está en un bloque de L1, tu transacción es tan definitiva como ese bloque de L1:
ni el secuenciador puede ya cambiar el orden.

### Las raíces de estado y las pruebas

Con los datos en L1, falta que L1 acepte cuál es el estado de la L2. Otro proceso (el
**proposer**) publica en un contrato de L1 una **raíz de estado** (state root o output root): un
hash que resume todo el estado de la L2 en un bloque, como la raíz de storage de la semana 27.
Las retiradas de la L2 a L1 (teoría 03) se demuestran contra esa raíz. Hay dos formas de que L1 se
fíe de ella:

| | Rollup optimista | Rollup ZK |
| - | ---------------- | --------- |
| Idea | La raíz se da por buena salvo que alguien demuestre que es falsa | La raíz llega con una prueba criptográfica de que es correcta |
| Prueba | De fraude (fault proof): solo si alguien disputa | De validez (SNARK o STARK), en cada lote |
| Retiradas a L1 | Tras la **ventana de disputa**: 7 días en OP Mainnet, Base y Arbitrum One | Cuando L1 verifica la prueba: horas |
| Ejemplos | OP Mainnet, Base (OP Stack), Arbitrum One | zkSync Era, Scroll, Linea |

En un rollup optimista basta con **un** observador honesto que vigile y dispute a tiempo. Por eso
la ventana es larga: tiene que dar tiempo a reaccionar aunque alguien intente censurar las
disputas en L1.

### Cuando el secuenciador no colabora

Si el secuenciador ignora tus transacciones, los rollups permiten **forzar la inclusión**: envías
la transacción a un contrato de L1 (en el OP Stack, el `OptimismPortal`) y el rollup tiene que
incluirla en un plazo (unas 12 horas en el OP Stack). Es lento y caro, pero sin él la L2 sería tan
fiable como su operador.

### Qué paga una transacción en una L2

En una L2 pagas dos cosas:

- **La ejecución**, como en L1: gas usado por la base fee de la L2. Es barata porque hay mucho
  espacio por bloque y pocos compitiendo por él.
- **La tarifa de datos de L1** (L1 data fee): tu parte de lo que cuesta publicar el lote en L1.
  Depende de los bytes de tu transacción (comprimidos) y del precio de los blobs. En el OP Stack
  la calcula el contrato predeployado `GasPriceOracle`, en `0x420000000000000000000000000000000000000F`.

Por eso en una L2 los bytes importan más que los opcodes. Antes de los blobs, cada byte de datos
en L1 costaba lo que dice EIP-2028: 16 de gas si no es cero, 4 si es cero. Sigue siendo una buena
forma de ver de qué está hecha una transacción.

## Cómo se escribe

Mira cuántos bytes lleva un alta del registro y cuánto costarían como `calldata` en L1.

**Dónde**: en el contenedor (`docker run --rm -it bc-smartcontracts-dev`).

```bash
data=$(cast calldata "register(string)" "hola")
echo $data
hex=${data#0x}; total=$(( ${#hex} / 2 )); zeros=$(echo $hex | fold -w2 | grep -c "^00$")
echo "bytes: $total, ceros: $zeros, gas: $(( 16 * (total - zeros) + 4 * zeros ))"
```

**Salida**:

```text
0xf2c298be00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000004686f6c6100000000000000000000000000000000000000000000000000000000
bytes: 100, ceros: 90, gas: 520
```

`cast calldata` codifica la llamada con el ABI (semana 10): 4 bytes de selector, 32 del
desplazamiento del string, 32 de su longitud y 32 con `hola` y relleno. De los 100 bytes, 90 son
ceros. La compresión del batcher se come casi todos, y por eso los rollups comprimen: la tarifa de
datos depende de lo que queda.

Los chain id de las redes que verás en la documentación:

| Red | Chain id | Sobre |
| --- | -------- | ----- |
| OP Mainnet | 10 | Ethereum |
| Base | 8453 | Ethereum |
| Arbitrum One | 42161 | Ethereum |
| OP Sepolia | 11155420 | Sepolia |
| Base Sepolia | 84532 | Sepolia |
| Arbitrum Sepolia | 421614 | Sepolia |

## Antipatrones y riesgos

- **Tratar la confirmación blanda como definitiva.** Hasta que el lote está en L1, el secuenciador
  puede reordenar o perder tu transacción. Un puente o un exchange que acredita al instante corre
  ese riesgo; uno que espera al bloque de L1, no.
- **Suponer que el secuenciador siempre está.** Si se cae, la L2 no produce bloques: los oráculos
  no se actualizan y, cuando vuelve, entran de golpe las transacciones que esperaban, incluidas
  las liquidaciones. La teoría 02 enseña a detectarlo.
- **Suponer que el secuenciador no censura.** Puede retrasar tu transacción horas, y en una subasta
  o una liquidación eso es perder. La inclusión forzada existe, pero tarda.
- **Olvidar quién puede actualizar el rollup.** Los contratos del rollup en L1 son actualizables
  (semana 15). Si una clave o un consejo puede cambiarlos sin plazo, puede cambiar las reglas de
  las retiradas. [ETHBEAT](https://ethbeat.org) (antes L2BEAT) clasifica cada rollup por **etapas** (Stage 0, 1 y 2)
  según cuánto depende de esas personas.
- **Esperar retiradas rápidas de un rollup optimista.** Sacar fondos a L1 por el puente canónico
  tarda la ventana de disputa entera. Si tu protocolo necesita mover ETH entre cadenas, ese plazo
  es parte del diseño (teoría 03).

## Trucos

- En [ETHBEAT](https://ethbeat.org) ves, por rollup, su etapa, quién puede actualizarlo, dónde
  publica los datos y cuánto dura la ventana de disputa.
- En una L2 del OP Stack, `getL1Fee(bytes)` del `GasPriceOracle` estima la tarifa de datos de L1
  de una transacción sin firmar: la [documentación de OP](https://docs.optimism.io/stack/transactions/fees)
  explica la fórmula.
- Optimizar gas en una L2 (semana 29) es sobre todo recortar bytes: argumentos más pequeños,
  menos llamadas con arrays grandes. El storage cuesta lo mismo que en L1 en unidades de gas, pero
  el gas es mucho más barato.
- Las cifras de esta teoría (2 s por bloque, 7 días de ventana, 12 horas para forzar) son del OP
  Stack y de Arbitrum hoy: compruébalas en la documentación de cada red antes de diseñar con ellas.

## ✅ Checklist

- [ ] Sé qué es una L2 y qué la hace rollup.
- [ ] Sé qué hace el secuenciador y qué es una confirmación blanda.
- [ ] Sé qué son los blobs y la disponibilidad de datos.
- [ ] Sé distinguir un rollup optimista de uno ZK y por qué uno tarda 7 días en las retiradas.
- [ ] Sé qué paga una transacción en una L2 y por qué los bytes cuentan.
- [ ] Sé qué riesgos trae el secuenciador y quién puede actualizar un rollup.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Semana 33 — L2 y cross-chain](../README.md) | **Teoría 01 — Rollups** | [Teoría 02 — Desplegar en una L2 →](02-desplegar-en-una-l2.md) |
