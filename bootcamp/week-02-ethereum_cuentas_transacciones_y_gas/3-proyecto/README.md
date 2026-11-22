# Proyecto — Primeras transacciones

> Segunda capa del protocolo de tu dominio: la cuenta del protocolo **paga** en ETH, y cada
> pago deja un **informe** con su nonce, su gas y su costo, leído del recibo. Todavía no hay
> contratos: hay movimiento de valor y la capacidad de comprobar qué pasó.

**Duración estimada**: 4 h
**Prerrequisitos**: los tres ejercicios de la semana terminados y tu proyecto de la
semana 01 en `main`.

## Capa que se añade y por qué ahora

En la semana 01 tu protocolo obtuvo una cuenta y una firma. Una cuenta que no envía
transacciones no hace nada: esta semana la pones a trabajar. Cada pago es una transacción
firmada que cambia el estado, consume gas y avanza el nonce, y tu script sabe leerlo del
recibo.

Es el mismo flujo que usarás desde la semana 03 para desplegar tu primer contrato y
llamarlo: firmar, enviar, esperar el recibo y comprobarlo.

**El dominio te lo asigna el instructor.** El starter usa un recurso genérico `Item`: tú
lo cambias por el de tu dominio.

## Preparar la rama

**Dónde**: en tu terminal, en tu repositorio `bc-smartcontracts-<tu-dominio>`.

1. Parte de `main` actualizado y crea la rama de la semana:

   ```bash
   git switch main
   git pull
   git switch -c week-02
   ```

2. Copia el starter en una carpeta `week-02/` (ajusta la ruta a donde clonaste el bootcamp):

   ```bash
   mkdir week-02
   cp ../bc-smartcontracts/bootcamp/week-02-ethereum_cuentas_transacciones_y_gas/3-proyecto/starter/* week-02/
   ```

3. Entra al contenedor y mira el rojo:

   ```bash
   cd week-02
   docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
   bash test.sh
   ```

**Verifica**: dos `✅` (`INDEX está entre 3 y 9` y `PAYMENTS tiene tres pagos válidos`,
que el starter ya cumple con sus datos de ejemplo), seis `❌` y `2 de 8 tests correctos`.

## Qué hay en el starter

| Archivo | Qué es |
| ------- | ------ |
| `transacciones.sh` | Datos de tu protocolo y siete funciones con `# TODO:` y una pista cada una |
| `test.sh` | Los 8 tests. **No lo modifiques**: comprueba propiedades (de qué cuenta sale cada pago, cuánto baja el saldo, que el informe coincide con el recibo), no valores fijos |

`test.sh` arranca su propio anvil en el puerto 8546, nuevo para cada test, con **5 ETH** por
cuenta en lugar de 10 000: así los saldos en wei caben en un entero de bash y la resta de
saldos es exacta. Para ejecutar una función suelta necesitas tu anvil en el 8545
(`anvil --silent &`):

```bash
bash transacciones.sh account_address
bash transacciones.sh pay 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720 0.3
bash transacciones.sh tx_report 0x...   # el hash que imprimió pay
```

## Requisitos

1. **Datos del dominio**: `PROTOCOL` con el nombre de tu protocolo e `INDEX` con **el mismo**
   índice que elegiste en la semana 01 (entre 3 y 9).
2. **`PAYMENTS`**: tres pagos de tu dominio, en orden, con el formato
   `"<índice> <ether> <concepto>"`: índice de la cuenta de anvil que recibe (0-9, distinto
   de `INDEX`), cantidad entre 0.01 y 1 ether y una frase corta en español.
3. **`account_address`** y **`private_key`**: las de tu semana 01.
4. **`recipient_address N`**: la dirección de la cuenta de anvil de índice `N`.
5. **`pay DIRECCIÓN ETHER`**: envía `ETHER` ether desde la cuenta del protocolo, espera al
   recibo e imprime **solo** el hash.
6. **`tx_cost HASH`**: el costo en wei (gas usado × precio efectivo).
7. **`tx_report HASH`**: exactamente cinco líneas:

   ```
   Hash: <hash>
   Nonce: <nonce>
   Gas usado: <gas usado>
   Precio efectivo: <precio> wei
   Costo: <costo> wei
   ```

8. **`run_payments`**: ejecuta `PAYMENTS` en orden con `pay` e imprime un hash por línea.

## Cómo verificar

```bash
bash test.sh
```

**Verifica**: ocho `✅` y `8 de 8 tests correctos`.

Con los datos de ejemplo del starter (`INDEX=3`) y un anvil recién arrancado, un pago de
0.3 ether a la cuenta 9 y su informe dan:

```
Hash: 0x4f5ae4e89027c1aba4c2e618318b5e45f36b19b77fc6d45c4242f40a1b87afbc
Nonce: 0
Gas usado: 21000
Precio efectivo: 1000000001 wei
Costo: 21000000021000 wei
```

Con tu `INDEX` verás otro hash: es lo esperado. El gas usado es 21 000 para cualquier
transferencia.

## Ejemplos de adaptación

Tres dominios que el instructor **no** asigna, para que veas el tipo de cambio:

| Dominio | `PROTOCOL` | Un pago de `PAYMENTS` |
| ------- | ---------- | --------------------- |
| Biblioteca | `Book Lending` | `"0 0.02 Devolución de la fianza del préstamo de Book 7"` |
| Tienda en línea | `Order Escrow` | `"1 0.5 Liberación del pago de Order 3 al vendedor"` |
| Cine | `Ticket Office` | `"2 0.08 Reembolso de Ticket fila C asiento 4"` |

## Criterios de calidad (no automatizables)

- Los pagos describen **tu** dominio y tienen sentido en ese orden.
- `PROTOCOL` en inglés; los conceptos, que lee una persona, en español.
- No hay claves reales: solo la frase de prueba de anvil.
- Sabes explicar por qué el saldo del protocolo baja más que la suma de los pagos, y qué
  pasaría con el tercer pago si el segundo se quedara atascado en el mempool.

## Entrega

```bash
git add week-02
git commit -m "feat(week-02): add protocol payments with receipt reports"
git push -u origin week-02
```

Abre un pull request `week-02` → `main` en tu repositorio.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 03 — Gas y nonce](../2-practicas/ejercicio-03-gas-y-nonce/README.md) | **Proyecto — Primeras transacciones** | [Rúbrica de evaluación →](../rubrica-evaluacion.md) |
