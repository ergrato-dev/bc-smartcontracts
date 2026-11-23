# Rúbrica de evaluación — Semana 20: Oráculos y datos off-chain

## 📊 Distribución de evidencias

| Tipo | Peso | Instrumento |
| ---- | ---- | ----------- |
| Conocimiento 🧠 | 30 % | Cuestionario de autoevaluación (10 preguntas) |
| Desempeño 💪 | 40 % | Ejercicios 01, 02 y 03 |
| Producto 📦 | 30 % | Proyecto: tasa en dólares con un oráculo |

**Nota mínima para aprobar**: 70 % en **cada** tipo de evidencia, no en el promedio.

---

## 🧠 Conocimiento (30 %)

Responde por escrito, sin mirar la teoría. Las respuestas están al final, plegadas.

| # | Pregunta | Puntos |
| - | -------- | ------ |
| 1 | ¿Por qué un contrato no puede pedir un precio a una API, y qué pregunta nueva aparece cuando un oráculo lo escribe en la cadena? | 10 |
| 2 | ¿Por qué un price feed usa la mediana de muchos nodos, y por qué tu contrato guarda la dirección del proxy y no la del agregador? | 10 |
| 3 | ¿Qué son la desviación y el latido de un feed, y qué dicen de la antigüedad máxima que debes aceptar? | 10 |
| 4 | Con un feed de 8 decimales a 3000 dólares, ¿cuántos wei son 25 dólares guardados como `25e18`? ¿Por qué se lee `decimals()` y hacia dónde se redondea? | 10 |
| 5 | ¿Qué pasa si tu contrato exige el importe exacto calculado con un feed, y qué alternativa hay? | 10 |
| 6 | ¿Por qué `block.prevrandao` no sirve para un sorteo, aunque nadie lo conozca antes del bloque? | 10 |
| 7 | ¿Qué garantiza la prueba de una VRF, y por qué el nodo de VRF espera confirmaciones antes de responder? | 10 |
| 8 | ¿Por qué `fulfillRandomWords` apunta el premio en vez de enviarlo, y qué cierras entre la petición y la respuesta? | 10 |
| 9 | ¿Qué hay dentro de un CID v1 y por qué un `ipfs://<CID>` en el `tokenURI` no puede cambiar de contenido? | 10 |
| 10 | Has subido la imagen de tu colección con `ipfs add` en tu portátil. ¿Qué falta para que siga disponible, y qué pasa si nadie la fija? | 10 |

**Total**: 100 puntos → 30 % de la nota.

<details>
<summary>Respuestas</summary>

1. Todos los nodos ejecutan cada transacción y deben llegar al mismo estado: una petición HTTP
   daría respuestas distintas en cada nodo. Un oráculo lo resuelve escribiendo el dato con una
   transacción, y la pregunta pasa a ser de quién te fías: el contrato es tan fiable como quien
   escribe el dato.
2. Con la mediana, un nodo que mienta o se caiga no mueve el resultado: hace falta controlar más
   de la mitad. El proxy tiene dirección fija y reenvía al agregador actual; si guardaras el
   agregador, al sustituirlo Chainlink dejaría de recibir rondas y tu contrato usaría un precio
   congelado.
3. El feed escribe una ronda cuando el precio se mueve más de la desviación (0,5 % en ETH/USD de
   Ethereum) o cuando pasa el latido (1 hora) sin rondas. Un precio puede tener hasta un latido;
   si tiene bastante más, el feed está parado. La antigüedad máxima es el latido más un margen,
   nunca ilimitada.
4. `25e18 × 1e8 / 3000e8 = 8333333333333333,33…`, que se cobra como `8333333333333334`. Se lee
   `decimals()` porque otro feed puede tener 18 y la cuenta saldría 10¹⁰ veces mal. Al cobrar se
   redondea hacia arriba (`Math.Rounding.Ceil`) y al pagar hacia abajo: el redondeo nunca regala
   valor.
