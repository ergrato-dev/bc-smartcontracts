# Proyecto — Ficha criptográfica

> Primera capa del protocolo de tu dominio: le das una **cuenta**, escribes su **ficha
> de presentación**, la **firmas** con esa cuenta y registras sus tres primeros hechos en
> una **cadena de hashes**. Todavía no hay contratos: hay identidad e integridad.

**Duración estimada**: 4 h
**Prerrequisitos**: los tres ejercicios de la semana terminados.

## Capa que se añade y por qué ahora

Un protocolo on-chain necesita, antes que nada, una cuenta que lo represente: la que
desplegará sus contratos desde la semana 03 y firmará sus operaciones. Y necesita que
cualquiera pueda comprobar que un dato publicado por el protocolo es auténtico y no se
alteró. Esta semana construyes las dos cosas con las herramientas que acabas de
aprender: derivación de claves, hashes, firmas y encadenamiento.

**El dominio te lo asigna el instructor.** El starter usa un recurso genérico `Item`:
tú lo cambias por el de tu dominio.

## Preparar tu repositorio

**Dónde**: en tu terminal, fuera del repositorio del bootcamp.

1. Crea en GitHub un repositorio vacío llamado `bc-smartcontracts-<tu-dominio>`.
2. Clónalo y crea la rama de la semana:

   ```bash
   git clone https://github.com/<tu-usuario>/bc-smartcontracts-<tu-dominio>.git
   cd bc-smartcontracts-<tu-dominio>
   git switch -c week-01
   ```

3. Copia el starter en una carpeta `week-01/` (ajusta la ruta a donde clonaste el bootcamp):

   ```bash
   mkdir week-01
   cp ../bc-smartcontracts/bootcamp/week-01-criptografia_y_blockchain/3-proyecto/starter/* week-01/
   ```

4. Entra al contenedor y mira el rojo:

   ```bash
   cd week-01
   docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
   bash test.sh
   ```

**Verifica**: siete `❌`, un `✅` (`INDEX está entre 3 y 9`) y
`1 de 8 tests correctos`.

## Qué hay en el starter

| Archivo | Qué es |
| ------- | ------ |
| `ficha.sh` | Datos de tu protocolo y siete funciones con `# TODO:` y una pista cada una |
| `test.sh` | Los 8 tests. **No lo modifiques**: comprueba propiedades (que la firma verifica, que la cadena enlaza), no valores fijos, así que vale para cualquier dominio |

Puedes ejecutar una función suelta con `bash ficha.sh <función>`, por ejemplo
`bash ficha.sh card_text`. `verify_card` recibe dos argumentos:
`bash ficha.sh verify_card "mensaje" 0xfirma...`.

## Requisitos

1. **Datos del dominio**: `PROTOCOL`, `RESOURCE` y `RULE` describen tu dominio, no
   `Item`. `INDEX` es un número entre 3 y 9 elegido por ti.
2. **`RECORDS`**: tres hechos de tu dominio en orden, en frases cortas.
3. **`account_address`** y **`private_key`**: la dirección y la clave del índice `INDEX`
   de la frase de prueba.
4. **`card_text`**: exactamente cuatro líneas, con este formato:

   ```
   Protocolo: <PROTOCOL>
   Recurso: <RESOURCE>
   Regla: <RULE>
   Cuenta: <dirección>
   ```

5. **`card_hash`** y **`card_signature`**: el keccak256 de la ficha y su firma con la
   clave del protocolo.
6. **`verify_card MENSAJE FIRMA`**: imprime `válida` o `inválida`.
7. **`ledger`**: los hashes de los tres `RECORDS` encadenados, uno por línea, empezando
   desde `cast hash-zero`.

## Cómo verificar

```bash
bash test.sh
```

**Verifica**: ocho `✅` y `8 de 8 tests correctos`.

Con los datos de ejemplo del starter (`Item`, `INDEX=3`), `bash ficha.sh card_text`
imprime:

```
Protocolo: Item Registry
Recurso: Item
Regla: Cada Item queda registrado una sola vez
Cuenta: 0x90F79bf6EB2c4f870365E785982E1f101E93b906
```

Con tus datos verás otros valores: es lo esperado.

## Ejemplos de adaptación

Tres dominios que el instructor **no** asigna, para que veas el tipo de cambio:

| Dominio | `PROTOCOL` | `RESOURCE` | `RULE` | Un registro |
| ------- | ---------- | ---------- | ------ | ----------- |
| Biblioteca | `Book Lending` | `Book` | `Un libro solo tiene un préstamo activo` | `Préstamo de Book 7 a socio 12` |
| Tienda en línea | `Order Escrow` | `Order` | `El pago se libera al confirmar la entrega` | `Pago de Order 3 retenido` |
| Cine | `Ticket Office` | `Ticket` | `Cada asiento se vende una vez por función` | `Venta de Ticket fila C asiento 4` |

## Criterios de calidad (no automatizables)

- Los datos y los registros describen **tu** dominio de forma concreta y coherente.
- Los nombres técnicos (`PROTOCOL`, valores de `RESOURCE`) en inglés; los textos que lee
  una persona (`RULE`, `RECORDS`), en español.
- No hay claves reales: solo la frase de prueba.
- Sabes explicar qué pasaría con `card_signature` si alguien cambia una letra de la
  ficha, y qué pasaría con `ledger` si alguien cambia el primer registro.

## Entrega

```bash
git add week-01
git commit -m "feat(week-01): add signed protocol card and hash ledger"
git push -u origin week-01
```

Abre un pull request `week-01` → `main` en tu repositorio.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 03 — Firmar y verificar](../2-practicas/ejercicio-03-firmar-y-verificar/README.md) | **Proyecto — Ficha criptográfica** | [Rúbrica de evaluación →](../rubrica-evaluacion.md) |
