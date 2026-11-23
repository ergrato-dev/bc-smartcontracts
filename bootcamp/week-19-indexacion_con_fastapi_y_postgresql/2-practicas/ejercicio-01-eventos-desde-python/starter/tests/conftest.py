"""Datos de la cadena que prepara test.sh. No lo modifiques."""

import os

import pytest

ACCOUNT_0 = "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266"
ACCOUNT_1 = "0x70997970c51812dc3a010c7d01b50e0d17dc79c8"
ACCOUNT_2 = "0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc"
ZERO = "0x0000000000000000000000000000000000000000"


@pytest.fixture
def url() -> str:
    return os.environ["RPC_URL"]


@pytest.fixture
def token() -> str:
    return os.environ["TOKEN"]
