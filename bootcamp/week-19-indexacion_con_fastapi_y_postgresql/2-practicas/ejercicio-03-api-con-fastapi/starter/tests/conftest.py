"""Base de datos indexada desde la cadena de test.sh y un cliente de la API. No lo modifiques."""

import os
from collections.abc import Iterator

import psycopg
import pytest
from fastapi.testclient import TestClient

from api import app
from store import create_schema, sync

ACCOUNT_0 = "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266"
ACCOUNT_1 = "0x70997970c51812dc3a010c7d01b50e0d17dc79c8"
ACCOUNT_2 = "0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc"
ZERO = "0x0000000000000000000000000000000000000000"


@pytest.fixture
def client() -> Iterator[TestClient]:
    """La API sobre una base de datos con las tres transferencias de los bloques 1, 2 y 3."""
    with psycopg.connect(os.environ["DATABASE_URL"], autocommit=True) as conn:
        conn.execute("DROP TABLE IF EXISTS transfers, blocks")
        create_schema(conn)
        sync(conn, os.environ["RPC_URL"], os.environ["TOKEN"])
    with TestClient(app) as client:
        yield client

