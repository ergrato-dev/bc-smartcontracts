# Rúbrica de evaluación — Semana 29: Optimización de gas

## 📊 Distribución de evidencias

| Tipo | Peso | Instrumento |
| ---- | ---- | ----------- |
| Conocimiento 🧠 | 30 % | Cuestionario de autoevaluación (10 preguntas) |
| Desempeño 💪 | 40 % | Ejercicios 01, 02 y 03 |
| Producto 📦 | 30 % | Proyecto: un alta más barata |

**Nota mínima para aprobar**: 70 % en **cada** tipo de evidencia, no en el promedio.

---

## 🧠 Conocimiento (30 %)

Responde por escrito, sin mirar la teoría. Las respuestas están al final, plegadas.

| # | Pregunta | Puntos |
| - | -------- | ------ |
| 1 | El recibo de `set(2)` dice 26 618. ¿De dónde sale cada parte de ese número? | 10 |
| 2 | ¿Por qué `set(3)` justo después de `set(2)` da 514 con `--no-isolate` y 26 618 sin él? ¿Cuál de los dos paga un usuario? | 10 |
| 3 | `vm.lastFrameGas().gasTotalUsed` y el recibo de anvil dan números distintos para `set(0)`. ¿Por qué, y cuál es cada uno? | 10 |
| 4 | ¿Por qué el struct `Tight` de la teoría 02 gasta 21 872 menos que `Loose` con los mismos campos? ¿Cuándo empaquetar no ahorra? | 10 |
| 5 | Un cerrojo que pasa de 0 a 1 y vuelve a 0 debería recuperar casi todo con el reembolso. ¿Por qué paga 38 886 y uno de 1 y 2, 28 709? | 10 |
| 6 | En el paso 3 del ejercicio 02, cambiar `memory` por `storage` ahorra más de 30 000. ¿Por qué, si la línea casi no cambia? ¿Y por qué el paso 4 no habría ahorrado nada antes del 3? | 10 |
| 7 | ¿Qué significa `optimizer_runs`? Con los números del registro, ¿por qué no pasar de 200 a 10 000? | 10 |
| 8 | En la teoría 04, `!= 0` parece ahorrar 25 y `public` parece ahorrar 66. ¿De dónde sale de verdad esa diferencia, y cómo se compara bien? | 10 |
| 9 | En el paso 3 del ejercicio 03, leer el saldo una vez es una buena optimización y aun así deja robar el bote. ¿Qué falla y cómo se arregla sin perder el ahorro? | 10 |
| 10 | En el proyecto, ¿por qué no quitas `id` del struct `Item`, si no hace falta guardarlo? ¿Qué mutante solo lo mata la comprobación de snapshots, y por qué? | 10 |

**Total**: 100 puntos → 30 % de la nota.

<details>
<summary>Respuestas</summary>

1. 21 000 de gas base, que paga cualquier transacción; 204 de calldata, porque `set(2)` envía 36
   bytes, 5 distintos de cero a 16 cada uno y 31 a cero a 4 cada uno; y 5414 de ejecución, de los
   que 5000 son el `SSTORE` frío de 1 a 2 (2900 + 2100). 21 000 + 204 + 5414 = 26 618.
2. Con `--no-isolate`, las dos llamadas se ejecutan dentro de la misma transacción del test: no
   hay gas base ni calldata, y el slot ya está caliente y ya cambió, así que su `SSTORE` cuesta
   100. Con aislamiento, que es lo que hay por defecto en Foundry 1.9, cada llamada es su propia
   transacción con todo frío. El usuario paga el de 26 618: en la cadena, cada uno envía su
   transacción.
3. `gasTotalUsed` es el gas usado antes del reembolso: 26 606. El recibo ya resta el reembolso de
   4800 por poner el slot a cero: 21 806. `gasRefunded` da esos 4800. Para saber lo que se paga,
   el recibo, o `gasTotalUsed` menos `gasRefunded` con el tope de un quinto.
4. Solc mete en un slot los campos consecutivos que caben en 32 bytes, en el orden declarado. En
   `Loose`, `kind` deja 31 bytes libres que `amount` no puede usar, y el struct ocupa tres slots;
   en `Tight`, `buyer`, `createdAt` y `kind` comparten uno y ocupa dos. Un slot nuevo menos es un
   `SSTORE` frío de cero a otro valor menos. No ahorra si el tipo pequeño va solo en su slot
   (cuesta más: hay que aislar su byte) ni si los campos del slot se escriben en transacciones
   distintas.
