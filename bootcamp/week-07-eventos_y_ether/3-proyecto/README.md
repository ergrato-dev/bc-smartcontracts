# Proyecto — Registro con tasas y eventos

> Séptima capa del protocolo de tu dominio: registrar un recurso cuesta una tasa en ETH,
> cada cambio de estado deja un evento que una dApp puede leer, y el dueño retira lo
> recaudado de forma segura.

**Duración estimada**: 4 h
**Prerrequisitos**: los tres ejercicios de la semana terminados y tu proyecto de la
semana 06 en `main`.

## Capa que se añade y por qué ahora

Hasta la semana 06, el registro guardaba datos pero nadie fuera del contrato se enteraba
de lo que pasaba sin preguntarle uno a uno, y registrar era gratis. Ahora sabes emitir
eventos y mover ETH:

- **Eventos**: `ItemRegistered`, `ItemRetired`, `OpenChanged` y `FeesWithdrawn`. La semana
  17 los escuchará desde el frontend y la 19 los guardará en PostgreSQL.
- **Tasa**: `register` y `registerBatch` pasan a ser `payable` y exigen el importe
  exacto, `REGISTRATION_FEE` por recurso.
- **Retirada**: el dueño envía todo lo recaudado a la cuenta que elija con
  `withdrawFees`, en orden checks-effects-interactions.
- **Cuándo**: cada `Item` guarda `registeredAt`, el `block.timestamp` de su registro.

Retirar un recurso **no** devuelve la tasa. Y el registro no tiene `receive` ni
`fallback`: el ETH que no llega como tasa se rechaza.

**El dominio te lo asigna el instructor.** El starter habla de un recurso genérico: tú le
das el nombre del tuyo, el mismo de las semanas anteriores, y decides cuánto cuesta
registrar (`REGISTRATION_FEE`, mayor que 0).

## Preparar la rama

**Dónde**: en tu terminal, en tu repositorio `bc-smartcontracts-<tu-dominio>`.

1. Parte de `main` actualizado y crea la rama de la semana:

   ```bash
   git switch main
   git pull
   git switch -c week-07
   ```

2. Copia el starter entero, con su `.gitignore`, en una carpeta `week-07/` (ajusta la
   ruta a donde clonaste el bootcamp):

   ```bash
   cp -r ../bc-smartcontracts/bootcamp/week-07-eventos_y_ether/3-proyecto/starter week-07
   ```

3. Entra al contenedor y mira el rojo:

   ```bash
   cd week-07
   docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
   forge test
   ```

**Verifica**: `25 tests passed, 12 failed, 0 skipped (37 total tests)`. Los que pasan
prueban lo que ya hacía la semana 06, que el starter trae resuelto.

## Qué hay en el starter

| Archivo | Qué es |
| ------- | ------ |
| `foundry.toml` | Configuración del bootcamp. No lo cambies |
| `.gitignore` | Deja fuera de git `out/` y `cache/` |
| `src/Registry.sol` | El registro de la semana 06 resuelto, con las firmas ya `payable` y todas las declaraciones nuevas: `REGISTRATION_FEE`, el campo `registeredAt`, los cuatro eventos y los cuatro errores. Lo que falta lleva `// TODO:` |
| `test/Registry.t.sol` | Los 37 tests. **No lo modifiques**: comprueban las reglas, los eventos y los pagos, no los nombres de tu dominio |

Los tests usan `vm.deal` para dar ETH a las cuentas de prueba y `vm.expectEmit` para
comprobar los eventos, como los de los ejercicios.

## Requisitos

1. **Nombres**: `PROTOCOL_NAME` y `RESOURCE_NAME` de tu dominio.
2. **`REGISTRATION_FEE`**: la tasa por recurso de tu dominio, en wei y escrita con sufijo
   (`0.01 ether`, `500 gwei`...). Mayor que 0.
3. **`register(label)`**: `WrongFee(REGISTRATION_FEE, msg.value)` si no llega la tasa
   exacta, ni más ni menos.
4. **`registerBatch(labels)`**: `WrongFee(REGISTRATION_FEE * labels.length, msg.value)` si
   no llega una tasa por recurso. Comprueba cantidad, capacidad y tasa **antes** del bucle.
5. **`_register`** guarda `registeredAt = block.timestamp` y emite
   `ItemRegistered(id, msg.sender, label)`. Un lote emite un evento por recurso.
6. **`retire(id)`** emite `ItemRetired(id, msg.sender)`; **`setOpen(open)`** emite
   `OpenChanged(open)`.
7. **`withdrawFees(to)`**, solo el dueño: `ZeroAddress()` si `to` es `address(0)`;
   `NothingToWithdraw()` si el registro no tiene saldo; emite
   `FeesWithdrawn(to, cantidad)` y envía **todo** el saldo con `call`;
   `TransferFailed(to, cantidad)` si el envío falla.
8. **Sin `receive` ni `fallback`**: un envío de ETH sin función revierte.
9. **NatSpec** (`@notice`, y `@param` donde haya parámetros) en `withdrawFees`, igual que
   en el resto de funciones `external`.
10. **Desplegado en anvil** desde la cuenta de tu `INDEX`, con las llamadas de abajo.

`withdrawFees` usa `address(this).balance` y no una cuenta propia porque todo el ETH del
registro es del dueño: no hay depósitos de nadie más que proteger (teoría 05). Y paga con
*push* porque el único destino lo elige quien cobra.

## Cómo verificar

