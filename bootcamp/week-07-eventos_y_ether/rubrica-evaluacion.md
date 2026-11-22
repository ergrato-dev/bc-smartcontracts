# Rúbrica de evaluación — Semana 07: Eventos y ether

## 📊 Distribución de evidencias

| Tipo | Peso | Instrumento |
| ---- | ---- | ----------- |
| Conocimiento 🧠 | 30 % | Cuestionario de autoevaluación (10 preguntas) |
| Desempeño 💪 | 40 % | Ejercicios 01, 02 y 03 |
| Producto 📦 | 30 % | Proyecto: registro con tasas y eventos en tu repositorio |

**Nota mínima para aprobar**: 70 % en **cada** tipo de evidencia, no en el promedio.

---

## 🧠 Conocimiento (30 %)

Responde por escrito, sin mirar la teoría. Las respuestas están al final, plegadas.

| # | Pregunta | Puntos |
| - | -------- | ------ |
| 1 | Tu contrato emite `Registered(id)` y necesita saber más tarde si un id se registró. ¿Puede consultar sus eventos? ¿Qué haces? | 10 |
| 2 | ¿Qué hay en el topic 0 de un log y cómo lo calculas desde la terminal? | 10 |
| 3 | ¿Por qué un evento admite como mucho tres parámetros `indexed`, y cuáles indexarías en `Transfer(from, to, amount)`? | 10 |
| 4 | Una función emite un evento y, dos líneas después, revierte. ¿Qué queda en el recibo? | 10 |
| 5 | ¿Cuánto vale `msg.value` si alguien paga `0.5 ether`? ¿Y `1 days`? | 10 |
| 6 | Un contrato autoriza con `tx.origin == OWNER`. Describe cómo se salta. | 10 |
| 7 | Envías ETH a un contrato sin datos. Tiene `fallback() external payable` y no tiene `receive`. ¿Qué se ejecuta? ¿Y si `fallback` no es `payable`? | 10 |
| 8 | ¿Por qué `transfer` puede fallar al pagar a una cartera multifirma y `call` no? ¿Qué obliga a hacer `call`? | 10 |
| 9 | Describe un ataque de reentrada contra un `withdrawAll` que pone el saldo a 0 después del envío, y cómo lo evita checks-effects-interactions. | 10 |
| 10 | Un contrato reparte premios en un bucle y uno de los ganadores es un contrato que revierte al recibir ETH. ¿Qué pasa? ¿Qué diseño lo evita? | 10 |

**Total**: 100 puntos → 30 % de la nota.

<details>
<summary>Respuestas</summary>

1. No: un contrato no puede leer logs, ni los suyos. Si la lógica necesita el dato, se
   guarda en storage (un mapping o un estado); el evento es para quien está fuera.
2. El keccak256 de la firma del evento, con los tipos y sin nombres ni `indexed`:
   `cast keccak "Registered(uint256)"`. En Solidity es `Registered.selector`.
3. Un log tiene como mucho cuatro topics y el topic 0 ya es el identificador del evento.
   En `Transfer` se indexan `from` y `to`, que es por lo que se busca; `amount` va en `data`.
4. Nada: el revert deshace el estado y también los eventos emitidos antes. El recibo dice
   `status 0` y no tiene logs.
5. `500000000000000000` (5 × 10^17 wei). `1 days` es `86400` (segundos).
6. El dueño llama a un contrato malicioso (por ejemplo, creyendo que reclama un premio). Ese
   contrato llama al tuyo: `msg.sender` es el malicioso, pero `tx.origin` sigue siendo el
   dueño y la guarda pasa. Se autoriza con `msg.sender`.
7. Se ejecuta `fallback`. Si no es `payable`, la transferencia revierte.
8. `transfer` le da al destino solo 2300 de gas, y una multifirma ejecuta código al recibir
   que no cabe. `call` le da todo el gas que queda, pero no revierte si falla: hay que
   comprobar el `bool` que devuelve y ordenar la función en CEI.
9. El atacante deposita y llama a `withdrawAll`. Al recibir el ETH, su `receive` vuelve a
   llamar a `withdrawAll`; su saldo todavía no está a 0, así que cobra otra vez, hasta
   vaciar la caja. Con CEI el saldo se pone a 0 antes del envío: la segunda llamada no
   tiene nada que retirar.
10. El envío a ese contrato falla y, si se comprueba (como se debe), todo el reparto
    revierte: nadie cobra, nunca. Es un DoS. Se evita con pagos *pull*: el contrato apunta
    cuánto le debe a cada uno y cada ganador retira lo suyo.

</details>

---

## 💪 Desempeño (40 %)

| Ejercicio | Criterio | Puntos |
| --------- | -------- | ------ |
| 01 — Eventos | `forge test`: 5 de 5 sin warnings | 15 |
| | Explica qué publicaba `Edited` sin la copia `oldText` | 10 |
| 02 — Recibir ETH | `forge test`: 5 de 5 sin warnings | 15 |
| | Explica cuándo se ejecuta `receive`, cuándo `fallback` y qué riesgo tiene el bote tal como está | 15 |
| 03 — Enviar ETH | `forge test`: 4 de 4 sin warnings | 25 |
| | Explica cómo el atacante se lleva 6 ETH con el orden equivocado | 20 |

**Total**: 100 puntos → 40 % de la nota.

---

## 📦 Producto (30 %)

| Criterio | Puntos |
| -------- | ------ |
| Carpeta `week-07/` en tu repositorio, sin `out/` ni `cache/`, y pull request `week-07` → `main` | 10 |
| `forge test`: 37 de 37 tests en verde, sin warnings | 40 |
| Desplegado en anvil desde la cuenta de tu `INDEX`, con la salida de `forge create`, las llamadas, los logs y los tres errores en el pull request | 15 |
| `withdrawFees` en orden CEI con el resultado de `call` comprobado; `indexed` en ids y cuentas | 10 |
| NatSpec en el constructor y en todas las funciones `external` | 10 |
| Calidad: sin `// TODO:` restantes, identificadores en inglés y comentarios en español, mensaje de commit claro | 15 |

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
| [← Proyecto — Registro con tasas y eventos](3-proyecto/README.md) | **Rúbrica de evaluación** | [Ebooks gratuitos →](4-recursos/ebooks-free/README.md) |
