# Rúbrica de evaluación — Semana 14: Firmas, EIP-712 y permit

## 📊 Distribución de evidencias

| Tipo | Peso | Instrumento |
| ---- | ---- | ----------- |
| Conocimiento 🧠 | 30 % | Cuestionario de autoevaluación (10 preguntas) |
| Desempeño 💪 | 40 % | Ejercicios 01, 02 y 03 |
| Producto 📦 | 30 % | Proyecto: órdenes firmadas en tu repositorio |

**Nota mínima para aprobar**: 70 % en **cada** tipo de evidencia, no en el promedio.

---

## 🧠 Conocimiento (30 %)

Responde por escrito, sin mirar la teoría. Las respuestas están al final, plegadas.

| # | Pregunta | Puntos |
| - | -------- | ------ |
| 1 | ¿Qué devuelve `ecrecover` con una firma inválida, y por qué eso puede dejar pasar cualquier firma? | 10 |
| 2 | ¿Qué es la maleabilidad de ECDSA y por qué no debes marcar como usada una firma por sus bytes? | 10 |
| 3 | ¿Qué hash firma de verdad `cast wallet sign 0x<32 bytes>`, y qué pasa si el contrato recupera sobre el hash sin prefijo? | 10 |
| 4 | ¿Por qué un mensaje firmado se codifica con `abi.encode` y no con `abi.encodePacked`? | 10 |
| 5 | Nombra las cuatro formas de replay y la defensa de cada una. | 10 |
| 6 | ¿Qué aporta EIP-712 frente a EIP-191, para el usuario y para el contrato? | 10 |
| 7 | ¿Cómo entra un `string` en el struct hash, y qué pasa si el typehash lleva un espacio de más? | 10 |
| 8 | ¿Qué ventaja tiene un nonce frente a `used[hash]`, y cómo anula una cuenta una orden que ya firmó? | 10 |
| 9 | ¿Por qué se llama a `permit` dentro de un `try`, y por qué eso no deja gastar con un permit falso? | 10 |
| 10 | En `registerBySig`, ¿por qué `_register` ya no puede usar `msg.sender`, y qué gana quien envía antes una orden ajena? | 10 |

**Total**: 100 puntos → 30 % de la nota.

<details>
<summary>Respuestas</summary>

1. Devuelve `address(0)`, sin revertir. Si el contrato compara con una dirección que nunca se
   asignó (también `address(0)`), cualquier basura pasa. `ECDSA.recover` revierte en vez de
   devolver `address(0)`.
2. De una firma válida `(r, s, v)` sale otra igual de válida, `(r, N - s, v')`, que recupera
   la misma dirección. Si marcas los bytes de la firma, el atacante envía la gemela. Se marca
   el hash del mensaje o se usa un nonce, y `ECDSA` solo acepta `s` en la mitad baja.
3. `keccak256("\x19Ethereum Signed Message:\n32" ‖ hash)`: el prefijo EIP-191 con la longitud
   32. Sin el prefijo, `ecrecover` devuelve otra dirección, de nadie, y la firma correcta se
   rechaza.
4. `abi.encodePacked` pega los valores sin separarlos: con dos campos dinámicos, órdenes
   distintas dan los mismos bytes (`"ab","c"` y `"a","bc"`) y la misma firma. `abi.encode`
   da a cada campo su sitio.
5. En el mismo contrato: marca de usado o nonce. En otro contrato: `address(this)` en el hash.
   En otra red: `block.chainid`. Fuera de tiempo: un `deadline` comprobado con
   `block.timestamp`.
6. Al usuario, la wallet le enseña cada campo con su nombre en vez de 32 bytes. Al contrato,
   el dominio (nombre, versión, red, contrato) mete en el hash las defensas contra el replay
   en otro contrato y en otra red, de forma estándar.
7. Como su `keccak256`. El typehash es el keccak256 de un texto: con un espacio de más es otro
   hash, el digest no coincide con el de la wallet y toda firma da `InvalidSigner`.
8. Las órdenes de una cuenta van en orden y no hay que guardar cada hash usado. Para anular,
   la cuenta gasta su nonce sin usarlo (`cancelNonce`): la firma pendiente lleva el nonce
   viejo y ya no recupera a quien firmó.
9. Porque cualquiera puede copiar la firma del mempool y enviarla antes al token: el nonce
   queda gastado y el `permit` del contrato revertiría, arrastrando la operación (griefing).
   Con el `try`, el fallo se ignora y `transferFrom` o `burnFrom` decide: un permit falso o
   caducado no da allowance, y el cobro revierte.
10. Porque quien llama es el patrocinador, no quien registra: el recurso, el certificado y los
    puntos tienen que ser de `registrant`. Quien envía antes una orden ajena no gana nada:
    paga la tasa de su bolsillo y el recurso sigue siendo del miembro.

</details>

---

## 💪 Desempeño (40 %)

| Ejercicio | Criterio | Puntos |
| --------- | -------- | ------ |
| 01 — Cupones firmados | `forge test --deny warnings`: 11 de 11 | 15 |
| | En anvil, canjea un cupón firmado con `cast` desde otra cuenta; explica los tres errores de los ataques | 15 |
| 02 — Votos con EIP-712 | `forge test --deny warnings`: 13 de 13 | 15 |
| | En anvil, firma el `Vote` desde un JSON y lo envía un relayer; explica por qué el reenvío falla sin `used[...]` | 15 |
| 03 — Permit | `forge test --deny warnings`: 10 de 10 | 25 |
| | En anvil, compra en una transacción con un permit firmado; explica qué pasa al quitar el `try` | 15 |

**Total**: 100 puntos → 40 % de la nota.

---

## 📦 Producto (30 %)

| Criterio | Puntos |
| -------- | ------ |
| Carpeta `week-14/` en tu repositorio, sin `out/` ni `cache/`, con tus pruebas de fuzzing y de fork, y pull request `week-14` → `main` | 10 |
| `forge test --deny warnings`: 122 tests en verde y el de fork saltado | 30 |
| `_register` y `_notifyHook` con `registrant`; `registerBySig` con plazo, firmante, nonce, capacidad y tasa en ese orden | 20 |
| `LoyaltyToken` con `ERC20Permit` y el nombre del token; `registerWithPermit` con `try`, `msg.sender` como `owner` y `whenNotPaused`; el silencio del linter, explicado | 15 |
| Desplegado en anvil: un alta firmada por otra cuenta y patrocinada por ti, el reenvío rechazado, un alta con permit; test de fork en verde | 15 |
| `.gas-snapshot` regenerado, `forge snapshot --fuzz-seed 1 --check` en verde, y el coste del despliegue explicado en el pull request | 10 |

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
| [← Proyecto — Órdenes firmadas](3-proyecto/README.md) | **Rúbrica de evaluación** | [Ebooks gratuitos →](4-recursos/ebooks-free/README.md) |
