# Rúbrica de evaluación — Semana 22: Vulnerabilidades económicas

## 📊 Distribución de evidencias

| Tipo | Peso | Instrumento |
| ---- | ---- | ----------- |
| Conocimiento 🧠 | 30 % | Cuestionario de autoevaluación (10 preguntas) |
| Desempeño 💪 | 40 % | Ejercicios 01, 02 y 03 |
| Producto 📦 | 30 % | Proyecto: ataques económicos a tu protocolo |

**Nota mínima para aprobar**: 70 % en **cada** tipo de evidencia, no en el promedio.

---

## 🧠 Conocimiento (30 %)

Responde por escrito, sin mirar la teoría. Las respuestas están al final, plegadas.

| # | Pregunta | Puntos |
| - | -------- | ------ |
| 1 | Un pool tiene 1 000 000 USD y 1000 GOV. ¿Cuánto GOV da un swap de 1 000 000 USD y en cuánto deja el precio? ¿Por qué eso no es un fallo del pool? | 10 |
| 2 | ¿Por qué un precio al contado se mueve en una transacción y un TWAP no? ¿Cuándo un TWAP tampoco te protege? | 10 |
| 3 | ¿Por qué quien presta con un flash loan no arriesga nada, y qué cambia eso en la forma de revisar un contrato? | 10 |
| 4 | Tu prestatario implementa `onFlashLoan`. ¿Qué dos cosas compruebas al principio y qué pasa si no compruebas cada una? | 10 |
| 5 | ¿Qué es la mempool, quién decide el orden de un bloque y con qué criterio? | 10 |
| 6 | Describe un sándwich alrededor de un swap. ¿De dónde sale el beneficio del atacante? | 10 |
| 7 | ¿Por qué `minAmountOut` se calcula fuera de la cadena, y para qué sirve además `deadline`? | 10 |
| 8 | En un commit-reveal, ¿por qué el hash lleva `msg.sender` y por qué la revelación tiene que ser en un bloque posterior? | 10 |
| 9 | En una bóveda, ¿hacia dónde redondeas las participaciones de un depósito, los tokens de una retirada y las participaciones que cuesta sacar N tokens? ¿Por qué? | 10 |
| 10 | Explica el ataque de inflación y por qué revertir con 0 participaciones no basta. ¿Qué añaden las participaciones virtuales? | 10 |

**Total**: 100 puntos → 30 % de la nota.

<details>
<summary>Respuestas</summary>

1. El producto de las reservas se mantiene: 10⁹. Con 2 000 000 USD, la reserva de GOV baja a
   500: el swap da 500 GOV y el precio pasa a 2 000 000 / 500 = 4000 USD. No es un fallo: el
   precio de un pool lo fijan las compras y ventas, y el arbitraje lo devuelve a su sitio. El
   fallo es de quien usa ese precio dentro de la misma transacción en que se puede mover.
2. Un precio al contado sale de las reservas de ahora, y un swap las cambia en la misma
   transacción. Un TWAP es la media de un periodo: para moverlo hay que sostener el precio
   falso muchos bloques, pagando a los arbitrajistas que lo corrigen. No protege si el periodo
   es corto o el pool tiene poca liquidez: sostener el precio sale barato.
3. Porque la transacción es atómica: si al final el préstamo no ha vuelto, el prestamista
   revierte y todo lo que pasó se deshace. Al revisar, ya no vale "¿quién tiene tanto dinero?":
   hay que suponer que el atacante tiene todo el capital que exista durante una transacción, y
   desconfiar de cualquier decisión tomada con saldos, precios o votos del momento.
4. Que `msg.sender` es el prestamista: si no, cualquiera llama a `onFlashLoan` fingiendo un
   préstamo. Y que `initiator` es tu propio contrato: si no, cualquiera pide un préstamo para
   ti, cuando él quiere, y tu contrato ejecuta su lógica y paga la comisión de su saldo.
