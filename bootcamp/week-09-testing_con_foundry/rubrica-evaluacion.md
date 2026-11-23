# Rúbrica de evaluación — Semana 09: Testing con Foundry

## 📊 Distribución de evidencias

| Tipo | Peso | Instrumento |
| ---- | ---- | ----------- |
| Conocimiento 🧠 | 30 % | Cuestionario de autoevaluación (10 preguntas) |
| Desempeño 💪 | 40 % | Ejercicios 01, 02 y 03 |
| Producto 📦 | 30 % | Proyecto: registro a prueba de fuzzing en tu repositorio |

**Nota mínima para aprobar**: 70 % en **cada** tipo de evidencia, no en el promedio.

---

## 🧠 Conocimiento (30 %)

Responde por escrito, sin mirar la teoría. Las respuestas están al final, plegadas.

| # | Pregunta | Puntos |
| - | -------- | ------ |
| 1 | ¿Qué es `vm` y por qué un cheatcode no sirve como prueba de lo que puede pasar en una red real? | 10 |
| 2 | Un test hace `vm.prank(alice)`, lee `vault.balanceOf(alice)` y después llama a `vault.withdraw()`. ¿Quién llama a `withdraw` y por qué? | 10 |
| 3 | ¿Por qué un test de "no antes de 7 días" debe probar `unlockAt - 1` y `unlockAt`, y no "un mes después"? | 10 |
| 4 | ¿Qué riesgo tiene `vm.expectRevert()` sin argumentos? ¿Qué escribes en su lugar? | 10 |
| 5 | ¿Por qué `vm.expectEmit` y `vm.expectRevert` van antes de la llamada y no después? | 10 |
| 6 | ¿Qué diferencia hay entre un test de ejemplo y una propiedad? Pon una propiedad de un registro con tasa. | 10 |
| 7 | ¿Cuándo usas `bound`, cuándo `vm.assume` y cuándo el tipo del parámetro? ¿Qué pasa si `vm.assume` descarta casi todo? | 10 |
| 8 | Un fuzz test pasa 256 veces. ¿Qué demuestra y qué no? | 10 |
| 9 | ¿Qué lee un fork del nodo, dónde escribe y por qué conviene fijar el bloque? | 10 |
| 10 | Tu contrato tiene 100 % de cobertura en todo. ¿Por qué aún puede tener fallos? Da un ejemplo del proyecto. | 10 |

**Total**: 100 puntos → 30 % de la nota.

<details>
<summary>Respuestas</summary>

1. Es el contrato de cheatcodes que forge ofrece solo en los tests, en
   `0x7109709ECfa91a80626fF3989D68f67F5b1DD12D`. Cambia reglas que en una red nadie puede
   cambiar: llamar como otra cuenta sin su clave, darse ETH, mover el reloj. Un test que solo
   pasa gracias a eso prueba algo que en la red no puede ocurrir.
2. El contrato de test. `vm.prank` vale para la siguiente llamada, y la siguiente fue la
   lectura de `balanceOf`, que lo gastó. Hay que leer antes del prank o usar `startPrank`.
3. Porque el fallo típico está en el borde: `<` en vez de `<=`, un segundo de más o de menos.
   "Un mes después" pasa con las dos versiones; `unlockAt - 1` (revierte) y `unlockAt`
   (funciona) solo pasan con la correcta.
4. Pasa con cualquier revert, también con uno que no esperabas (otro error que salta antes,
   falta de saldo). El test queda en verde sin probar la regla de su nombre. Se escribe el
   error concreto: `vm.expectRevert(abi.encodeWithSelector(E.selector, args))`.
5. Son expectativas sobre la siguiente llamada: forge las registra y las comprueba mientras
   esa llamada se ejecuta. Escritas después ya no queda llamada que las cumpla y el test
   falla (`expected an emit, but no logs were emitted afterwards`).
6. Un ejemplo prueba un caso elegido ("con 0,01 ether funciona"). Una propiedad vale para
   cualquier entrada válida y el fuzzer la prueba con muchas. Por ejemplo: "cualquier cuota
   distinta de la tasa revierte con `WrongFee(fee, sent)`", o "tras retirar, `to` recibe
   exactamente lo cobrado".
7. `bound` para llevar un número a un rango, sin perder entradas. `vm.assume` para excluir
   pocos valores concretos (`a != b`, `to != address(0)`). El tipo (`uint16`, `uint128`)
   limita el rango gratis. Si `vm.assume` descarta casi todo, el fuzzer se rinde con
   `` `vm.assume` rejected too many inputs (65536 allowed) ``.
8. Que con esas 256 entradas no encontró fallo. No demuestra que no lo haya: el espacio de
   entradas es enorme, y un fuzz test de una llamada no prueba secuencias de llamadas.
9. La primera vez que el test toca una cuenta o un slot, lo pide al nodo por JSON-RPC en el
   bloque elegido; después todo es local y las escrituras quedan en la copia. Sin bloque
   fijo copia el último, que en una red viva cambia, y el test deja de ser repetible.
10. La cobertura dice qué se ejecutó, no qué se comprobó, ni con qué valores. En el proyecto,
    guardar `block.number` en vez de `block.timestamp` pasa los 44 tests con 100 % de
    cobertura, porque en el test los dos valen 1; solo la propiedad con `vm.warp` lo ve.

</details>

---

## 💪 Desempeño (40 %)

| Ejercicio | Criterio | Puntos |
| --------- | -------- | ------ |
| 01 — Cheatcodes | `forge test`: 5 de 5 sin warnings | 15 |
| | Explica `prank`/`startPrank`/`hoax`, el borde del paso 3 y cómo viaja un `indexed` en un log | 15 |
| 02 — Fuzz testing | `forge test`: 4 de 4 sin warnings | 15 |
| | Explica el overflow del paso 1 y por qué acotar el importe es una decisión del sistema, y qué protege cada `assume` del paso 5 | 15 |
| 03 — Forks, gas y cobertura | `forge test`: sin warnings, 6 de 6 con `FORK_URL` y 4 más 1 saltado sin ella | 20 |
| | Explica la rama sin cubrir de `TipJar`, la diferencia de gas entre las dos propinas y por qué anvil no cambió | 20 |

**Total**: 100 puntos → 40 % de la nota.

---

## 📦 Producto (30 %)

| Criterio | Puntos |
| -------- | ------ |
| Carpeta `week-09/` en tu repositorio, sin `out/` ni `cache/`, con `.gas-snapshot`, y pull request `week-09` → `main` | 10 |
| `forge test`: 51 tests en verde y el de fork saltado, sin warnings, en varias ejecuciones seguidas | 30 |
| Los dos mutantes detectados por tus propiedades, con la salida en el pull request | 20 |
| Test de fork en verde contra tu despliegue en anvil, y `count` de anvil sin cambiar | 15 |
| `forge snapshot --fuzz-seed 1 --check` en verde | 10 |
| Calidad: propiedades que no repiten la fórmula del contrato, rangos justificados, cada `vm.assume` comentado, sin `TODO` restantes | 15 |

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
| [← Proyecto — Registro a prueba de fuzzing](3-proyecto/README.md) | **Rúbrica de evaluación** | [Ebooks gratuitos →](4-recursos/ebooks-free/README.md) |
