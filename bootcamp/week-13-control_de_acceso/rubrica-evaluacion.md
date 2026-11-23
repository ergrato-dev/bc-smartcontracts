# Rúbrica de evaluación — Semana 13: Control de acceso

## 📊 Distribución de evidencias

| Tipo | Peso | Instrumento |
| ---- | ---- | ----------- |
| Conocimiento 🧠 | 30 % | Cuestionario de autoevaluación (10 preguntas) |
| Desempeño 💪 | 40 % | Ejercicios 01, 02 y 03 |
| Producto 📦 | 30 % | Proyecto: roles del protocolo en tu repositorio |

**Nota mínima para aprobar**: 70 % en **cada** tipo de evidencia, no en el promedio.

---

## 🧠 Conocimiento (30 %)

Responde por escrito, sin mirar la teoría. Las respuestas están al final, plegadas.

| # | Pregunta | Puntos |
| - | -------- | ------ |
| 1 | ¿Qué dos límites tiene el `Owned` de la semana 08? | 10 |
| 2 | ¿Qué pasa si llamas a `transferOwnership` de `Ownable` con una dirección mal escrita? ¿Y con `Ownable2Step`? | 10 |
| 3 | ¿Qué hace `renounceOwnership`, y por qué una caja que se pausa debería desactivarlo? | 10 |
| 4 | ¿Qué es un rol en `AccessControl`, quién puede darlo y qué pasa si el constructor no llama a `_grantRole`? | 10 |
| 5 | Con `_setRoleAdmin(EDITOR_ROLE, MODERATOR_ROLE)`, ¿puede quien tiene `DEFAULT_ADMIN_ROLE` nombrar un editor? ¿Y un moderador hacerse editor? | 10 |
| 6 | ¿Qué diferencia hay entre `revokeRole` y `renounceRole`? ¿Para qué sirve el segundo argumento de `renounceRole`? | 10 |
| 7 | ¿Por qué una pausa no debe bloquear los retiros, y por qué conviene que quien pausa no pueda reanudar? | 10 |
| 8 | ¿Qué estados recorre una operación de un `TimelockController`, y qué ganan los usuarios con el plazo? | 10 |
| 9 | Pasas `DEFAULT_ADMIN_ROLE` a un timelock pero no renuncias a él. ¿Qué protección queda? | 10 |
| 10 | En un multisig, ¿por qué se marca `executed` antes de la llamada y por qué se rechazan dueños repetidos? | 10 |

**Total**: 100 puntos → 30 % de la nota.

<details>
<summary>Respuestas</summary>

1. El dueño no se puede cambiar (es `immutable`): si su clave se pierde o se expone, no hay
   arreglo. Y es todo o nada: una sola clave lo puede todo.
2. Con `Ownable`, la propiedad pasa al instante a esa dirección, que no es de nadie: el contrato
   se queda sin dueño para siempre. Con `Ownable2Step`, la dirección queda en `pendingOwner` y
   el dueño no cambia hasta que ella llame a `acceptOwnership`, cosa que nadie puede hacer: el
   dueño ofrece otra.
3. Deja el dueño en `address(0)`: nadie podrá volver a llamar a las funciones `onlyOwner`. Si
   el dueño renuncia con la caja en pausa, nadie podrá reanudarla.
4. Un `bytes32`, por convención el `keccak256` de su nombre, que se exige con `onlyRole`. Lo da
   quien tiene su rol administrador (`DEFAULT_ADMIN_ROLE` si no se cambia). Sin `_grantRole` en
   el constructor nadie tiene ningún rol, y nadie puede darlos nunca.
5. No: el administrador de `EDITOR_ROLE` es `MODERATOR_ROLE` y recibe
   `AccessControlUnauthorizedAccount`; tendría que hacerse moderador antes. Un moderador sí puede
   hacerse editor: administrar un rol incluye poder dárselo a uno mismo.
6. `revokeRole` lo llama el administrador del rol y quita el rol a cualquiera. `renounceRole` lo
   llama quien tiene el rol para quitárselo a sí mismo. El segundo argumento es la propia
   dirección, como confirmación: si no coincide, `AccessControlBadConfirmation`.
7. Si los retiros se pausan, quien pausa retiene el dinero de todos mientras quiera. Y si un
   atacante roba la clave de quien pausa, solo puede pausar: el administrador reanuda y le quita
   el rol.
8. `Unset`, `Waiting` (programada), `Ready` (cumplido el plazo) y `Done` (ejecutada, no se
   repite). El plazo publica el cambio antes de que ocurra: los usuarios lo ven con
   `CallScheduled` y pueden salir.
9. Ninguna: la cuenta que no renunció sigue siendo administradora y hace cualquier cambio sin
   plazo. Hay que comprobar con `hasRole` que solo el timelock tiene el rol.
10. `executed` antes de la llamada para que, si el destino llama de vuelta a `execute`, la
    propuesta ya conste como ejecutada. Un dueño repetido infla la lista de dueños: un "2 de 2"
    con el mismo dueño dos veces lo controla una sola persona.

</details>

---

## 💪 Desempeño (40 %)

| Ejercicio | Criterio | Puntos |
| --------- | -------- | ------ |
| 01 — Roles con AccessControl | `forge test --deny warnings`: 11 de 11 | 15 |
| | En anvil, la administradora no puede nombrar editores y la moderadora sí; lee la historia de `RoleGranted` | 15 |
| 02 — Pausa y dueño en dos pasos | `forge test --deny warnings`: 11 de 11 | 15 |
| | Explica por qué `withdraw` no lleva `whenNotPaused` y por qué se desactiva la renuncia | 15 |
| 03 — Multisig | `forge test --deny warnings`: 14 de 14 | 25 |
| | En anvil, una propuesta revierte con una confirmación y se ejecuta con dos; explica el umbral elegido | 15 |

**Total**: 100 puntos → 40 % de la nota.

---

## 📦 Producto (30 %)

| Criterio | Puntos |
| -------- | ------ |
| Carpeta `week-13/` en tu repositorio, sin `out/` ni `cache/`, con tus pruebas de la semana 09, y pull request `week-13` → `main` | 10 |
| `forge test --deny warnings`: 101 tests en verde y el de fork saltado | 30 |
| Solo administrador al desplegar; cada función de dueño con su rol; `unpause` solo del administrador; las altas con `whenNotPaused` y `retire` sin él | 20 |
| `supportsInterface` con `override` y `super`; el `grantRole` nuevo del fuzzing y el silencio del linter, explicados en un comentario | 15 |
| Desplegado en anvil: timelock como único administrador, hook cambiado tras el plazo, pausa de la guardiana, historia de roles; test de fork en verde | 15 |
| `.gas-snapshot` regenerado, `forge snapshot --fuzz-seed 1 --check` en verde, y el coste de `hasRole` explicado en el pull request | 10 |

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
| [← Proyecto — Roles del protocolo](3-proyecto/README.md) | **Rúbrica de evaluación** | [Ebooks gratuitos →](4-recursos/ebooks-free/README.md) |
