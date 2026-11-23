# Teoría 04 — Detectores propios

## 🎯 Objetivos

- Usar Slither como biblioteca de Python: contratos, funciones, nodos y operaciones.
- Leer SlithIR, la representación intermedia sobre la que se buscan patrones.
- Escribir un detector con `AbstractDetector` y ejecutarlo sobre un proyecto.
- Probarlo con pytest contra un contrato de casos, y saber dónde se queda corto.

## Por qué escribir uno

Los 101 detectores de Slither buscan fallos que se repiten en **todos** los contratos. Tu
protocolo tiene además reglas que solo valen para él:

- "Toda función que da un alta lleva `whenNotPaused`": la pausa de la semana 13 solo protege si
  ninguna función de alta se la salta.
- "Todo envío de ETH va con `nonReentrant`": una decisión de equipo, aunque CEI bien hecho no la
  necesite.
- "Nadie llama a `latestRoundData` sin comprobar `updatedAt`": la semana 20, convertida en un
  control.

Hoy las cumples porque las revisaste. Un detector hace que la próxima función, la que escriba
otra persona dentro de seis meses, no pueda saltársela sin que `test.sh` falle. Es la misma idea
que un test de regresión, aplicada a la forma del código en vez de a su comportamiento.

## Slither como biblioteca

Los detectores son Python e importan `slither`. En la imagen, Slither tiene su propio entorno, y
su intérprete está en la variable `$SLITHER_PYTHON`: es el que tiene `slither` instalado (y
pytest, para probar los detectores). El `python3` del sistema no lo tiene.

Un script que recorre las funciones de `Crowdfund`, en la carpeta `starter/` del ejercicio 01,
como `explore.py`:

```python
import sys

from slither import Slither

slither = Slither(sys.argv[1])
(crowdfund,) = slither.get_contract_from_name("Crowdfund")
for function in crowdfund.functions_entry_points:
    written = [variable.name for variable in function.all_state_variables_written()]
    modifiers = [modifier.name for modifier in function.modifiers]
    print(f"{function.name:12} {function.visibility:9} view={function.view!s:5} writes={written} modifiers={modifiers}")
```

```bash
"$SLITHER_PYTHON" explore.py contracts
```

Después de las líneas de compilación de forge:

```text
constructor  public    view=False writes=['owner', 'DEADLINE', 'GOAL', 'REWARD'] modifiers=[]
contribute   external  view=False writes=['contributed', 'raised'] modifiers=[]
goalReached  public    view=True  writes=[] modifiers=[]
withdraw     external  view=False writes=[] modifiers=[]
refund       external  view=False writes=['contributed'] modifiers=[]
claimReward  external  view=False writes=['rewarded'] modifiers=[]
setOwner     external  view=False writes=['owner'] modifiers=[]
```

`Slither(ruta)` compila el proyecto igual que `slither .` y devuelve el modelo del código. Lo que
más se usa:

| Objeto | Atributo o método | Qué da |
| ------ | ----------------- | ------ |
| `Slither` | `contracts`, `contracts_derived` | Todos los contratos; los que nadie hereda, es decir, los que se despliegan |
| | `get_contract_from_name("X")` | Una **lista** con los contratos que se llaman así |
| `Contract` | `functions`, `functions_entry_points` | Todas las funciones; las `public` y `external`, por donde entra una transacción (con el `constructor`, como ves arriba) |
| | `state_variables`, `modifiers` | Sus variables de estado y modificadores, heredados incluidos |
| | `is_from_dependency()` | Si viene de una dependencia, como OpenZeppelin |
| `Function` | `name`, `canonical_name`, `visibility`, `view` | `refund`, `Crowdfund.refund()`, `external`, `False` |
| | `modifiers` | Los modificadores que lleva |
| | `nodes`, `all_nodes()` | Los nodos de su grafo; los suyos y los de las funciones internas a las que llama |
| | `all_internal_calls()` | Las llamadas a funciones internas, también las indirectas; cada una tiene `.function` |
| | `all_state_variables_written()` | Las variables de estado que escribe, ella o las internas a las que llama |
| `Node` | `expression`, `irs` | La expresión en Solidity; sus operaciones de SlithIR |

Los métodos que empiezan por `all_` siguen las llamadas internas: es lo que quieres casi siempre,
porque un envío de ETH dentro de un `_send` sigue siendo un envío de la función que lo llama.

## SlithIR

Cada nodo se traduce a operaciones de **SlithIR**. `slither . --print slithir` las imprime. Para
`goalReached` del ejercicio 01:

```text
	Function Crowdfund.goalReached() (*)
		Expression: address(this).balance == GOAL
		IRs:
			TMP_146 = CONVERT this to address
			TMP_147(uint256) = SOLIDITY_CALL balance(address)(TMP_146)
			TMP_148(bool) = TMP_147 == GOAL
			RETURN TMP_148
```

Una línea de Solidity, cuatro operaciones. Cada una es un objeto de una clase de
`slither.slithir.operations`, con sus operandos. Y la llamada de `refund`:

```text
			TUPLE_1(bool,bytes) = LOW_LEVEL_CALL, dest:msg.sender, function:call, arguments:[''] value:amount
			ok(bool)= UNPACK TUPLE_1 index: 0
```

Es un `LowLevelCall` con `destination` (`msg.sender`), `function_name` (`call`) y `call_value`
(`amount`). Un `call` sin `{value: ...}` tiene `call_value` a `None`. Las clases que más se usan:

| Operación | Solidity |
| --------- | -------- |
| `LowLevelCall` | `.call`, `.delegatecall`, `.staticcall` |
| `HighLevelCall` | Llamada a otro contrato por su interfaz: `token.transfer(...)` |
| `InternalCall` | Llamada a una función del mismo contrato |
| `Transfer`, `Send` | `.transfer(...)` y `.send(...)` |
| `SolidityCall` | Funciones de Solidity: `require`, `keccak256`, `balance` |
| `Binary` | Operaciones con dos operandos: `==`, `+`, `/` |

