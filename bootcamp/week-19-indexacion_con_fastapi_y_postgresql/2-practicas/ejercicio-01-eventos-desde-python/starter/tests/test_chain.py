"""Tests del ejercicio 01. No los modifiques."""

import pytest

import chain
from chain import Transfer, decode_transfer, fetch_transfers, get_block, get_transfer_logs, rpc
from conftest import ACCOUNT_0, ACCOUNT_1, ACCOUNT_2, ZERO

ETHER = 10**18


def test_paso_1_rpc(url):
    assert rpc(url, "eth_chainId", []) == "0x7a69"
    assert rpc(url, "eth_blockNumber", []) == "0x3"
    with pytest.raises(chain.RpcError):
        rpc(url, "eth_noExiste", [])


def test_paso_2_bloque(url):
    block_2 = get_block(url, 2)
    block_3 = get_block(url, 3)
    assert block_3.number == 3
    assert block_3.parent_hash == block_2.hash
    assert len(block_3.hash) == 66


def test_paso_3_logs(url, token):
    logs = get_transfer_logs(url, token, 0, 3)
    assert [log["blockNumber"] for log in logs] == ["0x1", "0x2", "0x3"]
    assert get_transfer_logs(url, token, 2, 2)[0]["topics"][2] == "0x" + "0" * 24 + ACCOUNT_1[2:]


def test_paso_4_decodificar(url, token):
    first, second, _ = [decode_transfer(log) for log in get_transfer_logs(url, token, 0, 3)]
    assert (first.block_number, first.log_index) == (1, 0)
    assert (first.sender, first.recipient, first.value) == (ZERO, ACCOUNT_0, 1000 * ETHER)
    assert (second.sender, second.recipient, second.value) == (ACCOUNT_0, ACCOUNT_1, 100 * ETHER)
    assert second.block_hash == get_block(url, 2).hash


def test_paso_5_por_tramos(url, token, monkeypatch):
    calls = []
    original = chain.get_transfer_logs

    def counted(url, token, from_block, to_block):
        calls.append((from_block, to_block))
        return original(url, token, from_block, to_block)

    monkeypatch.setattr(chain, "get_transfer_logs", counted)
    transfers = fetch_transfers(url, token, 0, 3, chunk=2)
    assert calls == [(0, 1), (2, 3)]
    assert [t.recipient for t in transfers] == [ACCOUNT_0, ACCOUNT_1, ACCOUNT_2]
    assert all(isinstance(t, Transfer) for t in transfers)
