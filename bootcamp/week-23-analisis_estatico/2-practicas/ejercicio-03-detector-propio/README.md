# Ejercicio 03 — Detector propio

> Al terminar habrás escrito en Python un detector de Slither que busca funciones que envían ETH
> sin `nonReentrant`, lo habrás probado con pytest contra un contrato de casos y lo habrás
> ejecutado como una herramienta más.

**Duración estimada**: 2 h 30 min
**Prerrequisitos**: [Teoría 04 — Detectores propios](../../1-teoria/04-detectores-propios.md)
leída.

## Contexto

La regla de este ejercicio: **toda función `public` o `external` que envía ETH lleva
`nonReentrant`**. Slither no la trae: con checks-effects-interactions bien hecho no hace falta,
y su detector `reentrancy-eth` solo avisa cuando hay estado escrito después de la llamada. Pero
es una regla que un equipo puede decidir para su protocolo, y un detector la convierte en un
control que falla solo.

El detector es Python y usa Slither como biblioteca. En la imagen, Slither tiene su propio Python:
`$SLITHER_PYTHON`. `test.sh` ejecuta los tests con pytest sobre ese Python.

| Archivo | Qué es |
| ------- | ------ |
| `detectors/eth_send_without_guard.py` | El detector. Pasos 1, 2 y 3 |
| `detectors/run.py` | Lo ejecuta sobre un proyecto Foundry e imprime lo que encuentra. Hecho |
| `contracts/src/Treasury.sol` | El contrato de casos: cada función es uno. **No lo modifiques** |
| `tests/test_detector.py` | Los tests. **No lo modifiques** |

Las funciones de `Treasury` dicen en su nombre qué debería encontrar el detector:

| Función | Envía ETH | Guard | ¿Hallazgo? |
| ------- | --------- | ----- | ---------- |
| `deposit` | No: lo recibe | — | No |
| `guardedWithdraw` | Sí, dentro de `_send` | `nonReentrant` | No |
| `unguardedWithdraw` | Sí, con `call` | — | Sí |
| `unguardedViaInternal` | Sí, dentro de `_send` | — | Sí |
| `unguardedSend` | Sí, con `send` | `onlyOwner`, que no es un guard | Sí |
| `justifiedSweep` | Sí, con `transfer` | — | No: lleva `// slither-disable-next-line eth-send-without-guard` |
| `ping` | No: `call` sin valor | — | No |

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-23-analisis_estatico/2-practicas/ejercicio-03-detector-propio/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
bash test.sh
```

**Verifica**: `3 failed`, los tres con `NotImplementedError: TODO: Paso N`. Antes de los tests,
Slither ha compilado `contracts/` con forge: lo hace cada vez que crea un objeto `Slither`.

## Paso 1: ¿Envía ETH?

**Por qué**: Slither traduce cada función a su representación intermedia, **SlithIR**: una lista
de operaciones simples por nodo del grafo de control (teoría 04). Enviar ETH es una de tres:
`Transfer` (`.transfer`), `Send` (`.send`) o `LowLevelCall` con `call_value`, que es el
`{value: ...}` de un `call`; un `call` sin valor lo tiene a `None`. `all_nodes()` recorre los
nodos de la función **y los de las funciones internas a las que llama**: así ve el `call` de
`_send` desde `guardedWithdraw` y `unguardedViaInternal`.

```python
for node in function.all_nodes():
    for ir in node.irs:
        if isinstance(ir, (Transfer, Send)):
            return True
        if isinstance(ir, LowLevelCall) and ir.call_value is not None:
            return True
return False
```

**Abre** `detectors/eth_send_without_guard.py`, borra el `raise` de `sends_eth` y descomenta sus
líneas `#> `.

**Verifica**: `2 failed, 1 passed`. `test_paso1_sends_eth` en verde: los cuatro que envían ETH dan
`True`; `deposit` y `ping`, `False`.

## Paso 2: ¿Lleva el guard?

**Por qué**: `function.modifiers` es la lista de modificadores de la función, cada uno con su
`name`. `onlyOwner` limita quién llama, pero no impide que esa cuenta vuelva a entrar: no cuenta.

```python
return any(modifier.name == GUARD for modifier in function.modifiers)
```

**Abre** el mismo archivo, borra el `raise` de `is_guarded` y descomenta su línea.

**Verifica**: `1 failed, 2 passed`. `test_paso2_is_guarded` en verde.

## Paso 3: El detector

**Por qué**: un detector es una clase que hereda de `AbstractDetector`, con su nombre
(`ARGUMENT`), su impacto, su confianza y su documentación, y un método `_detect` que devuelve los
resultados. `contracts_derived` son los contratos que nadie hereda: los que se despliegan, con
todas las funciones heredadas dentro. `is_from_dependency()` descarta OpenZeppelin.
`functions_entry_points` son las funciones `public` y `external`, más la `fallback`: por donde
entra una transacción. Incluye las `view`, pero esas no envían ETH y no salen. `generate_result` recibe el texto del hallazgo, con objetos de Slither que se
convierten en su nombre y su ubicación.

```python
for contract in self.compilation_unit.contracts_derived:
    if contract.is_from_dependency():
        continue
    for function in contract.functions_entry_points:
        if sends_eth(function) and not is_guarded(function):
            info = [function, " sends ETH without nonReentrant\n"]
            results.append(self.generate_result(info))
```

**Abre** el mismo archivo, borra el `raise` de `_detect` y descomenta sus líneas.

**Verifica**: `3 passed`. `test_paso3_detector_findings` encuentra exactamente
`unguardedSend`, `unguardedViaInternal` y `unguardedWithdraw`. `justifiedSweep` no sale, y no has
escrito nada para eso: Slither filtra lo que devuelve `_detect` con los comentarios
`slither-disable-next-line`, también en un detector propio.

## Paso 4: Usarlo como una herramienta

**Por qué**: `run.py` registra el detector en un objeto `Slither` y lo ejecuta, como haría
`slither` con los suyos. Termina con código 1 si encuentra algo: sirve en un `test.sh` o en CI.

```bash
cd detectors
"$SLITHER_PYTHON" run.py ../contracts
```

**Verifica**: después de las líneas de compilación de forge, tres hallazgos y el total:

```text
Treasury.unguardedWithdraw() (src/Treasury.sol#32-37) sends ETH without nonReentrant
Treasury.unguardedSend() (src/Treasury.sol#47-50) sends ETH without nonReentrant
Treasury.unguardedViaInternal() (src/Treasury.sol#40-44) sends ETH without nonReentrant
3 result(s) found
```

Cada uno con su archivo y sus líneas, como los de Slither. `echo $?` da `1`.

## Para pensar

- Ejecuta `run.py` sobre `contracts/` del ejercicio 01. ¿Qué funciones de `Crowdfund` salen, y
  alguna de ellas era vulnerable después de tus correcciones?
- `all_nodes()` ve las funciones internas. ¿Ve una llamada a otro contrato que, a su vez, envía
  ETH? ¿Debería contar?
- El detector busca el modificador por su nombre. ¿Qué pasa si un contrato define su propio
  `nonReentrant` que no hace nada? ¿Cómo lo comprobarías?

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 02 — forge lint](../ejercicio-02-forge-lint/README.md) | **Ejercicio 03 — Detector propio** | [Proyecto — Análisis estático de tu protocolo →](../../3-proyecto/README.md) |
