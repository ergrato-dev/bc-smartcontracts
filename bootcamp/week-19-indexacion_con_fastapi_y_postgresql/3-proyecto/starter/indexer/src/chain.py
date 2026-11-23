"""Leer la cadena por JSON-RPC: lo del ejercicio 01, para cualquier evento. Viene resuelto."""

from dataclasses import dataclass
from typing import Any

import httpx2


class RpcError(Exception):
    """El nodo respondió con un error de JSON-RPC."""


@dataclass(frozen=True)
class Block:
    number: int
    hash: str
    parent_hash: str


def rpc(url: str, method: str, params: list[Any]) -> Any:
    response = httpx2.post(url, json={"jsonrpc": "2.0", "id": 1, "method": method, "params": params})
    response.raise_for_status()
    body = response.json()
    if "error" in body:
        raise RpcError(body["error"]["message"])
    return body["result"]


def head(url: str) -> int:
    return int(rpc(url, "eth_blockNumber", []), 16)


def get_block(url: str, number: int) -> Block | None:
    """El bloque `number`, o `None` si la cadena todavía no llega (o ya no llega) a ese número."""
    block = rpc(url, "eth_getBlockByNumber", [hex(number), False])
    if block is None:
        return None
    return Block(number=int(block["number"], 16), hash=block["hash"], parent_hash=block["parentHash"])


def get_logs(url: str, address: str, topics: list[str], from_block: int, to_block: int) -> list[dict[str, Any]]:
    """Los logs de `address` cuyo topic0 es uno de `topics`, en orden de bloque y de log."""
    return rpc(url, "eth_getLogs", [{
        "address": address,
        "topics": [topics],
        "fromBlock": hex(from_block),
        "toBlock": hex(to_block),
    }])
