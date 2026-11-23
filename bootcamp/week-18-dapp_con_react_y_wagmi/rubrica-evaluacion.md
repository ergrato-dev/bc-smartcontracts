# Rúbrica de evaluación — Semana 18: dApp con React y wagmi

## 📊 Distribución de evidencias

| Tipo | Peso | Instrumento |
| ---- | ---- | ----------- |
| Conocimiento 🧠 | 30 % | Cuestionario de autoevaluación (10 preguntas) |
| Desempeño 💪 | 40 % | Ejercicios 01, 02 y 03 |
| Producto 📦 | 30 % | Proyecto: la dApp del protocolo |

**Nota mínima para aprobar**: 70 % en **cada** tipo de evidencia, no en el promedio.

---

## 🧠 Conocimiento (30 %)

Responde por escrito, sin mirar la teoría. Las respuestas están al final, plegadas.

| # | Pregunta | Puntos |
| - | -------- | ------ |
| 1 | ¿Qué problema de la página de la semana 17 resuelve React? ¿Qué escribes tú y qué hace React? | 10 |
| 2 | Tres clics seguidos con `setVeces(veces + 1)` dejan el contador en 1. ¿Por qué, y cómo se arregla? | 10 |
| 3 | ¿Qué diferencia hay entre una acción de `@wagmi/core` y un hook de `wagmi`? ¿Cuándo usas cada una? | 10 |
| 4 | ¿Qué es la clave de consulta (*queryKey*) y por qué el saldo sigue viejo después de una transferencia si no haces nada? | 10 |
| 5 | ¿Para qué sirve `enabled` en una lectura, y por qué no basta con un `if`? | 10 |
| 6 | ¿Por qué la página de la semana 17 no podía escribir en Sepolia y esta sí? ¿Dónde está la clave? | 10 |
| 7 | ¿Qué son `window.ethereum` (EIP-1193) y EIP-6963? | 10 |
| 8 | La wallet está en mainnet y la página es de anvil. ¿Cómo lo sabe la página, qué hace, y qué pasaría al escribir sin `chainId` en la simulación? | 10 |
| 9 | Nombra los tres caminos por los que una transacción acaba "fallida". ¿En cuáles se paga gas? | 10 |
| 10 | ¿Por qué se simula antes de `mutate`, y por qué el botón se desactiva mientras firma o confirma? | 10 |

**Total**: 100 puntos → 30 % de la nota.

<details>
<summary>Respuestas</summary>

1. Saber qué partes de la pantalla refrescar después de cada cambio. Con React describes cómo se
   ve la pantalla para un estado dado; cuando el estado cambia, React vuelve a ejecutar los
   componentes y aplica al DOM solo la diferencia.
2. `setVeces` no cambia `veces` en el render actual: pide otro render. Si los tres clics llegan
   antes de que React vuelva a pintar, los tres calculan `0 + 1`. Con `setVeces((v) => v + 1)`,
   cada cambio parte del anterior.
3. La acción es una función que recibe la configuración y funciona sin React (Node, tests, un
   `onClick` con `useConfig()`). El hook la llama por dentro, guarda el resultado en la caché y
   vuelve a pintar el componente. Hooks en componentes; acciones fuera de ellos.
4. Identifica una lectura (acción, contrato, función, argumentos, red); lo que se lee se guarda
   bajo ella. Después de escribir, la caché no sabe que el contrato cambió: hay que invalidar
   las consultas cuando llega el recibo para que se repitan.
5. Deja la lectura en espera mientras falta un dato (la cuenta, la dirección del token). Un hook
   no puede ir dentro de un `if`: React reconoce los hooks por su orden y cambiarlo entre renders
   es un error.
6. Firmaba con una cuenta desbloqueada de anvil; en Sepolia ningún nodo guarda tu clave. Ahora
   firma la wallet de la persona: la clave se queda en la wallet, y la página solo pide.
7. `window.ethereum` es el proveedor que la wallet pone en la página: `request({ method,
   params })` con métodos JSON-RPC y de wallet, y eventos `accountsChanged` y `chainChanged`.
   EIP-6963 permite que varias wallets se anuncien a la vez, cada una con su nombre e icono.
8. `useConnection().chainId` es la red de la wallet; se compara con la de la configuración. La
   página no ofrece escribir y propone `switchChain`. Sin `chainId` en la simulación, wagmi no
   compara: la transacción saldría hacia mainnet con la dirección y los datos de anvil.
9. Revierte la simulación (sin gas, no se abre la wallet), la persona rechaza en la wallet (sin
   gas) y revierte el bloque porque otra transacción cambió el estado antes (el gas se pagó).
10. La simulación da el error con nombre, decodificado con la ABI, y evita enseñar en la wallet
    una transacción que va a fallar; sin ella, el revert llega como `custom error 0x…`. El botón
    se desactiva porque cada clic sería otra transacción, otra tasa y otra alta.

</details>

---

## 💪 Desempeño (40 %)

| Ejercicio | Criterio | Puntos |
| --------- | -------- | ------ |
| 01 — Conectar la cuenta | `bash test.sh`: 5 de 5 y sin errores de tipos | 15 |
| | Explica por qué la red de anvil lleva el `rpcUrl` del test en `rpcUrls` | 5 |
| 02 — Leer y escribir | `bash test.sh`: 5 de 5 y sin errores de tipos | 20 |
| | Explica de dónde sale la cuenta y qué añade `chainId` a la simulación | 10 |
| 03 — Hooks de React | `bash test.sh`: 6 de 6 y sin errores de tipos | 20 |
| | Explica qué falla al quitar la simulación y al quitar `invalidateQueries` | 15 |
| Todos | Sin tocar `test/` ni `test.sh` | 15 |

**Total**: 100 puntos → 40 % de la nota.

---

## 📦 Producto (30 %)

| Criterio | Puntos |
| -------- | ------ |
| Carpeta `week-18/` sin `.env.local`, `node_modules/` ni `dist/`, y pull request `week-18` → `main` | 10 |
| `bash test.sh`: 9 de 9 tests y `tsc` y `vite build` sin errores | 30 |
| `hooks.ts` completo: simula con `chainId` antes de cada escritura, invalida la caché al confirmar y espera a la wallet con `enabled` | 15 |
| En anvil: conectar, alta, rechazo, error con nombre, baja, aviso de otra red, actividad en vivo y `TooManyItems` tras actualizar a V2 | 20 |
| En Sepolia: un alta confirmada con la wallet | 10 |
| Textos de tu dominio, botones desactivados mientras hay una transacción en curso y nada de `dangerouslySetInnerHTML` | 15 |

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
| [← Proyecto — La dApp del protocolo](3-proyecto/README.md) | **Rúbrica de evaluación** | [Ebooks gratuitos →](4-recursos/ebooks-free/README.md) |
