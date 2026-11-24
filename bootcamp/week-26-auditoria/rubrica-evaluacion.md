# Rúbrica de evaluación — Semana 26: Auditoría

## 📊 Distribución de evidencias

| Tipo | Peso | Instrumento |
| ---- | ---- | ----------- |
| Conocimiento 🧠 | 30 % | Cuestionario de autoevaluación (10 preguntas) |
| Desempeño 💪 | 40 % | Ejercicios 01, 02 y 03 |
| Producto 📦 | 30 % | Proyecto: informe de auditoría final |

**Nota mínima para aprobar**: 70 % en **cada** tipo de evidencia, no en el promedio.

---

## 🧠 Conocimiento (30 %)

Responde por escrito, sin mirar la teoría. Las respuestas están al final, plegadas.

| # | Pregunta | Puntos |
| - | -------- | ------ |
| 1 | ¿Por qué una auditoría se hace sobre un commit fijo, y qué pasa con un cambio de una línea hecho después? | 10 |
| 2 | ¿Por qué la revisión manual empieza por la superficie de ataque, y cómo la sacas de un contrato compilado? | 10 |
| 3 | Slither no avisó de nada en una función. ¿Quiere decir que no tiene fallos? Usa H-01 del ejercicio 02. | 10 |
| 4 | ¿Qué encontró el modelo de amenazas del ejercicio 01 que una lectura de `resolve` línea a línea podía pasar por alto? | 10 |
| 5 | ¿Qué diferencia hay entre un hallazgo y un riesgo aceptado? Da un ejemplo de cada uno en el `Escrow`. | 10 |
| 6 | ¿Por qué H-03 del ejercicio 02 es media y no crítica, si el impacto es el mismo que el de H-02? | 10 |
| 7 | ¿Qué tiene que pasarle a una PoC cuando el equipo corrige el fallo, y por qué eso sirve en la revisión de correcciones? | 10 |
| 8 | En el nivel 2 del CTF, `withdraw` tiene `nonReentrant`. ¿Por qué se vacía igual el banco, y qué lo habría evitado? | 10 |
| 9 | Encuentras un fallo que permite vaciar un contrato desplegado en mainnet. ¿Qué haces y qué no haces? | 10 |
| 10 | ¿Por qué una sola cuenta con `DEFAULT_ADMIN_ROLE` es un hallazgo si el código hace exactamente lo que dice? | 10 |

**Total**: 100 puntos → 30 % de la nota.

<details>
<summary>Respuestas</summary>

1. Porque el informe habla de un código concreto: si cambia a mitad, describe algo que ya no
   existe. Un cambio posterior, aunque sea de una línea, no está auditado; entra en la revisión de
   correcciones o en otra auditoría.
2. Porque las funciones `external` y `public` que cambian estado son las únicas puertas por las que
   entra alguien de fuera: si revisas todas, no se te escapa ninguna. `forge inspect <Contrato>
   methodIdentifiers` las lista con su selector; los getters solo leen.
3. No. Los detectores buscan patrones de código. H-01 es un fallo de lógica del protocolo: `claim`
   compara la meta con el saldo de todo el contrato en vez de con lo recaudado por la campaña.
   Ningún patrón dice que eso está mal; solo lo sabe quien sabe qué debe hacer `claim`.
4. Que el árbitro, de confianza para decidir, puede enviar el ETH a cualquier dirección. Leyendo
   `resolve` se ve que comprueba quién llama y el estado, y parece completo; al cruzar el actor
   "árbitro" con el activo "ETH" aparece la pregunta de a quién puede enviarlo.
5. Un hallazgo es algo que no debería poder pasar y pasa. Un riesgo aceptado es algo que el diseño
   confía a propósito a un actor y se declara. En el `Escrow`: que el árbitro envíe el ETH a un
   tercero es un hallazgo; que decida mal entre Alice y Bob es un riesgo aceptado, y que Bob tenga
   que disputar dentro del plazo si Alice no libera, también.
6. Porque la severidad es impacto por probabilidad. Los dos bloquean fondos (impacto alto), pero
   H-02 lo hace cualquiera con 1 wei cuando quiera, y H-03 solo pasa en el segundo exacto del
   plazo y con las dos transacciones en ese orden: probabilidad baja, severidad media.
7. Tiene que dejar de pasar: una PoC pasa porque el fallo existe. Si tras la corrección sigue
   pasando, el fallo sigue ahí. Y el equipo debe añadir un test del comportamiento correcto, que se
   queda como test de regresión.
8. El cerrojo solo protege `withdraw`, y `withdraw` envía antes de poner el saldo a cero. Durante
   el `receive`, el saldo sigue entero y `transfer`, sin cerrojo, lo pasa a otro contrato del
   atacante. Lo habría evitado checks-effects-interactions: saldo a cero antes de enviar. Protege
   el estado, y con él a cualquier otra función, también a las que se añadan después.
9. No lo explotas, ni para demostrarlo, ni lo publicas ni se lo cuentas a nadie más. Buscas el
   canal de seguridad del protocolo (`SECURITY.md`, su bug bounty en Immunefi), envías un informe
   privado con una PoC que corre contra un fork local, das tiempo a corregir y no pides dinero a
   cambio de no publicar.
10. Porque el riesgo no está en el código sino en la clave: si se filtra, o su dueño actúa de mala
    fe, actualiza el proxy a cualquier implementación en una transacción, sin que los usuarios
    puedan salir antes. Impacto crítico, probabilidad baja: un hallazgo de centralización. Se
    defiende con un timelock y un multisig.

</details>

---

## 💪 Desempeño (40 %)

| Ejercicio | Criterio | Puntos |
| --------- | -------- | ------ |
| 01 — Modelo de amenazas | `forge test` sin error: `5 passed; 0 failed` | 15 |
| | Explica por qué el test del paso 4 fallaba con `next call did not revert as expected` y qué hallazgo era | 10 |
| 02 — Hallazgos con PoC | `forge test` sin error: `5 passed; 0 failed`, sin tocar `src/Crowdfund.sol` | 15 |
| | `FINDINGS.md` con los cuatro hallazgos, sus severidades justificadas y el falso positivo de Slither | 20 |
| 03 — CTF local | `forge test` sin error: `4 passed; 0 failed` | 15 |
| | Explica cada nivel como un hallazgo: qué fallo, qué impacto y qué corrección | 15 |
| Todos | Sin tocar `foundry.toml` ni los archivos marcados "no lo modifiques" | 10 |

**Total**: 100 puntos → 40 % de la nota.

---

## 📦 Producto (30 %)

| Criterio | Puntos |
| -------- | ------ |
| Carpeta `week-26/` sin `out/`, `cache/` ni `crytic-export/`, y pull request `week-26` → `main` | 10 |
| `bash test.sh` sin error: informe, tests, specs, `forge lint`, Slither, detector, Medusa y los doce mutantes muertos | 25 |
| Los cuatro tests del modelo de amenazas, con la cuenta y el rol exactos en cada revert | 15 |
| Modelo de amenazas: actores con su confianza, activos, fronteras y cada amenaza con su defensa y su prueba | 20 |
| Informe: resumen que se entiende solo, alcance con commit, revisión de correcciones y limitaciones | 20 |
| El riesgo de centralización de tu protocolo, como hallazgo o con la prueba de su defensa | 10 |

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
| [← Proyecto — Informe de auditoría final](3-proyecto/README.md) | **Rúbrica de evaluación** | [Ebooks gratuitos →](4-recursos/ebooks-free/README.md) |
