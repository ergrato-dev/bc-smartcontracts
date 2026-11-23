# Rúbrica de evaluación — Semana 15: Contratos actualizables

## 📊 Distribución de evidencias

| Tipo | Peso | Instrumento |
| ---- | ---- | ----------- |
| Conocimiento 🧠 | 30 % | Cuestionario de autoevaluación (10 preguntas) |
| Desempeño 💪 | 40 % | Ejercicios 01, 02 y 03 |
| Producto 📦 | 30 % | Proyecto: registro actualizable en tu repositorio |

**Nota mínima para aprobar**: 70 % en **cada** tipo de evidencia, no en el promedio.

---

## 🧠 Conocimiento (30 %)

Responde por escrito, sin mirar la teoría. Las respuestas están al final, plegadas.

| # | Pregunta | Puntos |
| - | -------- | ------ |
| 1 | En una llamada `proxy.increment()`, ¿qué código se ejecuta, qué storage cambia y qué `msg.sender` ve ese código? | 10 |
| 2 | ¿Por qué se rompe un proxy que guarda la implementación en su slot 0? | 10 |
| 3 | ¿De dónde sale el slot de la implementación de EIP-1967, y por qué el "menos 1"? | 10 |
| 4 | ¿Qué cambios de variables admite una V2, y qué pasa si declaras una variable nueva antes de las de la V1? | 10 |
| 5 | ¿Por qué el dueño de `OwnableUpgradeable` no ocupa el slot 0 aunque vaya primero en la herencia? | 10 |
| 6 | ¿Por qué el constructor de la implementación no inicializa el proxy, y qué pasa con una variable `immutable`? | 10 |
| 7 | ¿Qué ataque evita `_disableInitializers()` en el constructor, y cuál evita pasar `initialize` al constructor del proxy? | 10 |
| 8 | ¿Qué es el choque de selectores, y cómo lo evitan el proxy transparent y UUPS? | 10 |
| 9 | ¿Qué comprueba `upgradeToAndCall` de UUPS antes de cambiar el slot, y qué pasa con un `_authorizeUpgrade` vacío? | 10 |
| 10 | ¿Por qué el registro del proyecto no puede crear su token y su certificado con `new` en `initialize`? | 10 |

**Total**: 100 puntos → 30 % de la nota.

<details>
<summary>Respuestas</summary>

1. El de la implementación, con `delegatecall`. Cambia el storage del proxy. El código ve como
   `msg.sender` a quien llamó al proxy, y los eventos salen de la dirección del proxy.
2. Porque la implementación también usa el slot 0 para su primera variable: al escribirla,
   pisa la dirección de la implementación. En `NaiveProxy`, `count++` le suma 1 y la siguiente
   llamada va a una dirección sin código (`AddressEmptyCode`).
3. Es `keccak256("eip1967.proxy.implementation") - 1`: un slot que ningún compilador asigna a
   una variable. Con el "menos 1" nadie conoce el texto del que sale el hash, así que ninguna
   clave de mapping cae ahí.
4. Añadir variables al final, funciones, eventos, errores y constantes. No insertar, borrar,
   reordenar ni cambiar el tipo. Con una variable nueva delante, todas las de la V1 se
   desplazan un slot y leen el dato de otra, sin revertir: datos falsos.
5. Porque `OwnableUpgradeable` guarda `_owner` en un struct con espacio de nombres (ERC-7201),
   en un slot calculado a partir de `openzeppelin.storage.Ownable`, lejos de los slots 0, 1,
   2… donde van tus variables.
6. El constructor escribe en el storage de la implementación, y el proxy no lo ejecuta
   nunca. Una `immutable` está en el código de la implementación: el proxy ve el valor que
   fijó la implementación, y cambia con cada implementación.
7. `_disableInitializers()` evita que alguien llame a `initialize` sobre la implementación y se
   haga su dueño (la biblioteca de Parity, la implementación de Wormhole). Pasar `initialize`
   al constructor del proxy evita que alguien se adelante y lo inicialice primero, entre el
   despliegue y la llamada.
8. Si el proxy y la implementación tienen una función con el mismo selector, el proxy gana
   siempre y la de la implementación no se puede llamar. El transparent solo deja al
   administrador llamar a las funciones del proxy y reenvía todo lo de los demás. UUPS deja el
   proxy sin funciones: `upgradeToAndCall` está en la implementación.
9. Que se llama a través de un proxy (`onlyProxy`), tu `_authorizeUpgrade` y que la nueva
   implementación responde `proxiableUUID` con el slot de EIP-1967. Con `_authorizeUpgrade`
   vacío, cualquiera actualiza el contrato a un código suyo.
10. Porque `new` dentro de una función mete el bytecode del contrato creado en el código
    desplegado del registro: pasaría de 24 KiB. Y porque el creador sería quien ejecuta `new`;
    el proyecto los despliega antes, con la dirección del proxy predicha con el nonce.

</details>

---

## 💪 Desempeño (40 %)

| Ejercicio | Criterio | Puntos |
| --------- | -------- | ------ |
| 01 — Proxy a mano | `forge test --deny warnings`: 12 de 12 | 15 |
| | En anvil, lee con `cast storage` el slot 0, el de la implementación y el del administrador, antes y después de actualizar | 15 |
| 02 — Initializers y transparent | `forge test --deny warnings`: 12 de 12 | 15 |
| | En anvil, encuentra el `ProxyAdmin`, actualiza a V2 con `upgradeAndCall` y explica `ProxyDeniedAdminAccess` | 15 |
| 03 — UUPS y storage layout | `forge test --deny warnings`: 10 de 10 | 25 |
| | Compara con `forge inspect` los layouts de `NotesV1`, `NotesV2` y `NotesV2Bad`; en anvil, actualiza con `upgradeToAndCall` | 15 |

**Total**: 100 puntos → 40 % de la nota.

---

## 📦 Producto (30 %)

| Criterio | Puntos |
| -------- | ------ |
| Carpeta `week-15/` en tu repositorio, sin `out/` ni `cache/`, con tus pruebas de fuzzing (desplegando con `deployRegistry`) y de fork, y pull request `week-15` → `main` | 10 |
| `forge test --deny warnings`: 138 tests en verde y el de fork saltado | 30 |
| Implementación cerrada, `initialize` con sus `__X_init` y la comprobación `WrongRegistry`, y `_authorizeUpgrade` con `DEFAULT_ADMIN_ROLE` | 20 |
| `RegistryV2` con `reinitializer(2)`, el límite por cuenta en `_register` y el `diff` de layouts con una sola línea nueva | 15 |
| Desplegado en anvil detrás del proxy, con la dirección predicha; un alta en V1, la actualización a V2 y el límite en acción; test de fork en verde contra el proxy | 15 |
| `.gas-snapshot` regenerado, `forge snapshot --fuzz-seed 1 --check` en verde, y el coste del proxy y los silencios del linter explicados en el pull request | 10 |

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
| [← Proyecto — Registro actualizable](3-proyecto/README.md) | **Rúbrica de evaluación** | [Ebooks gratuitos →](4-recursos/ebooks-free/README.md) |
