# Rúbrica de evaluación — Semana 33: L2 y cross-chain

## 📊 Distribución de evidencias

| Tipo | Peso | Instrumento |
| ---- | ---- | ----------- |
| Conocimiento 🧠 | 30 % | Cuestionario de autoevaluación (10 preguntas) |
| Desempeño 💪 | 40 % | Ejercicios 01, 02 y 03 |
| Producto 📦 | 30 % | Proyecto: tu protocolo en una L2 |

**Nota mínima para aprobar**: 70 % en **cada** tipo de evidencia, no en el promedio.

---

## 🧠 Conocimiento (30 %)

Responde por escrito, sin mirar la teoría. Las respuestas están al final, plegadas.

| # | Pregunta | Puntos |
| - | -------- | ------ |
| 1 | ¿Qué publica un rollup en L1 y por qué eso le permite heredar parte de la seguridad de Ethereum? | 10 |
| 2 | ¿Por qué una retirada de un rollup optimista tarda siete días y una de un rollup ZK no? | 10 |
| 3 | ¿Qué diferencia hay entre una confirmación blanda del secuenciador y que el lote esté en L1? ¿A quién le importa? | 10 |
| 4 | ¿Por qué en una L2 los bytes de una transacción pesan más en su coste que los opcodes? | 10 |
| 5 | Con la misma dirección en dos cadenas, ¿qué impide que una firma EIP-712 valga en las dos, y por qué se calcula con `block.chainid` al verificar? | 10 |
| 6 | ¿Por qué un contrato en una L2 mira el feed de disponibilidad del secuenciador antes del precio, y para qué sirve el plazo de gracia? | 10 |
| 7 | En un puente de bloquear y acuñar, ¿qué invariante se rompe si alguien acuña sin bloquear, y quién pierde? | 10 |
| 8 | ¿Qué dos comprobaciones hace un contrato que recibe mensajes de otra cadena, y qué ataque abre la falta de cada una? | 10 |
| 9 | ¿Por qué el mensajero no revierte cuando la llamada al destino falla, y quién puede reintentar un mensaje fallido? | 10 |
| 10 | En el proyecto, ¿por qué la DAO se queda en L1, por qué un feed envoltorio y no un `RegistryV4`, y por qué el guardián conserva la pausa en la L2? | 10 |

**Total**: 100 puntos → 30 % de la nota.

<details>
<summary>Respuestas</summary>

1. Publica los datos de todas sus transacciones (hoy en blobs) y raíces de estado. Con los datos,
   cualquiera reconstruye el estado de la L2 sin pedir permiso al rollup, y L1 decide qué raíz es
   la buena (por pruebas de fraude o de validez). Lo que L1 no comprueba (el orden, la
   disponibilidad del secuenciador, quién actualiza los contratos del rollup) no se hereda.
2. En un rollup optimista la raíz se da por buena salvo que alguien demuestre que es falsa: L1 solo
   se fía de ella cuando acaba la ventana de disputa, y la retirada se demuestra contra esa raíz. En
   uno ZK la raíz llega con una prueba de validez que L1 verifica: en cuanto la verifica, se fía.
3. La confirmación blanda es una promesa del secuenciador: hasta que el lote está en un bloque de
   L1, puede reordenar o perder la transacción. Importa a quien acredita algo de valor al instante
   (un puente, un exchange): corre ese riesgo, o espera al bloque de L1.
4. Porque la ejecución en la L2 es barata (mucho espacio por bloque), y cada transacción paga
   además su parte de publicar sus bytes, comprimidos, en L1: la tarifa de datos de L1.
5. El `chainId` del dominio: con la misma dirección, es lo único que distingue un contrato de su
   gemelo. Se calcula con `block.chainid` al verificar porque, si la cadena se divide, un valor
   guardado al desplegar seguiría aceptando en la copia las firmas de la original.
6. Si el secuenciador se cae, el feed de precios se queda con su último valor y el contrato lo
   leería como válido hasta `maxPriceAge`. El plazo de gracia cubre la vuelta: entran de golpe las
   transacciones que esperaban, y quien forzó las suyas por L1 tiene ventaja con un precio viejo.
7. Lo bloqueado en L1 == `totalSupply()` en la L2. Si alguien acuña sin bloquear, el bote de L1
   no alcanza para todos: pierden los últimos en retirar, que no encuentran respaldo.
8. Que `msg.sender` es el mensajero (si no, cualquiera llama directamente) y que
   `xDomainMessageSender()` es el remitente esperado (si no, cualquiera envía un mensaje desde la
   otra cadena con `sendMessage`, que no pide permiso).
9. Revertir desharía la entrega entera y el mensaje se perdería. Lo apunta como fallido, y
   cualquiera puede reintentarlo con los mismos datos; entregar uno nuevo sigue siendo solo del
   sistema del rollup.
10. Los votos están en L1, y un mensaje de L1 a la L2 tarda minutos mientras uno de vuelta tarda
    siete días. El envoltorio se pone con `setFeeConfig`, sin otra implementación ni otro mapa de
    storage, y se quita con otra llamada. Una propuesta tarda la votación más dos días: para un
    incidente en la L2, el guardián pausa sin esperar.

</details>

---

## 💪 Desempeño (40 %)

| Ejercicio | Criterio | Puntos |
| --------- | -------- | ------ |
| 01 — Un contrato en varias cadenas | `forge test` sin error: `11 tests passed, 0 failed` | 15 |
| | Explica por qué el vale del gemelo de L1 no vale en la L2 aunque la dirección sea la misma | 10 |
| 02 — Mensajes entre cadenas | `forge test` sin error: `12 tests passed, 0 failed` | 15 |
| | Explica qué ataque para cada una de las dos comprobaciones de `RemoteGreeter` | 10 |
| 03 — Un puente de tokens | `forge test` sin error: `10 tests passed, 0 failed` | 15 |
| | Explica qué comprueba el fuzz del respaldo y qué cambio en el puente lo rompería | 15 |
| Todos | Sin tocar `foundry.toml` ni los tests | 20 |

**Total**: 100 puntos → 40 % de la nota.

---

## 📦 Producto (30 %)

| Criterio | Puntos |
| -------- | ------ |
| Carpeta `week-33/` sin `out/`, `cache/`, `crytic-export/` ni `.env`, con `contracts/snapshots/RegisterGasTest.json`, y pull request `week-33` → `main` | 10 |
| `bash test.sh` sin error: informe, gas con snapshots, 79 tests, specs, `forge lint`, Slither, detector, Medusa y los treinta y ocho mutantes muertos | 25 |
| El script deja al ejecutor como único admin y el feed nuevo; el feed y el ejecutor hacen sus comprobaciones | 25 |
| Informe: alcance, actores, activos, fronteras 8 y 9, T-25 a T-29 con su prueba y la sección `## El protocolo en L2 (semana 33)` | 25 |
| T-29 justificado con los plazos de la L2 elegida, y el tiempo de una propuesta de L1 a la L2 explicado | 15 |

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
| [← Proyecto — Tu protocolo en una L2](3-proyecto/README.md) | **Rúbrica de evaluación** | [Ebooks gratuitos →](4-recursos/ebooks-free/README.md) |
