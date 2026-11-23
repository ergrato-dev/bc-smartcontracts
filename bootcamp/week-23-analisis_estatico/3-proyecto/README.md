# Proyecto — Análisis estático de tu protocolo

> Pasas Slither y forge lint por tu protocolo y los conviertes en controles de `test.sh`. Casi
> todo lo que dicen ya lo sabías, y se justifica en el código, línea a línea. Una cosa no: el alta
> con puntos llama al token antes de escribir el alta. Lo corriges, escribes un detector propio
> para la regla de la pausa, y añades el análisis estático y el hallazgo H-03 al informe.

**Duración estimada**: 4 h
**Prerrequisitos**: los tres ejercicios de la semana en verde; tu proyecto de la semana 22 en
`main`.

## Capa que se añade y por qué ahora

Las semanas 21 y 22 revisaron tu protocolo a mano, clase por clase, y dejaron tests que atacan.
Esta semana añade una revisión que no se cansa: dos analizadores que pasan por todo el código en
cada `test.sh`, y una regla propia que ningún analizador trae. A partir de aquí, un cambio que
reintroduzca un patrón peligroso falla antes de llegar a un pull request.

Un protocolo que ya se revisó a mano da sobre todo falsos positivos, y eso también es trabajo:
cada silencio lleva su porqué, y el informe dice qué se miró y qué no.

## Preparar la rama

**Dónde**: en tu terminal, en tu repositorio `bc-smartcontracts-<tu-dominio>`.

1. Parte de `main` actualizado y crea la rama de la semana:

   ```bash
   git switch main
   git pull
   git switch -c week-23
   ```

2. Copia el starter en `week-23/` y pon encima tus contratos y tu informe de la semana 22:

   ```bash
   cp -r ../bc-smartcontracts/bootcamp/week-23-analisis_estatico/3-proyecto/starter week-23
   cp -r week-22/contracts/src week-22/contracts/script week-23/contracts/
   cp -r week-22/audit week-23/
   ls -l week-23/contracts/lib
   ```

   **Verifica**: `lib -> /opt/lib`. Tus `src/` y `script/` son los de la semana 22, y
   `week-23/audit/README.md`, tu informe.

3. Entra al contenedor y mira el rojo:

   ```bash
   cd week-23
   docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
   bash test.sh
   ```

**Verifica**: los tests de Foundry pasan, `26 tests passed` en 4 suites, y `test.sh` se para en
`forge lint`, con 3 avisos: `reentrancy-events`, `reentrancy-no-eth` y `unsafe-typecast`. Desde
`contracts/`, `slither .` da `21 result(s) found`. Son los números de la solución de referencia;
con tu dominio pueden cambiar.

## Qué hay en el starter

| Ruta | Qué es |
| ---- | ------ |
| `contracts/src/`, `contracts/script/` | Los de la solución de la semana 22: tu referencia. Tú usas los tuyos |
| `contracts/src/Registry.sol` | Con un `// TODO (semana 23)` en `_registerWithPoints`: el requisito 1 |
| `contracts/slither.config.json` | La configuración de Slither de los ejercicios. **No la modifiques** |
| `contracts/test/PointsRegistration.t.sol` | 2 tests nuevos del alta con puntos, que pasan antes y después del requisito 1 |
| `contracts/test/` (el resto) | Los tests y atacantes de las semanas 20 a 22 |
| `detectors/unpaused_register.py` | **Tu trabajo**: el detector propio, con su `# TODO:` y su pista |
| `detectors/fixture/` | Un proyecto Foundry mínimo con los casos del detector |
| `detectors/tests/test_unpaused_register.py` | 2 tests del detector: sobre el fixture y sobre tu protocolo. **No los modifiques** |
| `test.sh` | Tests, compilación sin warnings, `forge lint --deny warnings src`, `slither .` y los tests del detector |

## Requisitos

| # | Dónde | Qué |
| - | ----- | --- |
| 1 | `_registerWithPoints` de tu `Registry` | `_register` primero y `loyalty.burnFrom` después (checks-effects-interactions) |
| 2 | Tus contratos de `src/` | Cada hallazgo de Slither y de forge lint, corregido o silenciado en su línea con un comentario que diga por qué. Nada excluido en la configuración |
| 3 | `detectors/unpaused_register.py` | `_detect` devuelve las funciones de entrada que llegan a `_register` sin `whenNotPaused` |
| 4 | `week-23/audit/README.md` | El informe de la semana 22, con el análisis estático y el hallazgo H-03 |

### El hallazgo: el alta con puntos

Slither y forge lint coinciden en `_registerWithPoints`:

```solidity
if (activeCount >= capacity) revert RegistryFull(capacity);
loyalty.burnFrom(msg.sender, POINTS_PRICE);
id = _register(msg.sender, label);
```

La llamada a `loyalty` va antes de escribir el alta: si el token llamara a otro contrato al
quemar, ese contrato vería la capacidad comprobada y el alta sin escribir. Hoy no pasa nada:
`LoyaltyToken` es tuyo, `burnFrom` de OpenZeppelin no llama a nadie, y la dirección del token no
cambia. Pero rompe checks-effects-interactions sin ninguna necesidad, y corregirlo es cambiar dos
líneas de orden. Si no hay puntos, `burnFrom` revierte y deshace el alta entera:
`test_RevertWhen_NotEnoughPoints` lo comprueba.

### Silenciar sin perder nada

Para cada hallazgo, el triaje de la teoría 01: verdadero, falso positivo o aceptado. Muchos ya
los razonaste en las semanas 21 y 22 (el hook en el bucle de un lote, el `timestamp` del plazo
de la firma, el `bytes4(reason)` de H-01): ahora lo escribes al lado del código.

