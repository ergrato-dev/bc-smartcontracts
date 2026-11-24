# Rúbrica de evaluación — Semana 25: Verificación formal

## 📊 Distribución de evidencias

| Tipo | Peso | Instrumento |
| ---- | ---- | ----------- |
| Conocimiento 🧠 | 30 % | Cuestionario de autoevaluación (10 preguntas) |
| Desempeño 💪 | 40 % | Ejercicios 01, 02 y 03 |
| Producto 📦 | 30 % | Proyecto: specs de tu protocolo |

**Nota mínima para aprobar**: 70 % en **cada** tipo de evidencia, no en el promedio.

---

## 🧠 Conocimiento (30 %)

Responde por escrito, sin mirar la teoría. Las respuestas están al final, plegadas.

| # | Pregunta | Puntos |
| - | -------- | ------ |
| 1 | Un test de fuzz pasa 100 000 ejecuciones y Halmos encuentra un contraejemplo en la misma propiedad. ¿Cómo es posible? Usa la caja fuerte de la teoría 01. | 10 |
| 2 | ¿Qué es una condición de camino, y qué pregunta se le hace al solver en cada aserción? | 10 |
| 3 | Di las tres respuestas posibles de un solver SMT y qué significa cada una para tu spec. | 10 |
| 4 | ¿Qué cubre el SMTChecker con CHC que no cubre Halmos, y al revés? | 10 |
| 5 | El SMTChecker da un contraejemplo con `reserve(8)` cuando el máximo es 4. ¿Qué ha pasado y cómo lo compruebas? | 10 |
| 6 | ¿Qué significa "could not be proved" en el SMTChecker? ¿Y `TIMEOUT` en Halmos? | 10 |
| 7 | ¿Por qué una spec de Halmos que exige una aceptación usa `try`? Usa el paso 4 del ejercicio 02. | 10 |
| 8 | Halmos da `[PASS]` con el aviso "paths have not been fully explored due to the loop unrolling bound: 2". ¿Qué se ha demostrado y qué harías? | 10 |
| 9 | ¿Qué hace `svm.createCalldata("Token")`, y por qué el proyecto usa una lista explícita con `which`? | 10 |
| 10 | ¿Por qué el `setUp` del proyecto pone el proxy con `vm.etch` en vez de usar el handler de la semana 24? | 10 |

**Total**: 100 puntos → 30 % de la nota.

<details>
<summary>Respuestas</summary>

1. El fuzz prueba una muestra: un solo `uint64` de 2⁶⁴ abre la caja, y ni el azar ni el
   diccionario del bytecode llegan a él. Halmos no prueba valores: plantea la ecuación
   `code ^ 0x5eed5eed5eed == 0x1234abcd9876` y el solver la resuelve.
2. Lo que tiene que ser verdad de las entradas para que la ejecución pase por ese camino. En cada
   aserción: ¿hay entradas que cumplan la condición de camino y hagan fallar la aserción?
3. `sat`: hay entradas que la rompen, con un contraejemplo. `unsat`: ninguna la rompe en ese
   camino; si todos los caminos dan `unsat`, la spec está demostrada. `unknown` o tiempo agotado:
   no se sabe nada.
4. CHC cubre cualquier secuencia de transacciones, de cualquier longitud. Halmos cubre la
   secuencia que escribe el test, pero aguanta protocolos reales: OpenZeppelin, proxies, errores
   personalizados, cheatcodes.
5. El SMTChecker no entiende `revert InvalidAmount(amount)` y da por buena una llamada que
   revierte: el contraejemplo es espurio. Se comprueba con un test que repite la secuencia: la
   reserva grande revierte.
6. Ninguno de los dos es un fallo ni una demostración: el solver no lo resolvió. La propiedad se
   prueba de otra forma o el informe dice que no se demostró.
7. Porque en Halmos un camino que revierte no falla: se descarta. Sin `try`, un calendario que
   rechaza de más pasa la spec, como en el paso 4. Con `try`, el rechazo deja `accepted = false` y
   el `assert` falla.
8. Solo los caminos con hasta 2 vueltas del bucle; lo demás no se exploró. Subir `--loop` hasta
   cubrir el rango del `assume` (o acotar el rango), o escribir el límite en el informe.
9. Una llamada a cualquier función no `view` de `Token`, con argumentos simbólicos, más una con
   cualquier otro selector. Con todo `RegistryV3`, `multicall` y los arrays multiplican los
   caminos (`ERROR` tras 464 segundos); con una interfaz parcial, el "cualquier otro selector"
   llega a funciones que sí existen. La lista explícita es rápida y dice qué se prueba.
10. Halmos no da a los contratos la dirección de la fórmula de `CREATE`: los numera. El handler
    calcula la dirección del proxy con esa fórmula para dársela al token y al certificado, y en
    Halmos no coincide. Con `vm.etch` y `vm.store`, el proxy va a una dirección elegida.

</details>

---

## 💪 Desempeño (40 %)

| Ejercicio | Criterio | Puntos |
| --------- | -------- | ------ |
| 01 — SMTChecker | `forge test` sin error, `7 passed`, y `CHC: Assertion violation check is safe!` | 15 |
| | Explica por qué el primer contraejemplo era imposible y el segundo no | 10 |
| 02 — Halmos | `bash test.sh` sin error: las dos specs en `[PASS]` | 15 |
| | Explica por qué la spec sin `try` del paso 4 pasaba con un calendario demasiado estricto | 10 |
| 03 — Specs de contrato | `bash test.sh` sin error: `6 passed` y las dos specs en `[PASS]` | 20 |
| | Explica qué función encontró `createCalldata` y por qué ningún test unitario la probaba así | 15 |
| Todos | Sin tocar `foundry.toml`, `halmos.toml` ni los archivos marcados "no lo modifiques" | 15 |

**Total**: 100 puntos → 40 % de la nota.

---

## 📦 Producto (30 %)

| Criterio | Puntos |
| -------- | ------ |
| Carpeta `week-25/` sin `out/`, `cache/` ni `crytic-export/`, y pull request `week-25` → `main` | 10 |
| `bash test.sh` sin error: tests, las cinco specs sin avisos, `forge lint`, Slither, detector, Medusa y los diez mutantes muertos | 30 |
| Las cuatro specs: comprueban lo que se debe aceptar y lo que se debe rechazar con `try` o `call` y un `assert` | 20 |
| Cada `vm.assume` tiene su motivo | 10 |
| `audit/README.md`: specs, herramienta, mutantes y lo que no se demostró | 20 |
| Una spec propia de tu dominio, o el porqué de no necesitarla | 10 |

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
| [← Proyecto — Specs de tu protocolo](3-proyecto/README.md) | **Rúbrica de evaluación** | [Ebooks gratuitos →](4-recursos/ebooks-free/README.md) |