5. La lista de transacciones firmadas que todavía no están en un bloque; cualquier nodo la ve
   entera. El orden lo decide el constructor del bloque, que lo vende al validador que propone;
   ordena para ganar lo máximo: por propina, y metiendo sus transacciones donde más le rinden.
6. El atacante ve el swap de la víctima en la mempool, compra lo mismo justo antes (sube el
   precio), deja que la víctima compre al precio inflado, y vende justo después. El beneficio
   es la diferencia de precio que paga la víctima: en el ejercicio, Alice recibe 41,6 GOV en
   vez de 90,9 y el atacante gana 56 521 USD.
7. Porque dentro de la transacción el precio ya puede estar movido: un mínimo calculado ahí
   aceptaría el precio del atacante. Quien firma lo calcula con el precio que ve y su
   tolerancia. `deadline` evita que una transacción espere en la mempool hasta que el precio
   convenga a otro.
8. Con `msg.sender` en el hash, copiar el compromiso de otro no sirve: al revelar, el hash se
   recalcula con la dirección del copión y no coincide. En un bloque posterior, porque quien ve
   la respuesta en la revelación necesitaría un compromiso suyo de antes, y ya es tarde.
9. Participaciones de un depósito: hacia abajo. Tokens de una retirada: hacia abajo.
   Participaciones que cuesta sacar N tokens: hacia arriba. Siempre a favor de la bóveda, es
   decir, de los demás usuarios: si se redondea a favor de quien llama, puede repetirlo y
   sacar unidades gratis.
10. El primer depositante pone 1 wei (1 participación) y dona muchos tokens sin depositar: cada
    participación vale ahora una fortuna, y el depósito de la víctima se redondea a 0 o a muy
    pocas participaciones. Revertir con 0 solo cierra el caso extremo: con 1,49 redondeado a 1,
    la víctima sigue perdiendo 2500 de sus 15 000. Las participaciones virtuales reparten la donación
    también con participaciones que no son de nadie, así que el atacante pierde casi todo lo
    que dona.

</details>

---

## 💪 Desempeño (40 %)

| Ejercicio | Criterio | Puntos |
| --------- | -------- | ------ |
| 01 — Oráculo y flash loan | `forge test`: `7 passed` | 20 |
| | Explica por qué el mismo atacante no puede devolver el préstamo contra `FeedLender` | 10 |
| 02 — Front-running y MEV | `forge test`: `9 passed` | 15 |
| | Explica por qué `test_Paso2_SwapWithinSlippage` pasaba desde el principio y qué comprueba el test del sándwich que ese no | 10 |
| 03 — Redondeo | `forge test`: `7 passed` | 15 |
| | Explica por qué `test_Paso3_ZeroSharesIsNotEnough` sigue en verde después del paso 3 | 15 |
| Todos | Sin tocar `test/` ni los contratos marcados como "no lo arregles" | 15 |

**Total**: 100 puntos → 40 % de la nota.

---

## 📦 Producto (30 %)

| Criterio | Puntos |
| -------- | ------ |
| Carpeta `week-22/` sin `out/`, `cache/` ni `broadcast/` de anvil, y pull request `week-22` → `main` | 10 |
| `bash test.sh`: `8 passed`, `7 passed` y `9 passed`, sin warnings | 30 |
| La devolución va al final de `register`, `registerBySig` y `registerBatch`, después del hook | 15 |
| En anvil: el `WrongFee` antes de `PatchV3` y el alta con margen después | 10 |
| `audit/README.md`: revisión económica de las cuatro clases en tu protocolo, con las que no aplican justificadas | 20 |
| H-02 con severidad justificada, y el front-running de lo que sea único en tu dominio | 15 |

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
| [← Proyecto — Ataques económicos a tu protocolo](3-proyecto/README.md) | **Rúbrica de evaluación** | [Ebooks gratuitos →](4-recursos/ebooks-free/README.md) |
