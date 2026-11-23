# Rúbrica de evaluación — Semana 11: ERC-20 y OpenZeppelin

## 📊 Distribución de evidencias

| Tipo | Peso | Instrumento |
| ---- | ---- | ----------- |
| Conocimiento 🧠 | 30 % | Cuestionario de autoevaluación (10 preguntas) |
| Desempeño 💪 | 40 % | Ejercicios 01, 02 y 03 |
| Producto 📦 | 30 % | Proyecto: token de fidelidad en tu repositorio |

**Nota mínima para aprobar**: 70 % en **cada** tipo de evidencia, no en el promedio.

---

## 🧠 Conocimiento (30 %)

Responde por escrito, sin mirar la teoría. Las respuestas están al final, plegadas.

| # | Pregunta | Puntos |
| - | -------- | ------ |
| 1 | ¿Qué es un token para la red? ¿Qué identifica a un token, y por qué no basta su símbolo? | 10 |
| 2 | Un token tiene `decimals = 6`. ¿Qué mueve `transfer(to, 1)`? ¿Y cuánto hay que pasar para enviar 2,5 tokens? | 10 |
| 3 | ¿Por qué todas las wallets encuentran las transferencias de cualquier ERC-20 con un mismo filtro? | 10 |
| 4 | ¿Por qué una tienda no puede cobrar en tokens con un `transfer` del cliente? ¿Cómo cobra? | 10 |
| 5 | En `transferFrom(alice, shop, 5)` llamado por la tienda, ¿quién es el spender y qué allowance se resta? | 10 |
| 6 | Explica la carrera de `approve` y una forma de evitarla. | 10 |
| 7 | ¿Qué deja `forge install OpenZeppelin/openzeppelin-contracts@v5.7.0` en tu proyecto, y por qué con versión? | 10 |
| 8 | ¿Por qué `contract Medal is ERC20, ERC20Capped` no compila sin sobrescribir `_update`, y qué hace `super._update`? | 10 |
| 9 | ¿Qué pasa si un contrato lee el `bool` de `transferFrom` con un token como USDT? ¿Y si no lo lee con uno que devuelve `false`? | 10 |
| 10 | Un contrato acepta cualquier token y apunta `amount`. ¿Qué token lo deja debiendo, y cómo se corrige? | 10 |

**Total**: 100 puntos → 30 % de la nota.

<details>
<summary>Respuestas</summary>

1. Un contrato más: guarda una tabla de saldos en su storage y la red no sabe que es un
   token. Lo identifica la dirección de su contrato; nombre y símbolo los elige quien
   despliega, y cualquiera puede desplegar otro "USDC".
2. Una unidad mínima: 0,000001 tokens. Para 2,5 tokens, `2500000` (`cast parse-units 2.5 6`).
3. Porque el evento `Transfer(address,address,uint256)` tiene la misma firma en todos y por
   tanto el mismo topic 0 (`0xddf252ad…`).
4. Porque ese `transfer` es una llamada al token: la tienda no se entera ni sabe quién pagó.
   El cliente aprueba a la tienda en el token y la tienda, dentro de `buy()`, cobra con
   `transferFrom(msg.sender, address(this), precio)`.
5. La tienda, que es `msg.sender` para el token. Se resta `allowance[alice][shop]`.
6. Alice cambia un permiso de 100 a 50; el spender ve la transacción pendiente, gasta los
   100 antes y después los 50 nuevos. Se evita poniendo el permiso a 0 antes de cambiarlo,
   aprobando lo justo para cada operación, o aprobando solo a contratos que lo gastan en la
   misma transacción.
7. El código en `lib/openzeppelin-contracts` como submódulo de git, la URL en `.gitmodules`
   y la etiqueta y el commit en `foundry.lock`. Con versión para que el proyecto compile
   igual hoy y dentro de un año.
8. Porque las dos bases definen `_update` (error 6480) y el compilador no elige solo. Se
   escribe `override(ERC20, ERC20Capped)` y `super._update` recorre la herencia:
   `ERC20Capped` llama a `ERC20`, que mueve saldos, y a la vuelta comprueba el tope.
9. Con USDT la llamada al token sale bien pero devuelve 0 bytes, y tu contrato revierte al
   decodificar el `bool`: nunca podrá recibirlo. Sin leerlo, con un token que devuelve
   `false`, apunta un pago que no llegó. `SafeERC20` resuelve los dos.
10. Uno con comisión al transferir: llegan 99 y apunta 100, y el último en retirar no
    cobra. Se mide `balanceOf` antes y después dentro de la misma función y se apunta la
    diferencia.

</details>

---

## 💪 Desempeño (40 %)

| Ejercicio | Criterio | Puntos |
| --------- | -------- | ------ |
| 01 — ERC-20 a mano | `forge test --deny warnings`: 7 de 7 | 15 |
| | Hace el recorrido de tres cuentas en anvil y lee el spender del error final | 15 |
| 02 — Token con OpenZeppelin | `forge test --deny warnings`: 8 de 8 | 15 |
| | Explica `override(ERC20, ERC20Capped)`, por qué la regla va en `_update` y qué funciones heredó según `forge inspect` | 15 |
| 03 — Allowance y SafeERC20 | `forge test --deny warnings`: 7 de 7 | 20 |
| | Explica qué haría cada token raro sin `SafeERC20` y sin medir el saldo | 20 |

**Total**: 100 puntos → 40 % de la nota.

---

## 📦 Producto (30 %)

| Criterio | Puntos |
| -------- | ------ |
| Carpeta `week-11/` en tu repositorio, sin `out/` ni `cache/`, con tus pruebas de la semana 09, y pull request `week-11` → `main` | 10 |
| `forge test --deny warnings`: 78 tests en verde y el de fork saltado | 30 |
| `registerWithPoints` quema con `burnFrom` antes de registrar y avisa al hook al final; el token solo emite si llama el registro | 20 |
| Desplegado en anvil: token como hook, 30 tokens tras tres altas, `ERC20InsufficientAllowance` sin `approve` y alta pagada con tokens después; test de fork en verde | 15 |
| `.gas-snapshot` regenerado y `forge snapshot --fuzz-seed 1 --check` en verde; el coste de desplegar el registro explicado en el pull request | 10 |
| Calidad: nombre y símbolo del token de tu dominio, sin `TODO` restantes, y sabe qué funciones públicas heredó el token | 15 |

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
| [← Proyecto — Token de fidelidad](3-proyecto/README.md) | **Rúbrica de evaluación** | [Ebooks gratuitos →](4-recursos/ebooks-free/README.md) |
