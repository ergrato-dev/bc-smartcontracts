"""Detector propio de Slither: funciones de entrada que envían ETH sin `nonReentrant`.

¿Qué? Busca funciones `public` o `external` que envían ETH, directamente o a través de una
  función interna, y no llevan el modificador `nonReentrant`.
¿Para qué? Convertir en un control automático una regla de tu protocolo: todo envío de ETH va
  protegido contra la reentrada (semana 21). Slither no la trae: CEI bien hecho no la necesita, y
  su detector `reentrancy-eth` solo avisa cuando ve estado escrito después de la llamada.
¿Impacto? Es una regla, no una prueba de vulnerabilidad: una función sin guard y con CEI
  correcto también sale. Se justifica con `// slither-disable-next-line eth-send-without-guard`.
"""

from slither.core.declarations import Function
from slither.detectors.abstract_detector import AbstractDetector, DetectorClassification
from slither.slithir.operations import LowLevelCall, Send, Transfer

GUARD = "nonReentrant"


def sends_eth(function: Function) -> bool:
    """Si `function`, o alguna función interna a la que llama, envía ETH."""
    raise NotImplementedError("TODO: Paso 1")
    #> for node in function.all_nodes():
    #>     for ir in node.irs:
    #>         if isinstance(ir, (Transfer, Send)):
    #>             return True
    #>         if isinstance(ir, LowLevelCall) and ir.call_value is not None:
    #>             return True
    #> return False


def is_guarded(function: Function) -> bool:
    """Si `function` lleva el modificador `nonReentrant`."""
    raise NotImplementedError("TODO: Paso 2")
    #> return any(modifier.name == GUARD for modifier in function.modifiers)


class EthSendWithoutGuard(AbstractDetector):
    """El detector: Slither llama a `_detect` y filtra lo que devuelve."""

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
        raise NotImplementedError("TODO: Paso 3")
        #> for contract in self.compilation_unit.contracts_derived:
        #>     if contract.is_from_dependency():
        #>         continue
        #>     for function in contract.functions_entry_points:
        #>         if sends_eth(function) and not is_guarded(function):
        #>             info = [function, " sends ETH without nonReentrant\n"]
        #>             results.append(self.generate_result(info))
        return results