Buscar "envía ETH" en Solidity es buscar `.transfer`, `.send` y `call{value: ...}`, escritos de
cualquier forma. En SlithIR son tres clases y un atributo. Para eso existe.

## Un detector

Un detector es una clase que hereda de `AbstractDetector`:

```python
from slither.detectors.abstract_detector import AbstractDetector, DetectorClassification


class EthSendWithoutGuard(AbstractDetector):
    ARGUMENT = "eth-send-without-guard"
    HELP = "Entry point sends ETH without nonReentrant"
    IMPACT = DetectorClassification.MEDIUM
    CONFIDENCE = DetectorClassification.HIGH

    WIKI = "https://github.com/crytic/slither/wiki/Adding-a-new-detector"
    WIKI_TITLE = "ETH sent without a reentrancy guard"
    WIKI_DESCRIPTION = "A public or external function sends ETH and has no nonReentrant modifier."
    WIKI_EXPLOIT_SCENARIO = "The receiver re-enters the contract before its state is final."
    WIKI_RECOMMENDATION = "Add nonReentrant, or justify the exception with a disable comment."

    def _detect(self):
        results = []
        for contract in self.compilation_unit.contracts_derived:
            ...
                results.append(self.generate_result([function, " sends ETH without nonReentrant\n"]))
        return results
```

- `ARGUMENT` es el nombre: el que se pone en `slither-disable-next-line`.
- `IMPACT` y `CONFIDENCE`, como los de la teoría 01. Los campos `WIKI_*` son obligatorios: Slither
  no carga un detector sin ellos.
- `_detect` devuelve la lista de resultados. `self.compilation_unit` es el proyecto compilado.
- `generate_result` recibe una lista con texto y objetos de Slither: una función se convierte en
  `Crowdfund.refund() (src/Crowdfund.sol#72-84)`, con su ubicación para el JSON.

Para ejecutarlo, se registra en un objeto `Slither`:

```python
slither = Slither("contracts")
slither.register_detector(EthSendWithoutGuard)
for results in slither.run_detectors():
    for result in results:
        print(result["description"], end="")
```

`run_detectors` devuelve una lista por detector registrado. Antes de dártela, Slither filtra los
resultados con los comentarios `// slither-disable-next-line eth-send-without-guard`: tu detector
respeta los silencios sin escribir nada para ello.

Slither también puede cargar detectores como **plugins**: un paquete de Python instalado en su
mismo entorno, que `slither` encuentra solo. En la imagen ese entorno es del sistema y no se
instala nada en él, así que esta semana los detectores se ejecutan con un script, como arriba.

## Probar un detector

Un detector es código, y se equivoca como cualquier código: puede no ver un caso (falso
negativo) o ver uno que no es (falso positivo). Se prueba con un **contrato de casos**
(*fixture*): un contrato que no se despliega, con una función por caso, y un nombre que dice qué
debería pasar.

```python
def test_detector_findings():
    slither = Slither("contracts")
    slither.register_detector(EthSendWithoutGuard)
    (results,) = slither.run_detectors()
    found = sorted(result["elements"][0]["name"] for result in results)
    assert found == ["unguardedSend", "unguardedViaInternal", "unguardedWithdraw"]
```

`result["elements"]` son los objetos que le diste a `generate_result`; el primero es la función.
Compara la lista **entera**: así falla tanto si sobra un hallazgo como si falta. Cada caso que se
te ocurra (una llamada sin valor, un envío dentro de una función interna, un modificador que no
es el guard) es una función más en el fixture.

## Dónde se queda corto

- **Los nombres.** Si el detector busca el modificador `nonReentrant` por su nombre, un
  `nonReentrant` propio que no hace nada también cuenta. Un detector de nombres comprueba
  convenciones, no semántica.
- **`delegatecall`.** `all_internal_calls()` no sigue un `delegatecall` a sí mismo: en el
  proyecto, `multicall` llega a `register` así y el detector no lo ve.
- **Otros contratos.** Una llamada a otro contrato que, a su vez, envía ETH es un `HighLevelCall`:
  el detector no sabe qué hace el otro lado.
- **El `constructor`** está en `functions_entry_points`. Si tu regla no tiene sentido en él,
  sáltalo con `function.is_constructor`.

Escribe esas limitaciones en el docstring del detector y en el informe: quien lea "0 hallazgos"
tiene que saber qué no se miró.

## ⚠️ Riesgos

- **Un detector sin tests** da una falsa sensación de seguridad: si no encuentra nada, no sabes si
  es porque no hay nada o porque no funciona.
- **Comprobar solo que encuentra algo.** Compara la lista exacta de hallazgos, con casos que no
  deben salir.
- **Reglas demasiado anchas.** Un detector que avisa en cada función acaba excluido en la
  configuración, y entonces no protege nada.

## 📝 Resumen

- `Slither(ruta)` compila y devuelve contratos, funciones, nodos y operaciones de SlithIR.
- Los métodos `all_*` siguen las llamadas internas.
- Un detector hereda de `AbstractDetector`, declara nombre, impacto, confianza y wiki, y devuelve
  resultados desde `_detect`. Se ejecuta con `register_detector` y `run_detectors`.
- Se prueba con un fixture, comparando la lista exacta de hallazgos.
- Documenta lo que no ve: nombres, `delegatecall`, otros contratos.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 03 — forge lint](03-forge-lint.md) | **Teoría 04 — Detectores propios** | [Ejercicio 01 — Slither →](../2-practicas/ejercicio-01-slither/README.md) |
