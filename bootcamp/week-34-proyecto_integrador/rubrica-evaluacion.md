# Rúbrica de evaluación — Semana 34: Integración final y auditoría cruzada

## 📊 Distribución de evidencias

| Tipo | Peso | Instrumento |
| ---- | ---- | ----------- |
| Conocimiento 🧠 | 30 % | Cuestionario de autoevaluación (10 preguntas) |
| Desempeño 💪 | 40 % | Ejercicios 01, 02 y 03 |
| Producto 📦 | 30 % | Proyecto: la entrega final |

**Nota mínima para aprobar**: 70 % en **cada** tipo de evidencia, no en el promedio.

---

## 🧠 Conocimiento (30 %)

Responde por escrito, sin mirar la teoría. Las respuestas están al final, plegadas.

| # | Pregunta | Puntos |
| - | -------- | ------ |
| 1 | ¿Por qué un error de configuración no lo detecta ningún test del código? Pon un ejemplo real. | 10 |
| 2 | ¿Qué tres preguntas haces para comprobar un despliegue, y por qué `hasRole` no basta para la segunda? | 10 |
| 3 | Si `Deploy.run()` ya comprueba el resultado, ¿por qué ejecutar `CheckDeployment` otra vez contra la red? | 10 |
| 4 | ¿Por qué quien escribe un contrato no es quien mejor lo audita, y por qué Slither no sustituye a otra persona? | 10 |
| 5 | ¿Qué es una asimetría entre funciones y por qué es buen sitio para buscar hallazgos? | 10 |
| 6 | ¿Qué aporta una prueba de concepto frente a describir el fallo, y qué se hace con una sospecha que no se confirma? | 10 |
| 7 | ¿Cómo se asigna la severidad? ¿Por qué H-03 del ejercicio 02 es media y no alta, si deja a todos sin recompensas? | 10 |
| 8 | ¿Qué diferencia hay entre corregido, reconocido y en disputa? ¿Qué escribes en cada caso? | 10 |
| 9 | ¿Qué es la revisión de una corrección y cuáles son las tres formas típicas de que una corrección falle? | 10 |
| 10 | ¿Por qué una corrección grave se publica después de pausar, y qué es la divulgación responsable? | 10 |

**Total**: 100 puntos → 30 % de la nota.

<details>
<summary>Respuestas</summary>

1. Porque el código está bien: lo malo es un valor con el que se desplegó o un rol que se quedó
   donde no debía, y los tests prueban el código con su propio despliegue. Nomad (2022) inicializó
   su raíz de confianza a cero y cualquier mensaje pasó a ser válido; Parity (2017) dejó su
   biblioteca sin inicializar y alguien se hizo dueño y la destruyó.
2. ¿Quién manda? ¿Manda alguien más? ¿Está todo conectado? `hasRole` solo responde por la cuenta que
   preguntas: la que olvidaste no la preguntas. Hay que contar los miembros
   (`AccessControlEnumerable`) o reconstruir la lista con los eventos `RoleGranted` y `RoleRevoked`.
3. `run()` comprueba en la simulación de `forge script`. Entre la simulación y los bloques reales
   puede entrar otra transacción antes (un `initialize` ajeno), fallar una tuya, o puedes estar en
   otra red. Contra la red, sin `--broadcast`, compruebas lo que de verdad quedó.
4. Conoce las intenciones y lee lo que quiso escribir, no lo que escribió; sus tests prueban lo que
   pensó. Slither encuentra patrones; los fallos de lógica (quién llama, en qué orden se actualiza,
   cuándo se redondea) no tienen patrón: en el pool del ejercicio 02 da `0 result(s) found`.
5. Dos funciones que cambian lo mismo y se protegen distinto (`withdraw` llama a `_update`, `stake`
   no). Suele significar que la autora corrigió una y olvidó la otra.
6. Convierte una opinión en un número que la autora reproduce sin discutir si el fallo existe, y
   después, invertida, es su test de regresión. Una sospecha no confirmada se cierra con un test que
   demuestra que no pasa: no va al informe y protege si un cambio futuro la hace posible.
7. Impacto por probabilidad. H-03 tiene impacto medio (se pierden recompensas, no el depósito) y no
   da beneficio al atacante, que paga gas en cada bloque durante horas: probabilidad media.
8. Corregido: el ataque ya no funciona; se escribe la corrección, el test de regresión y dónde está
   desplegada. Reconocido: el fallo existe y no se corrige; se escribe por qué y pasa a riesgo
   aceptado. En disputa: no estás de acuerdo con el fallo o su severidad; se escriben los
   argumentos, idealmente con un test, hasta acordar.
9. Leer el diff preguntando qué hace ahora el código tocado. Una corrección falla por incompleta
   (solo el camino del PoC), por nueva (introduce otro fallo) o por incompatible (storage, eventos
   o firmas que otros leen).
10. La propuesta de la DAO publica el diff, y durante el plazo del timelock cualquiera puede atacar
    con él: primero el guardián pausa, después se corrige. Divulgación responsable es contar el fallo
    primero a los autores, en privado, y publicarlo cuando está corregido.

</details>

---

## 💪 Desempeño (40 %)

| Ejercicio | Criterio | Puntos |
| --------- | -------- | ------ |
| 01 — Un despliegue que se comprueba | `forge test` sin error: `15 tests passed, 0 failed` | 15 |
| | Explica por qué el despliegue a medias de la teoría 01 da `ONCHAIN EXECUTION COMPLETE & SUCCESSFUL` y `NotAdmin` a la vez | 10 |
| 02 — Auditar código ajeno | `forge test` sin error: `6 tests passed, 0 failed` | 15 |
| | Escribe los tres hallazgos con el formato de la teoría 02 y justifica cada severidad | 15 |
| 03 — Corregir y revisar | `forge test` sin error: `7 tests passed, 0 failed` | 15 |
| | Explica por qué los PoC del ejercicio 02 no encontraron el fallo del paso 4 | 10 |
| Todos | Sin tocar `foundry.toml`, los tests ni, en el ejercicio 02, `RewardPool.sol` | 20 |

**Total**: 100 puntos → 40 % de la nota.

---

## 📦 Producto (30 %)

| Criterio | Puntos |
| -------- | ------ |
| Carpeta `week-34/` sin `out/`, `cache/`, `crytic-export/` ni `.env`, pull request `week-34` → `main` fusionado y etiqueta `v1.0.0` | 10 |
| `bash test.sh` sin error: informe y auditoría cruzada, 95 tests o más, specs, Slither, Medusa y los cuarenta y tres mutantes muertos | 20 |
| `audit/auditoria-cruzada.md`: alcance con repositorio y commit, cada hallazgo con severidad justificada y una PoC que la pareja pudo ejecutar | 25 |
| Cada hallazgo recibido respondido en `audit/README.md`, con su test de regresión si está corregido; T-30, T-31 y la sección `## La entrega (semana 34)` | 25 |
| `README.md` de la raíz con qué es, arquitectura, cómo probarlo, despliegues, seguridad y limitaciones, y la demo de diez minutos | 20 |

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
| [← Proyecto — La entrega final](3-proyecto/README.md) | **Rúbrica de evaluación** | [Ebooks gratuitos →](4-recursos/ebooks-free/README.md) |
