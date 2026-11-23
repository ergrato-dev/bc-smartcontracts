"""Base de datos y cadena que prepara test.sh, y ayudas para los tests. No lo modifiques."""

import os
from collections.abc import Iterator

import psycopg
import pytest

from chain import rpc

ACCOUNT_0 = "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266"
ACCOUNT_1 = "0x70997970c51812dc3a010c7d01b50e0d17dc79c8"
ACCOUNT_2 = "0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc"
ACCOUNT_5 = "0x9965507d1a55bcc2695c58ba16fb37d819b0a4dc"
ETHER = 10**18


@pytest.fixture
def url() -> Iterator[str]:
    """El RPC de anvil. Al terminar el test, la cadena vuelve a como estaba (`evm_revert`)."""
    url = os.environ["RPC_URL"]
    snapshot = rpc(url, "evm_snapshot", [])
    yield url
    rpc(url, "evm_revert", [snapshot])


@pytest.fixture
def token() -> str:
    return os.environ["TOKEN"]


@pytest.fixture
def conn() -> Iterator[psycopg.Connection]:
    """Una conexión en autocommit a una base de datos sin tablas."""
    with psycopg.connect(os.environ["DATABASE_URL"], autocommit=True) as conn:
        conn.execute("DROP TABLE IF EXISTS transfers, blocks")
        yield conn


def send_transfer(url: str, token: str, sender: str, to: str, value: int) -> None:
    """`transfer(to, value)` del Token desde una cuenta de anvil, en un bloque nuevo."""
    data = "0xa9059cbb" + to[2:].rjust(64, "0") + hex(value)[2:].rjust(64, "0")
    rpc(url, "eth_sendTransaction", [{"from": sender, "to": token, "data": data}])