```bash
forge test
```

**Verifica**: treinta y siete `[PASS]` y
`37 tests passed, 0 failed, 0 skipped (37 total tests)`, sin warnings.

Después, despliega y prueba en anvil. Con `anvil --silent &` en marcha y la clave de tu
`INDEX` (aquí `3`, capacidad `50` y tasa `0.01 ether`, los de los ejemplos):

```bash
PK=$(cast wallet private-key "test test test test test test test test test test test junk" 3)
forge create src/Registry.sol:Registry --private-key "$PK" --broadcast --constructor-args 50
```

```
Deployer: 0x90F79bf6EB2c4f870365E785982E1f101E93b906
Deployed to: 0x057ef64E23666F000b34aE31332854aCBd1c8544
Transaction hash: 0x83d7b8c15f0cc9eb5be384b90dfddcd993abb3ff83038e031ac7b1b17e444afa
```

Con anvil recién arrancado, la dirección es la de las semanas anteriores; el hash cambia
con tu código, tus nombres, tu tasa y tu capacidad.

Registra uno y un lote de dos, pagando la tasa con `--value` (ajusta los importes a tu
tasa):

```bash
REGISTRY=0x057ef64E23666F000b34aE31332854aCBd1c8544   # tu "Deployed to"
cast send "$REGISTRY" "register(string)" "north" --value 0.01ether --private-key "$PK"
cast send "$REGISTRY" "registerBatch(string[])" '["east","west"]' --value 0.02ether --private-key "$PK"
cast call "$REGISTRY" "getItem(uint256)((uint256,address,uint8,uint256,string))" 2
cast balance "$REGISTRY" --ether
```

Dos recibos con `status 1 (success)` y:

```
(2, 0x90F79bf6EB2c4f870365E785982E1f101E93b906, 1, 1795344186 [1.795e9], "east")
0.030000000000000000
```

El cuarto campo es `registeredAt`: tu hora será otra. Lee los eventos del registro:

```bash
cast logs --address "$REGISTRY" "ItemRegistered(uint256 indexed,address indexed,string)"
```

Tres logs; al final de cada uno, los valores decodificados:

```
  decoded:
  	param0: 1
  	param1: 0x90F79bf6EB2c4f870365E785982E1f101E93b906
  	param2: "north"
```

(y los mismos con `2`, `"east"` y `3`, `"west"`). Ahora los tres errores. Registrar sin
pagar:

```bash
cast send "$REGISTRY" "register(string)" "south" --private-key "$PK"
```

```
Error: Failed to estimate gas: server returned an error response: error code 3: execution reverted: custom error 0x23b18f5f: ...: WrongFee(10000000000000000 [1e16], 0)
```

ETH sin función:

```bash
cast send "$REGISTRY" --value 1ether --private-key "$PK"
```

```
Error: Failed to estimate gas: server returned an error response: error code 3: execution reverted, data: "0x"
```

Otra cuenta (la del `INDEX` siguiente al tuyo) intenta llevarse las tasas:

```bash
PK_OTHER=$(cast wallet private-key "test test test test test test test test test test test junk" 4)
cast send "$REGISTRY" "withdrawFees(address)" 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65 --private-key "$PK_OTHER"
```

```
Error: Failed to estimate gas: server returned an error response: error code 3: execution reverted: custom error 0x245aecd3: ...: NotOwner(0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65)
```

Tú sí puedes. Envía las tasas a esa misma cuenta y mira los saldos:

```bash
cast send "$REGISTRY" "withdrawFees(address)" 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65 --private-key "$PK"
cast balance 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65
cast balance "$REGISTRY"
```

```
10000030000000000000000
0
```

La cuenta 4 tenía 10 000 ETH y recibió los 0,03 de las tasas; el registro queda a 0.

## Ejemplos de adaptación

Tres dominios que el instructor **no** asigna, para que veas el tipo de decisión:

| Dominio | Qué paga la tasa | Una tasa razonable en el ejemplo |
| ------- | ---------------- | -------------------------------- |
| Biblioteca | Dar de alta un libro en el fondo | `0.001 ether` |
| Tienda en línea | Publicar un producto en el catálogo | `0.005 ether` |
| Cine | Abrir una sala para programar sesiones | `0.05 ether` |

## Criterios de calidad (no automatizables)

- `withdrawFees` sigue el orden checks-effects-interactions: guardas, evento y `call` al
  final, con su resultado comprobado.
- Toda función que cambia estado emite su evento, y los eventos van después de los cambios
  que cuentan.
- `indexed` en lo que se busca (ids y cuentas), no en las etiquetas.
- Sabes explicar los riesgos que quedan: el dueño es una sola cuenta que se lleva todo el
  ETH (si pierde su clave, nadie más puede retirarlo; la semana 13 trae roles y multisig),
  y la tasa es fija en el código (cambiarla exige desplegar otro contrato; la semana 15
  trae contratos actualizables).

## Entrega

```bash
git add week-07
git commit -m "feat(week-07): charge a registration fee, emit events and withdraw fees"
git push -u origin week-07
```

Abre un pull request `week-07` → `main` en tu repositorio. En la descripción pega la
salida de `forge create` y de las llamadas de arriba, incluidos los tres errores.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 03 — Enviar ETH](../2-practicas/ejercicio-03-enviar-ether/README.md) | **Proyecto — Registro con tasas y eventos** | [Rúbrica de evaluación →](../rubrica-evaluacion.md) |
