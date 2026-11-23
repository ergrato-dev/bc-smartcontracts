"""Tests del ejercicio 03. No los modifiques."""

import os

import psycopg

from conftest import ACCOUNT_0, ACCOUNT_1, ACCOUNT_2, ZERO

ETHER = 10**18


def test_paso_1_estado(client):
    assert client.get("/status").json() == {"last_block": 3}
    with psycopg.connect(os.environ["DATABASE_URL"], autocommit=True) as conn:
        conn.execute("TRUNCATE blocks CASCADE")
    assert client.get("/status").json() == {"last_block": None}


def test_paso_2_saldo(client):
    response = client.get(f"/balances/{ACCOUNT_1.upper().replace('0X', '0x')}")
    assert response.status_code == 200
    assert response.json() == {"account": ACCOUNT_1, "balance": str(100 * ETHER)}
    assert client.get("/balances/hola").status_code == 422


def test_paso_3_transferencias(client):
    page = client.get("/transfers", params={"limit": 2}).json()
    assert [t["block_number"] for t in page] == [3, 2]
    assert page[0]["value"] == "50000000000000000000"
    assert [t["recipient"] for t in client.get("/transfers", params={"offset": 2}).json()] == [ACCOUNT_0]
    mine = client.get("/transfers", params={"account": ACCOUNT_0}).json()
    assert [(t["sender"], t["recipient"]) for t in mine] == [(ACCOUNT_0, ACCOUNT_2), (ACCOUNT_0, ACCOUNT_1), (ZERO, ACCOUNT_0)]
    assert client.get("/transfers", params={"limit": 1000}).status_code == 422
    assert client.get("/transfers", params={"account": "' OR 1=1 --"}).status_code == 422


def test_paso_4_una_transferencia(client):
    newest = client.get("/transfers", params={"limit": 1}).json()[0]
    assert client.get(f"/transfers/{newest['tx_hash']}").json() == newest
    response = client.get("/transfers/0x" + "ab" * 32)
    assert (response.status_code, response.json()) == (404, {"detail": "Transferencia no indexada"})


def test_paso_5_cors(client):
    preflight = {"Access-Control-Request-Method": "GET"}
    page = client.options("/status", headers={"Origin": "http://localhost:5173", **preflight})
    assert page.headers.get("access-control-allow-origin") == "http://localhost:5173"
    other = client.options("/status", headers={"Origin": "https://evil.example", **preflight})
    assert other.status_code == 400
    assert "access-control-allow-origin" not in other.headers
