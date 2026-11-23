"""Tests de la API. No los modifiques."""

from chain import head
from conftest import ACCOUNT_1, ACCOUNT_2, register, retire
from indexer import sync


def test_status(client, db, url, registry):
    assert client.get("/status").json() == {"last_block": None}
    sync(db, url, registry)
    assert client.get("/status").json() == {"last_block": head(url)}


def test_list_items(client, db, url, registry):
    for sender, label in [(ACCOUNT_1, b"uno"), (ACCOUNT_2, b"dos"), (ACCOUNT_1, b"<script>tres</script>")]:
        register(url, registry, sender, label)
    retire(url, registry, ACCOUNT_1, 1)
    sync(db, url, registry)

    everything = client.get("/items").json()
    assert [(i["id"], i["active"]) for i in everything] == [("1", False), ("2", True), ("3", True)]
    assert everything[2]["label"] == "<script>tres</script>"
    mine = client.get("/items", params={"registrant": ACCOUNT_1.upper().replace("0X", "0x"), "active": True}).json()
    assert [i["id"] for i in mine] == ["3"]
    assert [i["id"] for i in client.get("/items", params={"limit": 1, "offset": 1}).json()] == ["2"]
    assert client.get("/items", params={"limit": 101}).status_code == 422
    assert client.get("/items", params={"registrant": "' OR 1=1 --"}).status_code == 422


def test_get_item(client, db, url, registry):
    register(url, registry, ACCOUNT_2, b"dos")
    sync(db, url, registry)
    item = client.get("/items/1").json()
    assert item == {"id": "1", "registrant": ACCOUNT_2, "label": "dos", "active": True,
                    "registered_block": item["registered_block"]}
    assert client.get("/items/2").json() == {"detail": "Recurso no indexado"}
    assert client.get("/items/2").status_code == 404
    assert client.get("/items/0").status_code == 422
    assert client.get("/items/abc").status_code == 422


def test_cors(client):
    preflight = {"Access-Control-Request-Method": "GET"}
    page = client.options("/items", headers={"Origin": "http://localhost:5173", **preflight})
    assert page.headers.get("access-control-allow-origin") == "http://localhost:5173"
    assert client.options("/items", headers={"Origin": "https://evil.example", **preflight}).status_code == 400
