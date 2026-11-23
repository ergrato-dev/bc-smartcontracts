# Rúbrica de evaluación — Semana 16: Despliegue y verificación

## 📊 Distribución de evidencias

| Tipo | Peso | Instrumento |
| ---- | ---- | ----------- |
| Conocimiento 🧠 | 30 % | Cuestionario de autoevaluación (10 preguntas) |
| Desempeño 💪 | 40 % | Ejercicios 01, 02 y 03 |
| Producto 📦 | 30 % | Proyecto: protocolo desplegado y verificado en Sepolia |

**Nota mínima para aprobar**: 70 % en **cada** tipo de evidencia, no en el promedio.

---

## 🧠 Conocimiento (30 %)

Responde por escrito, sin mirar la teoría. Las respuestas están al final, plegadas.

| # | Pregunta | Puntos |
| - | -------- | ------ |
| 1 | En un script, ¿qué se convierte en transacciones y qué no? ¿Qué pasa con una comprobación escrita después de `vm.stopBroadcast()`? | 10 |
| 2 | ¿Qué hace `forge script` sin `--rpc-url`, con `--rpc-url` y con `--broadcast`? ¿Cuándo se envía algo? | 10 |
| 3 | ¿Por qué el script toma a quien firma con `vm.readCallers()` y no con `msg.sender`? | 10 |
| 4 | ¿Por qué no se firma con `--private-key` ni con `PRIVATE_KEY` en un `.env` fuera de anvil? Da dos sitios por los que se escapa una clave | 10 |
| 5 | ¿Qué guarda un keystore, y para qué sirven `scrypt` y el campo `mac`? | 10 |
| 6 | ¿Por qué la estimación de gas que vale es la de Sepolia y no la de anvil? | 10 |
| 7 | ¿Qué archivo de `broadcast/` se versiona y cuál no, y por qué `cache/` nunca se sube? | 10 |
| 8 | ¿Qué demuestra que un contrato esté verificado, y qué no demuestra? | 10 |
| 9 | ¿Por qué el código de la cadena no es igual al que da `forge inspect ... deployedBytecode`, y dónde están los argumentos del constructor? | 10 |
| 10 | ¿Por qué no verificaba el JSON con las bibliotecas en `/opt/lib`, y cómo lo arregla `lib`? | 10 |

**Total**: 100 puntos → 30 % de la nota.

<details>
<summary>Respuestas</summary>

1. Solo las llamadas a otros contratos y los `new` entre `vm.startBroadcast()` y
   `vm.stopBroadcast()`. Lo demás (leer el entorno, calcular, comprobar) se ejecuta en la
   simulación y no llega a la red. Una comprobación tras `stopBroadcast` sí se ejecuta, pero si
   falla las transacciones ya están emitidas: lo que puede fallar va antes de `startBroadcast`.
2. Sin `--rpc-url`, ejecuta `run()` en una EVM vacía en memoria. Con `--rpc-url`, además simula
   las transacciones sobre el estado real de la red y pide al nodo la estimación de gas. Solo con
   `--broadcast` y una cuenta firma y envía. Si algo revierte en la simulación, no se envía nada.
3. Porque en un test el `msg.sender` de `deploy` es el contrato de test, mientras que lo emitido
   lo firma `DEFAULT_SENDER`. El dueño o el administrador sería un contrato que no puede firmar.
   `vm.readCallers()` da el `msg.sender` de lo que se emite: quien firma, en un script y en un
   test.
4. Porque quien tiene la clave controla la cuenta, y con ella el registro que administra. Se
   escapa por el historial de la shell, la lista de procesos, los logs de CI y un `.env` que
   acaba en un commit.
5. La clave privada cifrada con AES-128-CTR, la sal y los parámetros de `scrypt`, el `iv` y un
   `mac`. `scrypt` convierte la contraseña en la clave de cifrado, lento a propósito para que
   probar contraseñas sea caro. El `mac` detecta una contraseña equivocada (`Mac Mismatch`) sin
   descifrar nada.
6. Porque las reglas de gas de una red pública cambian con cada actualización de la red y anvil
   simula las de su versión. En Sepolia, crear contratos cuesta ya varias veces más gas que en
   anvil: el despliegue del proyecto estimaba 12,5 millones en anvil y 87 millones en Sepolia.
7. Se versiona el `run-latest.json` de Sepolia (`11155111`): es el registro de las direcciones
   desplegadas. No se versionan los de anvil (`31337`) ni las simulaciones (`dry-run`). `cache/`
   guarda la URL RPC de cada ejecución, que puede llevar una clave de API.
8. Que el código publicado compila, con esos ajustes, exactamente al bytecode de la dirección.
   No demuestra que ese código sea correcto ni honesto: puede tener fallos o puertas traseras.
9. Porque el constructor escribe los immutables dentro del código (`OWNER` en las posiciones 157
   y 198), donde el compilador deja ceros. Los argumentos del constructor no están en el código
   desplegado: van al final de la transacción de creación, codificados en ABI.
10. Porque forge nombraba esos archivos `../opt/lib/…` en el JSON, pero los remappings seguían
    apuntando a `/opt/lib/…`: el JSON no contenía los archivos que importaba y no recompilaba.
    Con `lib`, un enlace a `/opt/lib` dentro del proyecto, las rutas son `lib/…` en los dos
    sitios y el JSON se basta a sí mismo.

</details>

---

## 💪 Desempeño (40 %)

| Ejercicio | Criterio | Puntos |
| --------- | -------- | ------ |
| 01 — Primer script | `forge test --deny warnings`: 6 de 6 | 20 |
| | En anvil, simula sin `--broadcast` (nonce sin cambiar), emite con `INITIAL_VALUE=7` y ve el script fallar con `INITIAL_VALUE=0` | 10 |
| 02 — Keystore y broadcast | `bash test.sh`: 6 de 6 pasos | 25 |
| | Explica qué hay en el keystore y por qué `Mac Mismatch` no descifra nada | 10 |
| 03 — Verificación por dentro | `bash test.sh`: 7 de 7 pasos | 25 |
| | Explica las tres diferencias entre la cadena y el compilador: immutables, metadatos y argumentos del constructor | 10 |

**Total**: 100 puntos → 40 % de la nota.

---

## 📦 Producto (30 %)

| Criterio | Puntos |
| -------- | ------ |
| Carpeta `week-16/` en tu repositorio, con `lib`, sin `out/`, `cache/` ni `.env`, y pull request `week-16` → `main` | 10 |
| `forge test --deny warnings`: 152 tests en verde y el de fork saltado; `.gas-snapshot` regenerado y `--check` en verde | 25 |
| `DeployProtocol` y `UpgradeToV2` completos, con quien firma tomado de `vm.readCallers()` | 15 |
| Ensayo en anvil con un keystore: despliegue, alta, test de fork y actualización (la segunda falla en la simulación) | 10 |
| En Sepolia, firmado con `sepolia-dev`: desplegado, una alta real, test de fork en verde y actualizado a V2 | 25 |
| Los cinco contratos (los cuatro del despliegue y la implementación V2) en `exact_match` en Sourcify, y los `run-latest.json` de Sepolia en el commit | 15 |

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
| [← Proyecto — Despliegue en Sepolia](3-proyecto/README.md) | **Rúbrica de evaluación** | [Ebooks gratuitos →](4-recursos/ebooks-free/README.md) |
