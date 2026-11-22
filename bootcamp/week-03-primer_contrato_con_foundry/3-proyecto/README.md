# Proyecto — Contrato registro

> Tercera capa del protocolo de tu dominio: el primer contrato. Un **registro** del recurso
> principal que cuenta cuántos hay, asigna a cada uno un identificador y recuerda quién
> registró el último. Lo pruebas con `forge test` y lo despliegas en anvil desde la cuenta
> del protocolo.

**Duración estimada**: 4 h
**Prerrequisitos**: los tres ejercicios de la semana terminados y tu proyecto de la
semana 02 en `main`.

## Capa que se añade y por qué ahora

Hasta ahora tu protocolo era una cuenta que firma y paga. Desde esta semana tiene código
en la cadena: reglas que ejecutan todos los nodos y que nadie puede saltarse. Es poco
(contar y recordar), pero es la base sobre la que crecerá: la semana 04 le añade tipos y
constantes; la 05, reglas y permisos; la 06, los datos de cada recurso; la 07, eventos y
pagos.

**El dominio te lo asigna el instructor.** El starter habla de un recurso genérico: tú le
das el nombre del tuyo.

## Preparar la rama

**Dónde**: en tu terminal, en tu repositorio `bc-smartcontracts-<tu-dominio>`.

1. Parte de `main` actualizado y crea la rama de la semana:

   ```bash
   git switch main
   git pull
   git switch -c week-03
   ```

2. Copia el starter entero, con su `.gitignore`, en una carpeta `week-03/` (ajusta la
   ruta a donde clonaste el bootcamp):

   ```bash
   cp -r ../bc-smartcontracts/bootcamp/week-03-primer_contrato_con_foundry/3-proyecto/starter week-03
   ```

3. Entra al contenedor y mira el rojo:

   ```bash
   cd week-03
   docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
   forge test
   ```

**Verifica**: ocho líneas `[FAIL: TODO: ...]` (cada una con la función que falta) y
`0 tests passed, 8 failed, 0 skipped (8 total tests)`.

## Qué hay en el starter

| Archivo | Qué es |
| ------- | ------ |
| `foundry.toml` | Configuración del bootcamp. No lo cambies |
| `.gitignore` | Deja fuera de git `out/` y `cache/` |
| `src/Registry.sol` | El contrato, con cinco funciones `// TODO:` y una pista cada una |
| `test/Registry.t.sol` | Los 8 tests. **No lo modifiques**: comprueban propiedades (el primer identificador es 1, se suceden de uno en uno, se guarda quién llama), no los nombres de tu dominio |

## Requisitos

1. **Variables de estado**: `count` (`uint256`) con cuántos recursos hay y `latest`
   (`address`) con quién registró el último.
2. **`protocolName()`**: devuelve el nombre de tu protocolo, en inglés: el `PROTOCOL` de la
   semana 02.
3. **`resourceName()`**: devuelve el nombre del recurso principal de tu dominio, en inglés
   y en singular.
4. **`register()`**: suma 1 a `count`, guarda `msg.sender` en `latest` y devuelve el
   `count` nuevo. Ese número es el identificador del recurso: el primero es 1.
5. **`total()`** y **`lastRegistrant()`**: devuelven `count` y `latest`.
6. **Desplegado en anvil** desde la cuenta del protocolo (la de tu `INDEX`), con un
   recurso registrado.

## Cómo verificar

```bash
forge test
```

**Verifica**: ocho `[PASS]` y `8 tests passed, 0 failed, 0 skipped (8 total tests)`, sin
warnings.

Después, despliega y prueba en anvil. Con `anvil --silent &` en marcha, toma la clave de
la cuenta de tu `INDEX` (aquí `3`, la de los ejemplos):

```bash
PK=$(cast wallet private-key "test test test test test test test test test test test junk" 3)
forge create src/Registry.sol:Registry --private-key "$PK" --broadcast
```

```
Deployer: 0x90F79bf6EB2c4f870365E785982E1f101E93b906
Deployed to: 0x057ef64E23666F000b34aE31332854aCBd1c8544
Transaction hash: 0x271714b103bd6467c9d10ff28f0eaebd8fbeb085041a9779ff22669aa9f3e38b
```

Con tu `INDEX` verás otro `Deployer` y otra dirección; el hash cambia además con tus
nombres, que van dentro del bytecode. Registra un recurso y compruébalo:

```bash
REGISTRY=0x057ef64E23666F000b34aE31332854aCBd1c8544   # tu "Deployed to"
cast call "$REGISTRY" "protocolName()(string)"
cast send "$REGISTRY" "register()" --private-key "$PK"
cast call "$REGISTRY" "total()(uint256)"
cast call "$REGISTRY" "lastRegistrant()(address)"
```

`protocolName()` imprime tu nombre entre comillas (por ejemplo `"Book Lending"`), el
recibo de `register()` trae `status 1 (success)`, `total()` da `1` y `lastRegistrant()`,
la dirección de tu cuenta del protocolo.

## Ejemplos de adaptación

Tres dominios que el instructor **no** asigna, para que veas el tipo de cambio:

| Dominio | `protocolName()` | `resourceName()` | Qué representa `register()` |
| ------- | ---------------- | ---------------- | ---------------------------- |
| Biblioteca | `Book Lending` | `Book` | Alta de un libro en el catálogo |
| Tienda en línea | `Order Escrow` | `Order` | Apertura de un pedido |
| Cine | `Ticket Office` | `Screening` | Alta de una función de cine |

## Criterios de calidad (no automatizables)

- `protocolName()` coincide con el `PROTOCOL` de la semana 02 y `resourceName()` es el
  recurso central de tu dominio, no un detalle.
- Sin `// TODO:` restantes; comentarios en español, identificadores en inglés.
- Sabes explicar por qué `register()` necesita `cast send` y `total()` no, y qué pasaría si
  llamaras a `register()` con `cast call`.
- Sabes explicar el riesgo de esta versión: **cualquier cuenta** puede registrar. Se
  arregla en la semana 05.

## Entrega

```bash
git add week-03
git commit -m "feat(week-03): add resource registry contract"
git push -u origin week-03
```

Abre un pull request `week-03` → `main` en tu repositorio. En la descripción pega la
salida de `forge create` y de las cuatro llamadas de arriba.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 03 — Desplegar y llamar](../2-practicas/ejercicio-03-desplegar-y-llamar/README.md) | **Proyecto — Contrato registro** | [Rúbrica de evaluación →](../rubrica-evaluacion.md) |
