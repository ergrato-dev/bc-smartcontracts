# Rúbrica de evaluación — Semana 10: Llamadas entre contratos

## 📊 Distribución de evidencias

| Tipo | Peso | Instrumento |
| ---- | ---- | ----------- |
| Conocimiento 🧠 | 30 % | Cuestionario de autoevaluación (10 preguntas) |
| Desempeño 💪 | 40 % | Ejercicios 01, 02 y 03 |
| Producto 📦 | 30 % | Proyecto: registro conectado en tu repositorio |

**Nota mínima para aprobar**: 70 % en **cada** tipo de evidencia, no en el promedio.

---

## 🧠 Conocimiento (30 %)

Responde por escrito, sin mirar la teoría. Las respuestas están al final, plegadas.

| # | Pregunta | Puntos |
| - | -------- | ------ |
| 1 | En el calldata de `buy(7, "hola")`, ¿qué hay en la segunda palabra y por qué no está ahí el texto? | 10 |
| 2 | ¿Por qué `abi.encodeCall` es mejor que `abi.encodeWithSignature`? Pon un error que uno detecta y el otro no. | 10 |
| 3 | ¿Por qué `keccak256(abi.encodePacked(a, b))` con dos `string` es peligroso para un permiso? | 10 |
| 4 | Una llamada de bajo nivel a una dirección devuelve `ok = true` y `data = 0x`. ¿Qué puede haber pasado? ¿Cómo lo evitas? | 10 |
| 5 | ¿Qué recibe un destino que gasta todo el gas, y cuánto le queda a quien llama? ¿Cómo lo limitas? | 10 |
| 6 | Con `delegatecall`, ¿de quién es el storage, `msg.sender` y `msg.value`? ¿Qué pasa si los storages no coinciden? | 10 |
| 7 | ¿Por qué un `multicall` con `delegatecall` no puede ser `payable`? | 10 |
| 8 | Nombra tres fallos que `try`/`catch` no atrapa. | 10 |
| 9 | ¿De qué depende la dirección de `CREATE` y de qué la de `CREATE2`? ¿Por qué cambia si cambia el dueño del constructor? | 10 |
| 10 | En una fábrica pública con `CREATE2`, ¿qué ataque permite un salt que elige el usuario tal cual, y cómo lo evitas? | 10 |

**Total**: 100 puntos → 30 % de la nota.

<details>
<summary>Respuestas</summary>

1. El offset `0x40`: a cuántos bytes del inicio de los argumentos empieza el `string`. Un
   tipo dinámico no tiene tamaño fijo, así que en la cabeza va solo dónde buscarlo; en la
   cola van su longitud (4) y sus bytes, rellenos a 32.
2. `encodeCall` comprueba en compilación que los argumentos encajan con la función.
   `encodeWithSignature` calcula el selector del texto tal cual: `"buy(uint,string)"` compila
   y da `0xd378caeb` en vez de `0xb7dc3b18`, y la llamada falla en ejecución.
3. `encodePacked` pega los bytes sin longitudes: `("ab", "c")` y `("a", "bc")` dan los mismos
   bytes y el mismo hash. Dos entradas distintas valdrían lo mismo. Se usa `abi.encode`.
4. Que la dirección no tiene código: la EVM no ejecuta nada y responde éxito. Si enviaste
   ETH, se quedó allí. Se comprueba `destino.code.length > 0` o se llama por interfaz.
5. Recibe como mucho 63/64 del gas que queda (EIP-150); quien llama se queda con 1/64, que a
   veces no basta para terminar. Con `{gas: n}` en la llamada o en el `try`.
6. El storage, `msg.sender` y `msg.value` son los de quien llama; solo el código es del
   destino. Si las variables no están en los mismos slots, el código escribe donde no debe:
   en la teoría, el dueño pasó a ser otra dirección sin que nada revirtiera.
7. Porque cada `delegatecall` ve el mismo `msg.value`: con dos `deposit()` y 1 ether pagado,
   se apuntan 2. Sin `payable`, cualquier llamada con ETH revierte.
8. Una llamada a una cuenta sin código; un retorno que no se puede decodificar con el tipo
   de `returns`; y un revert dentro de las llaves del `try` o del `catch`. Los tres ocurren en
   tu contrato, no en el destino.
9. `CREATE`: de quien despliega y su nonce. `CREATE2`: de quien despliega, el salt y el
   hash del código de creación, que incluye los argumentos del constructor. Otro dueño es
   otro código de creación, y por tanto otra dirección.
10. Front-running: otro ve tu transacción pendiente, despliega antes con tu salt y ocupa la
    dirección (tu transacción falla). Se mezcla a quien llama en el salt,
    `keccak256(abi.encode(msg.sender, salt))`, y cada cuenta solo ocupa las suyas.

</details>

---

## 💪 Desempeño (40 %)

| Ejercicio | Criterio | Puntos |
| --------- | -------- | ------ |
| 01 — ABI y llamadas | `forge test --deny warnings`: 6 de 6 | 15 |
| | Lee el error dentro de `CallFailed` en una traza y explica la comprobación del paso 5 | 15 |
| 02 — delegatecall y try/catch | `forge test --deny warnings`: 8 de 8 | 15 |
| | Explica por qué `addListener` comprueba el código, el gas del `GasBurner` en la traza y por qué `multicall` no es `payable` | 15 |
| 03 — CREATE y CREATE2 | `forge test --deny warnings`: 7 de 7 | 20 |
| | Explica la fórmula de `predict`, qué evita `saltOf` y el ETH enviado antes del despliegue en anvil | 20 |

**Total**: 100 puntos → 40 % de la nota.

---

## 📦 Producto (30 %)

| Criterio | Puntos |
| -------- | ------ |
| Carpeta `week-10/` en tu repositorio, sin `out/` ni `cache/`, con tus pruebas de la semana 09, y pull request `week-10` → `main` | 10 |
| `forge test --deny warnings`: 68 tests en verde y el de fork saltado | 30 |
| Avisos al final: `register` después de `_register`, `registerBatch` en un segundo bucle; `multicall` sin `payable` | 20 |
| Desplegado en anvil con los puntos como hook, puntos sumados y test de fork en verde | 15 |
| `.gas-snapshot` regenerado y `forge snapshot --fuzz-seed 1 --check` en verde; la diferencia de gas explicada en el pull request | 10 |
| Calidad: cada `forge-lint` con su porqué, sin `TODO` restantes, nombres de tu dominio | 15 |

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
| [← Proyecto — Registro conectado](3-proyecto/README.md) | **Rúbrica de evaluación** | [Ebooks gratuitos →](4-recursos/ebooks-free/README.md) |