Cuando la misma línea necesita los dos comentarios, Slither encima y forge lint al final
(teoría 03):

```solidity
// Solo TREASURER_ROLE llega aquí. Los dos analizadores reconocen `onlyOwner`, no `onlyRole`.
// slither-disable-next-line arbitrary-send-eth
(bool ok,) = to.call{value: amount}(""); // forge-lint: disable-line(arbitrary-send-eth)
```

Un mismo silencio puede cerrar varios hallazgos. Slither da siete `reentrancy-events`, y seis son
el mismo evento visto desde cada función de alta: `HookFailed`, que se emite después de llamar al
hook porque cuenta precisamente que la llamada falló. Un comentario encima de ese `emit` los
cierra, y Slither pasa de 21 a 15. El séptimo es el de `_registerWithPoints`, y lo cierra H-03.

### El detector

La regla: **toda función de entrada que llega a `_register` lleva `whenNotPaused`**. Hoy la
cumplen las cinco funciones de alta. El detector hace que una sexta no pueda olvidarla.

Es el ejercicio 03 con otra condición: en vez de buscar envíos de ETH en `all_nodes()`, busca
`_register` entre las llamadas de `all_internal_calls()` (cada una tiene `.function`, con su
`name`). Los tests lo prueban dos veces:

| Test | Qué mira |
| ---- | -------- |
| `test_fixture` | Sobre `detectors/fixture/`: encuentra exactamente `registerFor` (sin el modificador) y `registerViaHelper` (sin el modificador, a través de otra función interna) |
| `test_protocol_respects_pause` | Sobre tu `contracts/`: ningún hallazgo |

## Cómo verificar

```bash
bash test.sh
```

**Verifica**: `26 tests passed`, `forge lint` sin avisos, Slither con
`analyzed (58 contracts with 75 detectors), 0 result(s) found`, y `2 passed` en los tests del
detector. Con tu dominio, el número de contratos puede ser otro.

H-03 cambia la implementación de `Registry`. Llévala a anvil y a Sepolia con `PatchV3.s.sol` como
en la semana 22 si quieres; si no, el informe dice que llega con la siguiente actualización.

## El informe de auditoría

Copia tu informe a `week-23/audit/README.md` (ya lo copiaste al preparar la rama) y añade:

1. **Análisis estático**: las herramientas, sus versiones y su configuración; cuántos hallazgos
   dio cada una al principio y al final; y una tabla con el veredicto de cada uno. Agrupa los que
   tienen la misma causa.
2. **La regla propia**: qué comprueba el detector y qué **no** ve.
3. **H-03**, con el mismo formato que H-01 y H-02.

```markdown
## Análisis estático (semana 23)

| Herramienta | Versión | Configuración | Resultado inicial | Resultado final |
| ----------- | ------- | ------------- | ----------------- | --------------- |
| Slither | 0.11.5 | `contracts/slither.config.json`: ... | 21 hallazgos | 0 |
| forge lint | Foundry v1.9.0 | `--deny warnings` sobre `src/` | 3 avisos | 0 |
| `unpaused-register` (propio) | — | `detectors/unpaused_register.py` | 0 | 0 |

| Detector | Dónde | Veredicto | Acción |
| -------- | ----- | --------- | ------ |
| `reentrancy-no-eth`, ... | `_registerWithPoints`: `burnFrom` antes de `_register` | Verdadero, no explotable hoy | Corregido: H-03 |
| `arbitrary-send-eth` (los dos) | `withdrawFees` envía a `to` | Falso positivo: solo `TREASURER_ROLE` | Comentario |
| ... | ... | ... | ... |

## Hallazgos

| Id | Título | Severidad | Estado |
| -- | ------ | --------- | ------ |
| H-01 | ... | Baja | Corregido |
| H-02 | ... | Baja | Corregido |
| H-03 | El alta con puntos llama al token antes de escribir el alta | Informativa | Corregido |
```

Termina la sección con lo que **no** vieron las herramientas: ¿encuentra algún detector H-01 o
H-02? ¿Por qué no?

## Ejemplos de adaptación

| Dominio | Una regla propia que tendría sentido |
| ------- | ------------------------------------ |
| Biblioteca | Toda función que presta un libro comprueba el límite de préstamos por socio |
| Tienda en línea | Toda función que mueve el saldo de una tienda emite un evento |
| Cine | Toda función que reserva una butaca comprueba que la sesión no ha empezado |

El detector del starter es el de la pausa, que vale para cualquier dominio. Si en el tuyo hay una
regla así, escribe un segundo detector con su fixture y sus tests.

## Criterios de calidad (no automatizables)

- Cada comentario de silencio dice **por qué** no es un fallo, no solo qué detector silencia.
- Ningún detector ni lint excluido en `slither.config.json` ni en `foundry.toml`.
- La tabla del informe tiene un veredicto para cada hallazgo, y los que comparten causa van juntos.
- El informe dice qué no ve el detector propio (por ejemplo, `multicall` y su `delegatecall`).

## Entrega

1. `bash test.sh` acaba sin error: tests, `forge lint`, Slither y detector en verde.
2. `week-23/audit/README.md` con el análisis estático y H-03.
3. Commit y pull request:

   ```bash
   git add week-23
   git commit -m "feat(week-23): add static analysis gates and custom detector"
   git push -u origin week-23
   ```

   Abre el pull request `week-23` → `main` y fusiónalo cuando esté en verde.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 03 — Detector propio](../2-practicas/ejercicio-03-detector-propio/README.md) | **Proyecto — Análisis estático de tu protocolo** | [Rúbrica de evaluación →](../rubrica-evaluacion.md) |
