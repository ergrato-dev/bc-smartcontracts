"""Las funciones del ejercicio 01, resueltas: leer bloques y transferencias por JSON-RPC."""

from dataclasses import dataclass
from typing import Any

import httpx2

# ¿Qué? topic0 del evento `Transfer(address,address,uint256)`: el keccak256 de su firma.
# ¿Para qué? Pedir al nodo solo los logs de ese evento. Sale de
#   `cast sig-event "Transfer(address,address,uint256)"`.
TRANSFER_TOPIC = "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"


class RpcError(Exception):
    """El nodo respondió con un error de JSON-RPC."""


@dataclass(frozen=True)
class Block:
    number: int
    hash: str
    parent_hash: str


@dataclass(frozen=True)
class Transfer:
    block_number: int
    block_hash: str
    tx_hash: str
    log_index: int
    sender: str
    recipient: str
    value: int


# Llamar a un método de JSON-RPC y devolver su `result`.
def rpc(url: str, method: str, params: list[Any]) -> Any:
    response = httpx2.post(url, json={"jsonrpc": "2.0", "id": 1, "method": method, "params": params})
    response.raise_for_status()
    body = response.json()
    if "error" in body:
        raise RpcError(body["error"]["message"])
    return body["result"]


# El bloque `number`, con su hash y el de su padre.
def get_block(url: str, number: int) -> Block:
    block = rpc(url, "eth_getBlockByNumber", [hex(number), False])
    return Block(number=int(block["number"], 16), hash=block["hash"], parent_hash=block["parentHash"])


# Los logs de `Transfer` del contrato `token` entre dos bloques, ambos incluidos.
def get_transfer_logs(url: str, token: str, from_block: int, to_block: int) -> list[dict[str, Any]]:
    return rpc(url, "eth_getLogs", [{
        "address": token,
        "topics": [TRANSFER_TOPIC],
        "fromBlock": hex(from_block),
        "toBlock": hex(to_block),
    }])


# Un log de `Transfer` convertido en datos de Python.
def decode_transfer(log: dict[str, Any]) -> Transfer:
    return Transfer(
        block_number=int(log["blockNumber"], 16),
        block_hash=log["blockHash"],
        tx_hash=log["transactionHash"],
        log_index=int(log["logIndex"], 16),
        sender="0x" + log["topics"][1][-40:],
        recipient="0x" + log["topics"][2][-40:],
        value=int(log["data"], 16),
    )


# Todas las transferencias entre dos bloques, pidiendo como mucho `chunk` bloques cada vez.
def fetch_transfers(url: str, token: str, from_block: int, to_block: int, chunk: int) -> list[Transfer]:
    transfers = []
    for start in range(from_block, to_block + 1, chunk):
        end = min(start + chunk - 1, to_block)
        transfers += [decode_transfer(log) for log in get_transfer_logs(url, token, start, end)]
    return transfers
