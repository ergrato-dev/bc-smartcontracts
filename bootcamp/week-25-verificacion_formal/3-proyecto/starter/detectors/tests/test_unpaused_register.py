"""Tests del detector `unpaused-register`: sobre el fixture y sobre el protocolo."""

from slither import Slither

from detectors.unpaused_register import UnpausedRegister


def findings(target: str) -> list[str]:
    """Compila `target` con forge, ejecuta el detector y devuelve las funciones que encuentra."""
    slither = Slither(target)
    slither.register_detector(UnpausedRegister)
    (results,) = slither.run_detectors()
    return sorted(result["elements"][0]["name"] for result in results)


def test_fixture():
    assert findings("detectors/fixture") == ["registerFor", "registerViaHelper"]


def test_protocol_respects_pause():
    # Las cinco funciones de alta del registro llevan `whenNotPaused`: ningún hallazgo.
    assert findings("contracts") == []
