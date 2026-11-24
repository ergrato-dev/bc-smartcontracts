# Rúbrica de evaluación — Semana 32: Account abstraction

## 📊 Distribución de evidencias

| Tipo | Peso | Instrumento |
| ---- | ---- | ----------- |
| Conocimiento 🧠 | 30 % | Cuestionario de autoevaluación (10 preguntas) |
| Desempeño 💪 | 40 % | Ejercicios 01, 02 y 03 |
| Producto 📦 | 30 % | Proyecto: altas sin ETH |

**Nota mínima para aprobar**: 70 % en **cada** tipo de evidencia, no en el promedio.

---

## 🧠 Conocimiento (30 %)

Responde por escrito, sin mirar la teoría. Las respuestas están al final, plegadas.

| # | Pregunta | Puntos |
| - | -------- | ------ |
| 1 | ¿Qué hacen el usuario, el bundler y el EntryPoint con una UserOperation? ¿Quién paga el gas de la transacción y cómo lo recupera? | 10 |
| 2 | ¿Por qué `validateUserOp` devuelve `1` con una firma mala en vez de revertir? | 10 |
| 3 | ¿Qué pasa si `validateUserOp` no comprueba que la llama el EntryPoint? | 10 |
| 4 | ¿Qué diferencia hay entre que falle la validación y que falle la ejecución de una operación? | 10 |
| 5 | ¿Por qué el dueño de una cuenta tiene que ir en el código de creación y no en un `initialize` posterior? | 10 |
| 6 | ¿Por qué un paymaster no comprueba su plazo con `block.timestamp`? ¿Dónde lo pone? | 10 |
| 7 | ¿Por qué el presupuesto de un paymaster se comprueba con `maxCost` en la validación y no en `postOp`? | 10 |
| 8 | ¿Qué queda en una EOA después de una autorización de EIP-7702, y qué pasa cuando alguien la llama? | 10 |
| 9 | ¿Por qué un contrato para EOAs guarda su estado en un slot de ERC-7201? | 10 |
| 10 | En el proyecto, ¿por qué la cuenta es una EOA delegada y no una cuenta de fábrica, y por qué T-24 se acepta? | 10 |

**Total**: 100 puntos → 30 % de la nota.

<details>
<summary>Respuestas</summary>

1. El usuario firma la operación y la manda al mempool de los bundlers. El bundler junta varias y
   llama a `handleOps` desde su EOA: paga él el gas de esa transacción. El EntryPoint valida cada
   operación con su cuenta (y su paymaster), ejecuta, cobra a cada una lo que costó y se lo manda
   todo a `beneficiary`, la cuenta del bundler.
2. Porque una firma mala es una respuesta, no un fallo de la cuenta: el EntryPoint la distingue
   (`AA24 signature error` frente a `AA23 reverted`), y los bundlers estiman gas con firmas falsas.
   Por eso `tryRecover` y no `recover`.
3. `validateUserOp` manda `missingAccountFunds` a quien la llama. Cualquiera la llama con el saldo
   entero y se lo lleva, sin firma: la firma mala cambia lo que se devuelve, no lo que se paga.
4. Si falla la validación, `handleOps` revierte entero (`FailedOp`) y el bundler pierde su gas: por
   eso simula antes. Si falla la ejecución, la operación se cobra igual y el evento sale con
   `success = false`.
5. Porque la dirección de CREATE2 depende del código de creación: con el dueño dentro, otra persona
   no puede desplegar en esa dirección con otro dueño. Con `initialize`, el atacante despliega antes
   y se hace dueño de una cuenta que ya tiene el ETH.
6. `TIMESTAMP` está prohibido en la validación (ERC-7562): entre la simulación del bundler y el
   bloque, el resultado cambiaría. El plazo va en `validationData` (bits 160-207, `validUntil`) y lo
   comprueba el EntryPoint: `AA32 paymaster expired or not due`.
7. Porque solo la validación decide si se paga. Si la operación se pasa del presupuesto y el
   paymaster lo descubre en `postOp`, el gas ya se gastó; si `postOp` revierte, el EntryPoint
   deshace la llamada pero cobra igual al paymaster. `maxCost` es lo peor que puede costar.
8. El designador: `0xef0100` y la dirección del contrato, 23 bytes. Quien llama a la EOA ejecuta el
   código del contrato con el storage, el saldo y la dirección de la EOA (`address(this)` es la EOA).
   La clave sigue mandando y el nonce de la EOA sube.
9. Porque el storage es de la EOA y lo comparten todos los contratos en los que delegue: lo que dejó
   una delegación anterior en el slot 0 sigue ahí. Un slot calculado desde un nombre no choca.
10. Porque los puntos ya están en la EOA y `LoyaltyToken` solo acepta permits ECDSA: desde una cuenta
    de fábrica no habría puntos ni permit. T-24 (repartir puntos entre cuentas) se acepta porque
    cada alta quema 30 puntos, que cuestan tres altas con ETH, y el gas que paga el depósito es menos
    de una vigésima parte de una tasa.

</details>

---

## 💪 Desempeño (40 %)

| Ejercicio | Criterio | Puntos |
| --------- | -------- | ------ |
| 01 — Una cuenta para el EntryPoint | `forge test` sin error: `12 tests passed, 0 failed` | 15 |
| | Explica qué error `AA` da cada paso sin resolver y qué parte de la operación falló | 10 |
| 02 — Un paymaster | `forge test` sin error: `10 tests passed, 0 failed` | 15 |
| | Explica por qué `postOp` ve menos coste del que cobra el bundler | 10 |
| 03 — Una EOA con código | `forge test` sin error: `11 tests passed, 0 failed` | 15 |
| | Explica qué ataca cada campo del hash de `executeWithSignature` (red, cuenta, nonce, plazo) | 15 |
| Todos | Sin tocar `foundry.toml` ni los tests | 20 |

**Total**: 100 puntos → 40 % de la nota.

---

## 📦 Producto (30 %)

| Criterio | Puntos |
| -------- | ------ |
| Carpeta `week-32/` sin `out/`, `cache/` ni `crytic-export/`, con `contracts/snapshots/RegisterGasTest.json`, y pull request `week-32` → `main` | 10 |
| `bash test.sh` sin error: informe, gas con snapshots, 70 tests, specs, `forge lint`, Slither, detector, Medusa y los treinta y tres mutantes muertos | 25 |
| El script deposita, pone stake y propone a la DAO; el paymaster aplica sus cuatro reglas en la validación, sin leer el registro | 25 |
| Informe: alcance, actores, activos, frontera 7, T-20 a T-24 con su prueba y la sección `## Altas patrocinadas (semana 32)` | 25 |
| T-24 justificado con números de tu dominio, y la propiedad en dos pasos explicada | 15 |

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
| [← Proyecto — Altas sin ETH](3-proyecto/README.md) | **Rúbrica de evaluación** | [Ebooks gratuitos →](4-recursos/ebooks-free/README.md) |
