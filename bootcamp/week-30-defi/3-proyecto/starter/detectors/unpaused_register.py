"""Detector propio de Slither para el registro: altas que no respetan la pausa.

¿Qué? Busca funciones `public` o `external` que llegan a `_register`, directamente o a través de
  otras funciones internas, y no llevan el modificador `whenNotPaused`.
¿Para qué? `pause` para las altas en una emergencia (semana 13). Hoy las cinco funciones de alta
  llevan el modificador; con este detector, una sexta en una V4 no puede olvidarlo sin que
  `test.sh` falle.
¿Impacto? Ve las llamadas internas, no las que pasan por `delegatecall` (`multicall`).
"""

from slither.detectors.abstract_detector import AbstractDetector, DetectorClassification

REGISTER = "_register"
GUARD = "whenNotPaused"


class UnpausedRegister(AbstractDetector):
    """El detector: Slither llama a `_detect` y filtra lo que devuelve."""

    ARGUMENT = "unpaused-register"
    HELP = "Entry point reaches _register without whenNotPaused"
    IMPACT = DetectorClassification.MEDIUM
    CONFIDENCE = DetectorClassification.HIGH

    WIKI = "https://github.com/crytic/slither/wiki/Adding-a-new-detector"
    WIKI_TITLE = "Registration that ignores the pause"
    WIKI_DESCRIPTION = "A public or external function reaches _register without whenNotPaused."
    WIKI_EXPLOIT_SCENARIO = "During an emergency pause, anyone keeps registering through it."
    WIKI_RECOMMENDATION = "Add whenNotPaused to every entry point that registers."

    def _detect(self):
        results = []
        for contract in self.compilation_unit.contracts_derived:
            if contract.is_from_dependency():
                continue
            for function in contract.functions_entry_points:
                registers = any(call.function.name == REGISTER for call in function.all_internal_calls())
                guarded = any(modifier.name == GUARD for modifier in function.modifiers)
                if registers and not guarded:
                    info = [function, " reaches _register without whenNotPaused\n"]
                    results.append(self.generate_result(info))
        return results