5. Si el feed escribe una ronda entre que la página calcula la tasa y la transacción entra en un
   bloque, el importe ya no coincide y revierte con `WrongFee`. No se pierde dinero, pero el
   usuario repite. La alternativa es aceptar de más y devolver el cambio.
6. Porque dentro de la transacción lo lee cualquier contrato: un atacante calcula el resultado
   igual que tu contrato y solo juega si gana. Además, el validador puede no publicar un bloque
   cuyo valor le haga perder.
7. Que el número sale de la semilla y de la clave del nodo, y de ninguna otra forma: el nodo no
   puede elegirlo y nadie lo prevé sin su clave privada. Espera confirmaciones porque la semilla
   lleva datos del bloque de la petición: un reorg la cambiaría.
8. Si el ganador es un contrato que rechaza ETH, enviarlo haría revertir el callback y el
   coordinador no reintenta: el sorteo quedaría bloqueado. Apuntado, retira él después (patrón
   pull). Entre petición y respuesta se cierra la entrada: quien viera la respuesta en el mempool
   entraría con la posición ganadora.
9. La versión (`0x01`), el códec (`0x55`, `raw`), la función hash (`0x12`, sha2-256), la longitud
   (`0x20`) y el sha256 del contenido, en base32 con una `b` delante. Otro contenido tiene otro
   hash y, por tanto, otro CID: el enlace apunta siempre a los mismos bytes.
10. Que un nodo conectado a la red la tenga fijada: tu propio nodo encendido, un servicio de
    pinning o varios. Si nadie la fija, la recolección de basura la borra y el CID del contrato
    apunta a nada, aunque siga siendo válido si alguien vuelve a subir los mismos bytes.

</details>

---

## 💪 Desempeño (40 %)

| Ejercicio | Criterio | Puntos |
| --------- | -------- | ------ |
| 01 — Precio con Chainlink | `forge test`: `8 passed` | 15 |
| | Explica qué falla al quitar `Math.Rounding.Ceil` y por qué `buy` acepta de más | 10 |
| 02 — Sorteo con VRF | `forge test`: `7 passed` | 20 |
| | Explica por qué gana `Rejecter` sin bloquear el sorteo y por qué la respuesta vieja no decide nada tras `cancelDraw` | 10 |
| 03 — Metadatos en IPFS | `bash test.sh`: `5 de 5 pasos correctos` | 15 |
| | Explica de qué bytes sale el CID del paso 2 y por qué el paso 4 da un `bafybei` | 15 |
| Todos | Sin tocar `test/`, `test.sh` ni `certificado.svg` | 15 |

**Total**: 100 puntos → 40 % de la nota.

---

## 📦 Producto (30 %)

| Criterio | Puntos |
| -------- | ------ |
| Carpeta `week-20/` sin `out/`, `cache/` ni `broadcast/` de anvil, y pull request `week-20` → `main` | 10 |
| `bash test.sh`: `8 passed`, sin warnings | 30 |
| Lee `decimals()`, comprueba precio y antigüedad, redondea hacia arriba y guarda el proxy del feed | 15 |
| En anvil: actualización a V3, alta con la tasa del feed y `StalePrice` con un precio viejo | 15 |
| En Sepolia: tu registro es V3 con el feed ETH/USD real y la implementación verificada | 15 |
| Tu página cobra `registrationFee()`; tu README dice `USD_FEE`, `MAX_PRICE_AGE` y en quién confías | 15 |

**Total**: 100 puntos → 30 % de la nota.

---

## 🏅 Bandas

| Banda | Rango |
| ----- | ----- |
| Sobresaliente | 90-100 |
| Notable | 80-89 |
| Aprobado | 70-79 |
| No aprobado | < 70 en alguna evidencia |

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Proyecto — Tasa en dólares con un oráculo](3-proyecto/README.md) | **Rúbrica de evaluación** | [Ebooks gratuitos →](4-recursos/ebooks-free/README.md) |
