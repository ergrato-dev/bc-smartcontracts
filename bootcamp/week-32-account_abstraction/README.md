# Semana 32 — Account abstraction

Desde la semana 1, cada transacción la firma una EOA con una clave y paga su gas en ETH. Esta
semana la cuenta pasa a ser un contrato. Primero **ERC-4337**: la UserOperation, el bundler y el
EntryPoint, y la cuenta que valida su firma y paga su gas. Después las **fábricas** y las firmas:
cuentas que existen antes de desplegarse y que aceptan lo que su código diga. Luego los
**paymasters**: contratos que pagan el gas de otros, y las reglas que impiden que les vacíen el
depósito. Y por último **EIP-7702**: una EOA que delega en un contrato sin cambiar de dirección. En
el proyecto, quien tiene puntos y no tiene ETH se da de alta: su EOA delega en la cuenta del
protocolo y un paymaster de la DAO paga el gas.

## 🎯 Objetivos de aprendizaje

- Explicar el ciclo de una UserOperation en ERC-4337 y leer los errores `AA` del EntryPoint.
- Escribir una cuenta que el EntryPoint acepta y una fábrica que la despliega en su primera
  operación.
- Escribir un paymaster con reglas en la validación, `postOp` y plazos en `validationData`.
- Delegar una EOA con EIP-7702 y escribir código para EOAs: quién llama, firmas y storage de
  ERC-7201.
- Reconocer los riesgos: validación abierta, depósitos sin reglas, inicialización sin firma y
  suposiciones que EIP-7702 rompe (`tx.origin`, `extcodesize`).

## 📋 Prerrequisitos

[Semana 31](../week-31-gobernanza_y_daos/README.md) terminada: tu protocolo con la DAO, en `main`.
Esta semana usa `CREATE2` y `delegatecall` de la semana 10, el ERC-20 de la 11, el multisig de la
13, las firmas EIP-712 y el permit de la 14, ERC-7201 de la 15, los scripts de la 16, el modelo de
amenazas de la 26 y la DAO de la 31.

**La imagen del contenedor cambia**: trae el EntryPoint v0.8.0 de eth-infinitism en
`/opt/lib/account-abstraction`. Reconstrúyela antes de empezar:

```bash
cd /ruta/a/bc-smartcontracts
docker build -t bc-smartcontracts-dev docker
```

## 📚 Contenidos

| # | Recurso | Tiempo |
| - | ------- | ------ |
| 1 | [Teoría 01 — Cuentas y UserOperations](1-teoria/01-cuentas-y-user-operations.md) | 50 min |
| 2 | [Teoría 02 — Cuentas, fábricas y firmas](1-teoria/02-cuentas-fabricas-y-firmas.md) | 45 min |
| 3 | [Teoría 03 — Paymasters](1-teoria/03-paymasters.md) | 45 min |
| 4 | [Teoría 04 — EIP-7702](1-teoria/04-eip-7702.md) | 40 min |
| 5 | [Ejercicio 01 — Una cuenta para el EntryPoint](2-practicas/ejercicio-01-una-cuenta-para-el-entrypoint/README.md) | 2 h |
| 6 | [Ejercicio 02 — Un paymaster](2-practicas/ejercicio-02-un-paymaster/README.md) | 1 h 30 min |
| 7 | [Ejercicio 03 — Una EOA con código](2-practicas/ejercicio-03-una-eoa-con-codigo/README.md) | 2 h |
| 8 | [Proyecto — Altas sin ETH](3-proyecto/README.md) | 4 h |
| 9 | [Rúbrica de evaluación](rubrica-evaluacion.md) (autoevaluación) | 30 min |
| 10 | [Ebooks](4-recursos/ebooks-free/README.md), [videos](4-recursos/videografia/README.md), [webgrafía](4-recursos/webgrafia/README.md) y [glosario](5-glosario/README.md) | 30 min |

## ⏱️ Distribución del tiempo (14 h)

| Parte | Tiempo |
| ----- | ------ |
| Teoría | 3 h |
| Prácticas | 5 h 30 min |
| Proyecto | 4 h |
| Autoevaluación, recursos y glosario | 1 h |
| Margen para reconstruir la imagen y el informe | 30 min |

## ✅ Cómo saber que terminaste

- Los tres ejercicios con `forge test` sin error: `12 tests passed`, `10 tests passed` y
  `11 tests passed`.
- En tu repositorio, `bash test.sh` de `week-32/` acaba sin error, con los nueve tests de
  `test/aa/Sponsored.t.sol` en verde y los treinta y tres mutantes muertos, y hay un pull request
  `week-32` → `main`.
- Respondes las 10 preguntas de la rúbrica sin mirar la teoría.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Glosario de la semana 31](../week-31-gobernanza_y_daos/5-glosario/README.md) | **Semana 32 — Account abstraction** | [Teoría 01 — Cuentas y UserOperations →](1-teoria/01-cuentas-y-user-operations.md) |

← [Volver al índice del bootcamp](../README.md)
