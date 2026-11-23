"""Tests del ejercicio 02. No los modifiques."""

import psycopg
import pytest

from chain import Block, Transfer, rpc
from conftest import ACCOUNT_0, ACCOUNT_1, ACCOUNT_2, ACCOUNT_5, ETHER, send_transfer
from store import balance_of, create_schema, rollback_reorg, save, sync

MAX_UINT256 = 2**256 - 1


@pytest.fixture
def db(conn):
    create_schema(conn)
    return conn


def count(conn, table):
    return conn.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]


def test_paso_1_tablas(conn):
    create_schema(conn)
    create_schema(conn)
    conn.execute("INSERT INTO blocks VALUES (1, '0xaa')")
    conn.execute("INSERT INTO transfers VALUES (1, 0, '0xbb', '0x01', '0x02', %s)", [MAX_UINT256])
    assert conn.execute("SELECT value FROM transfers").fetchone()[0] == MAX_UINT256
    with pytest.raises(psycopg.errors.ForeignKeyViolation):
        conn.execute("INSERT INTO transfers VALUES (2, 0, '0xcc', '0x01', '0x02', 1)")
    conn.execute("DELETE FROM blocks WHERE number = 1")
    assert count(conn, "transfers") == 0


def test_paso_2_guardar_dos_veces(db):
    block = Block(number=7, hash="0xaa", parent_hash="0x99")
    transfer = Transfer(7, "0xaa", "0xbb", 0, ACCOUNT_0, ACCOUNT_1, 5 * ETHER)
    save(db, [block], [transfer])
    save(db, [block], [transfer])
    assert (count(db, "blocks"), count(db, "transfers")) == (1, 1)


def test_paso_3_saldo(db):
    save(db, [Block(1, "0xaa", "0x99")], [
        Transfer(1, "0xaa", "0xbb", 0, ACCOUNT_0, ACCOUNT_1, 100 * ETHER),
        Transfer(1, "0xaa", "0xbb", 1, ACCOUNT_1, ACCOUNT_2, 30 * ETHER),
    ])
    assert balance_of(db, ACCOUNT_1) == 70 * ETHER
    assert balance_of(db, ACCOUNT_1.upper().replace("0X", "0x")) == 70 * ETHER
    assert balance_of(db, ACCOUNT_5) == 0
    assert balance_of(db, "x' OR '1'='1") == 0
    assert balance_of(db, "o'brien") == 0


def test_paso_4_sincronizar(db, url, token, monkeypatch):
    assert sync(db, url, token) == 3
    assert sync(db, url, token) == 0
    assert count(db, "blocks") == 3
    assert balance_of(db, ACCOUNT_1) == 100 * ETHER
    send_transfer(url, token, ACCOUNT_1, ACCOUNT_5, 10 * ETHER)
    assert sync(db, url, token) == 1
    assert balance_of(db, ACCOUNT_5) == 10 * ETHER

    send_transfer(url, token, ACCOUNT_1, ACCOUNT_5, 1 * ETHER)
    def blocks_then_crash(conn, blocks, transfers):
        save(conn, blocks, [])
        raise TimeoutError("se cortó a mitad de guardar")

    monkeypatch.setattr("store.save", blocks_then_crash)
    with pytest.raises(TimeoutError):
        sync(db, url, token)
    assert (count(db, "blocks"), count(db, "transfers")) == (4, 4)


def test_paso_5_reorg(db, url, token):
    sync(db, url, token)
    fork = rpc(url, "evm_snapshot", [])
    send_transfer(url, token, ACCOUNT_1, ACCOUNT_5, 10 * ETHER)
    sync(db, url, token)
    assert balance_of(db, ACCOUNT_5) == 10 * ETHER

    # Reorg: el bloque 4 que guardaste deja de existir y en su lugar entra otro.
    rpc(url, "evm_revert", [fork])
    send_transfer(url, token, ACCOUNT_2, ACCOUNT_5, 3 * ETHER)
    assert rollback_reorg(db, url) == 1
    assert rollback_reorg(db, url) == 0
    sync(db, url, token)
    assert balance_of(db, ACCOUNT_5) == 3 * ETHER
    assert balance_of(db, ACCOUNT_1) == 100 * ETHER