5. Porque el reembolso no pasa de un quinto del gas usado (EIP-3529). El de 0 y 1 paga 22 100 por
   escribir en un slot a cero y le corresponderían 19 900 al devolverlo a cero, pero el tope es
   48 607 / 5 = 9721. El de 1 y 2 nunca pasa por cero: paga 5000 y recupera 2800. El `transient`
   no escribe storage: 27 043.
6. `memory` copia el empleado entero: el slot del `name` y el de `blocked` y `hiredAt`, dos
   `SLOAD` fríos por empleado, 2100 cada uno. `storage` es solo el número del slot y `e.blocked`
   lee el suyo. Con 10 empleados, 10 lecturas frías menos. Antes del paso 3, la copia ya había
   leído `blocked` antes de la condición, así que poner primero `amounts[i] == 0` no se ahorra
   ningún `SLOAD`: con el ejercicio da 30 más, no menos.
7. Es cuántas veces esperas que se ejecute cada instrucción en la vida del contrato: con pocas, el
   optimizador prefiere bytecode pequeño; con muchas, bytecode grande y barato de ejecutar. De 200
   a 10 000, cada alta ahorra 331 de gas y el bytecode crece 3068 bytes, 613 600 de gas más en cada
   despliegue: hacen falta unas 1850 altas para recuperarlo, y el margen hasta 24 576 bytes baja de
   9459 a 6391.
8. Del dispatcher: el contrato compara el selector con los de sus funciones en orden, y la que se
   encuentra antes gasta unas decenas menos. Cambiando `public` por `external` las dos funciones
   son idénticas y los números siguen igual. Se compara con el mismo nombre de función en dos
   contratos distintos: así, `> 0` y `!= 0` dan 43 861 y 43 858 sin optimizador, y 43 607 los dos
   con él.
9. Escribe el saldo nuevo **después** de enviar el ETH. Mientras tanto, el atacante vuelve a
   entrar en `withdraw` y encuentra el saldo de storage sin cambiar: la comprobación pasa y recibe
   otra vez. Se arregla moviendo la escritura antes de la llamada (checks-effects-interactions,
   semana 21): sigue siendo una lectura y una escritura, así que el ahorro se mantiene.
10. Porque el registro está detrás de un proxy con recursos dados de alta: quitar el primer campo
    movería los demás un slot y V3 leería cada dato del sitio de otro (semana 15). Por eso el campo
    se queda y solo se deja de escribir. El mutante `el alta lee count una vez más` añade una
    lectura a la `assert`: no cambia nada de lo que hace el registro, así que ningún test de
    comportamiento falla; solo sube el gas, y lo ve `FORGE_SNAPSHOT_CHECK=true` al comparar con el
    archivo.

</details>

---

## 💪 Desempeño (40 %)

| Ejercicio | Criterio | Puntos |
| --------- | -------- | ------ |
| 01 — Storage barato | `forge test` sin error: `10 tests passed, 0 failed` | 15 |
| | Explica cuánto ahorró cada paso y por qué el 2 ahorra mucho menos que el 1 | 10 |
| 02 — Código barato | `forge test` sin error: `7 tests passed, 0 failed` | 10 |
| | Explica por qué el orden de los pasos 3 y 4 importa, y qué pasa al quitar la comprobación del paso 5 | 10 |
| 03 — Optimizar sin romper | `forge test` sin error: `6 tests passed, 0 failed` | 15 |
| | Para cada paso, nombra la optimización, el fallo y qué test de borde lo ve | 20 |
| Todos | Sin tocar `foundry.toml` ni los tests | 20 |

**Total**: 100 puntos → 40 % de la nota.

---

## 📦 Producto (30 %)

| Criterio | Puntos |
| -------- | ------ |
| Carpeta `week-29/` sin `out/`, `cache/` ni `crytic-export/`, con `contracts/snapshots/RegisterGasTest.json`, y pull request `week-29` → `main` | 10 |
| `bash test.sh` sin error: informe, gas con snapshots, tests, specs, `forge lint`, Slither, detector, Medusa y los veinte mutantes muertos | 25 |
| `_register` sin escribir `id`, `getItem` con el id de la clave, `Item` sin cambios y el mapa de storage actualizado con su comentario | 25 |
| Sección `## Gas (semana 29)`: antes y después, lo que cuesta, tests, mutantes y lo que no se hizo | 20 |
| Decisión sobre `optimizer_runs` con tus números de tamaño y de gas | 20 |

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
| [← Proyecto — Un alta más barata](3-proyecto/README.md) | **Rúbrica de evaluación** | [Ebooks gratuitos →](4-recursos/ebooks-free/README.md) |
