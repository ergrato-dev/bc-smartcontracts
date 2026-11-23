"""Tests del detector sobre contracts/src/Treasury.sol: cada función es un caso."""

import pytest
from slither import Slither

from detectors.eth_send_without_guard import EthSendWithoutGuard, is_guarded, sends_eth


@pytest.fixture(scope="module")
def slither():
    # Compila contracts/ con forge una sola vez para todos los tests.
    return Slither("contracts")


@pytest.fixture(scope="module")
def functions(slither):
    (treasury,) = slither.get_contract_from_name("Treasury")
    return {function.name: function for function in treasury.functions_entry_points}


def test_paso1_sends_eth(functions):
    assert sends_eth(functions["unguardedWithdraw"]), "call with value"
    assert sends_eth(functions["unguardedViaInternal"]), "call with value inside _send"
    assert sends_eth(functions["unguardedSend"]), "send"
    assert sends_eth(functions["justifiedSweep"]), "transfer"
    assert not sends_eth(functions["deposit"]), "receives ETH, does not send it"
    assert not sends_eth(functions["ping"]), "call without value"


def test_paso2_is_guarded(functions):
    assert is_guarded(functions["guardedWithdraw"])
    assert not is_guarded(functions["unguardedSend"]), "onlyOwner is not a reentrancy guard"


def test_paso3_detector_findings(slither):
    slither.register_detector(EthSendWithoutGuard)
    (results,) = slither.run_detectors()
    found = sorted(result["elements"][0]["name"] for result in results)
    # justifiedSweep envía ETH sin guard, pero su comentario `slither-disable-next-line` lo
    # silencia: Slither filtra lo que devuelve `_detect`, también en un detector propio.
    assert found == ["unguardedSend", "unguardedViaInternal", "unguardedWithdraw"]
