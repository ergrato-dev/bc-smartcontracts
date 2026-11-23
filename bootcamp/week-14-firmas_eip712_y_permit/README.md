# Semana 14 — Firmas, EIP-712 y permit

Hasta ahora, toda orden que recibe un contrato llega en una transacción de quien la da, que
paga el gas. Esta semana separas a quien autoriza de quien envía: la autorización es una
firma hecha fuera de la cadena, gratis, y cualquier cuenta la lleva al contrato. Verás cómo
recupera el contrato al firmante (ECDSA y `ecrecover`), qué formato tiene lo que se firma
(EIP-191 y EIP-712), cómo se impide que una firma valga dos veces (replay) y cómo un token
ERC-20 acepta un `approve` firmado (permit, ERC-2612). En el proyecto, un miembro firma su
alta y otra cuenta la patrocina, y los puntos se gastan sin `approve`.

## 🎯 Objetivos de aprendizaje

- Recuperar el firmante de una firma con `ecrecover` y con `ECDSA`, y firmar en tests con
  `vm.sign`.
- Rehacer en Solidity el hash que firma `cast wallet sign` con el prefijo EIP-191.
- Escribir órdenes EIP-712 con `EIP712` y `Nonces`: typehash, struct hash y dominio.
- Firmar datos tipados desde un JSON con `cast wallet sign --data`.
- Añadir `permit` a un token y usarlo desde el contrato que gasta.
- Reconocer los riesgos: firmante `address(0)`, firmas maleables, replay en el mismo contrato,
  en otro y en otra red, front-running de permits y phishing con firmas.

## 📋 Prerrequisitos

[Semana 13](../week-13-control_de_acceso/README.md) terminada: roles, pausa y timelock. Tu
repositorio `bc-smartcontracts-<dominio>` con el proyecto de la semana 13 en `main`.

## 📚 Contenidos

| # | Recurso | Tiempo |
| - | ------- | ------ |
| 1 | [Teoría 01 — ECDSA y ecrecover](1-teoria/01-ecdsa-y-ecrecover.md) | 45 min |
| 2 | [Teoría 02 — EIP-191 y replay](1-teoria/02-eip191-y-replay.md) | 40 min |
| 3 | [Teoría 03 — EIP-712, datos tipados](1-teoria/03-eip712-datos-tipados.md) | 55 min |
| 4 | [Teoría 04 — Permit (ERC-2612)](1-teoria/04-permit-erc2612.md) | 40 min |
| 5 | [Ejercicio 01 — Cupones firmados](2-practicas/ejercicio-01-cupones-firmados/README.md) | 2 h |
| 6 | [Ejercicio 02 — Votos con EIP-712](2-practicas/ejercicio-02-votos-con-eip712/README.md) | 2 h |
| 7 | [Ejercicio 03 — Permit](2-practicas/ejercicio-03-permit/README.md) | 2 h |
| 8 | [Proyecto — Órdenes firmadas](3-proyecto/README.md) | 4 h |
| 9 | [Rúbrica de evaluación](rubrica-evaluacion.md) (autoevaluación) | 30 min |
| 10 | [Ebooks](4-recursos/ebooks-free/README.md), [videos](4-recursos/videografia/README.md), [webgrafía](4-recursos/webgrafia/README.md) y [glosario](5-glosario/README.md) | 30 min |

## ⏱️ Distribución del tiempo (14 h)

| Parte | Tiempo |
| ----- | ------ |
| Teoría | 3 h |
| Prácticas | 6 h |
| Proyecto | 4 h |
| Autoevaluación, recursos y glosario | 1 h |

## ✅ Cómo saber que terminaste

- Los tres ejercicios: `forge test --deny warnings` en verde (11, 13 y 10 tests).
- En tu repositorio, `forge test` de `week-14/` pasa 122 tests y salta el de fork; en anvil
  registraste un recurso con la orden firmada de otra cuenta, el reenvío revirtió y te
  registraste con un permit sin `approve`; el test de fork pasa, `.gas-snapshot` está
  actualizado y hay un pull request `week-14` → `main`.
- Respondes las 10 preguntas de la rúbrica sin mirar la teoría.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Glosario de la semana 13](../week-13-control_de_acceso/5-glosario/README.md) | **Semana 14 — Firmas, EIP-712 y permit** | [Teoría 01 — ECDSA y ecrecover →](1-teoria/01-ecdsa-y-ecrecover.md) |

← [Volver al índice del bootcamp](../README.md)
