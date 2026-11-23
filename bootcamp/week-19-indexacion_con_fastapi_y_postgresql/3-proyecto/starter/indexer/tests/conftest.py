"""Base de datos, cadena y ayudas para mandar transacciones al Registry. No lo modifiques."""

import os
from collections.abc import Iterator

import psycopg
import pytest
from fastapi.testclient import TestClient

from api import app
from chain import rpc
from indexer import create_schema

ACCOUNT_1 = "0x70997970c51812dc3a010c7d01b50e0d17dc79c8"
ACCOUNT_2 = "0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc"
FEE = 10**16  # REGISTRATION_FEE: 0.01 ether


@pytest.fixture
def url() -> Iterator[str]:
    """El RPC de anvil. Al terminar el test, la cadena vuelve a como estaba (`evm_revert`)."""
    url = os.environ["RPC_URL"]
    snapshot = rpc(url, "evm_snapshot", [])
    yield url
    rpc(url, "evm_revert", [snapshot])


@pytest.fixture
def registry() -> str:
    return os.environ["REGISTRY"]


@pytest.fixture
def db() -> Iterator[psycopg.Connection]:
    """Una conexión en autocommit a una base de datos sin tablas."""
    with psycopg.connect(os.environ["DATABASE_URL"], autocommit=True) as conn:
        conn.execute("DROP TABLE IF EXISTS items, blocks")
        yield conn


@pytest.fixture
def client(db) -> Iterator[TestClient]:
    """La API sobre la base de datos de `db`, con las tablas creadas."""
    create_schema(db)
    with TestClient(app) as client:
        yield client


def word(n: int) -> str:
    return hex(n)[2:].rjust(64, "0")


def send(url: str, sender: str, to: str, data: str, value: int = 0) -> None:
    """Una transacción desde una cuenta de anvil, en un bloque nuevo."""
    rpc(url, "eth_sendTransaction", [{"from": sender, "to": to, "data": data, "value": hex(value)}])


def register(url: str, registry: str, sender: str, label: bytes) -> None:
    """`register(label)` pagando la tasa. `label` son bytes: puede no ser UTF-8 válido."""
    padded = label.hex().ljust((len(label) + 31) // 32 * 64, "0")
    send(url, sender, registry, "0xf2c298be" + word(32) + word(len(label)) + padded, FEE)


def retire(url: str, registry: str, sender: str, item_id: int) -> None:
    send(url, sender, registry, "0x3790cf57" + word(item_id))
