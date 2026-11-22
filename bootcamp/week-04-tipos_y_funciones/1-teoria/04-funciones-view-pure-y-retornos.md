# Teoría 04 — Funciones: view, pure y retornos

## 🎯 Objetivos

- Elegir la mutabilidad más estricta que admite cada función.
- Devolver varios valores y recogerlos en quien llama.
- Usar valores de retorno con nombre.
- Documentar funciones con NatSpec.

---

## 1. Qué problema resuelve

Una función se define por cuatro cosas: su nombre, sus parámetros, su visibilidad
(Teoría 03) y su **mutabilidad**, que es lo que promete hacer con el estado. Con eso, el
compilador comprueba que el cuerpo cumple la promesa, y quien la llama sabe si necesita
una transacción o le basta un `cast call`. Esta teoría completa la firma con los valores
que devuelve y con la documentación que la acompaña.

## 2. Mutabilidad: repaso y regla

La semana 03 presentó las tres clases:

| Mutabilidad | Lee estado | Escribe estado | Se llama con |
| ----------- | ---------- | -------------- | ------------ |
| (ninguna) | ✅ | ✅ | `cast send` (transacción) |
| `view` | ✅ | ❌ | `cast call` |
| `pure` | ❌ | ❌ | `cast call` |

**La regla**: declara siempre la más estricta posible. El compilador te avisa si podrías
apretar más (`Warning (2018): Function state mutability can be restricted to view`) y te
para si prometes algo que no cumples (`Error (8961)` y `Error (2527)`, semana 03).

Una función `view` o `pure` puede llamar a otras funciones, pero solo a las que cumplan
su misma promesa: una `pure` puede llamar a otra `pure`; una `view`, a `view` o `pure`.

`view` y `pure` son gratis **solo si se llaman desde fuera** con `eth_call`. Si una función
que escribe las llama dentro de una transacción, su gas se paga como el de cualquier otro
código.

## 3. Varios valores de retorno

Una función puede devolver varios valores, separados por comas:

```solidity
function summary() external view returns (uint256, address) {
    return (total, lastWriter);
}
```

Quien llama los recoge en el mismo orden (**desestructurar**):

```solidity
(uint256 currentTotal, address writer) = ledger.summary();
```

Con `cast`, se ponen los tipos de retorno entre paréntesis:

```bash
cast call "$LEDGER" "summary()(uint256,address)"
```

```
198
0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
```

Sin los tipos de retorno, `cast` imprime la respuesta en crudo: los dos valores
codificados con la ABI, uno detrás de otro, en palabras de 32 bytes.

## 4. Retornos con nombre

Los valores de retorno pueden llevar nombre. Se comportan como variables locales que
empiezan a cero y se devuelven solas al terminar la función:

```solidity
function preview(uint256 amount) external pure returns (uint256 net, uint256 fee) {
    fee = _fee(amount);
    net = amount - fee;
}
```

```bash
cast call "$LEDGER" "preview(uint256)(uint256,uint256)" 500
```

```
495
5
```

Los nombres también quedan en la ABI: quien lee la interfaz sabe qué significa cada valor
sin mirar el código. Úsalos cuando devuelves más de un valor del mismo tipo: así no se
confunde `net` con `fee`.

## 5. NatSpec: documentar para quien llama

**NatSpec** (*Ethereum Natural Language Specification Format*) es el formato de
comentarios de documentación de Solidity. Va en líneas `///` justo encima de la función:

```solidity
/// @notice Comisión que se descuenta al sumar `amount`.
/// @param amount Importe bruto, en la unidad mínima.
/// @return La comisión, redondeada hacia abajo.
function quoteFee(uint256 amount) external pure returns (uint256) {
    return _fee(amount);
}
```

| Etiqueta | Para quién | Qué dice |
| -------- | ---------- | -------- |
| `@notice` | Quien usa el contrato | Qué hace la función, en lenguaje llano |
| `@dev` | Quien mantiene el código | Detalles de implementación |
| `@param` | Ambos | Qué es cada parámetro |
| `@return` | Ambos | Qué es cada valor devuelto |

El compilador la guarda en el artefacto, y las herramientas (exploradores de bloques,
carteras) la muestran:

```bash
forge inspect Ledger userdoc --json
```

```
{"version":1,"kind":"user","methods":{"quoteFee(uint256)":{"notice":"Comisión que se descuenta al sumar `amount`."}}}
```

Desde esta semana, toda función `external` o `public` del proyecto lleva al menos
`@notice`. Los comentarios `¿Qué? ¿Para qué? ¿Impacto?` siguen explicando las decisiones
del contrato; NatSpec describe la interfaz.

## 6. Antipatrones y riesgos

- **Dejar una función sin `view` cuando solo lee**: quien la ve en la ABI cree que cambia
  algo y la llamará con una transacción que cuesta gas.
- **Varios retornos del mismo tipo sin nombre**: `returns (uint256, uint256)` invita a
  desestructurarlos al revés. Ponles nombre.
- **NatSpec que no coincide con el código**: una documentación falsa es peor que ninguna.
  Revísala cada vez que cambies la función.
- **Confiar en que `view` es gratis dentro de una transacción**: el gas de su ejecución se
  paga igual.

## 7. Trucos

- `forge build` con warnings: el `Warning (2018)` te dice qué funciones pueden apretar su
  mutabilidad.
- `cast call ... "f()(tipo1,tipo2)"` decodifica varios valores, uno por línea.
- `forge inspect <Contrato> userdoc` y `devdoc` muestran la documentación tal como la verán
  otros.

## ✅ Checklist

- [ ] Elijo la mutabilidad más estricta para cada función.
- [ ] Devuelvo varios valores y los recojo desestructurando.
- [ ] Uso retornos con nombre cuando hay varios del mismo tipo.
- [ ] Documento una función con `@notice`, `@param` y `@return`.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 03 — Visibilidad](03-visibilidad.md) | **Teoría 04 — Funciones: view, pure y retornos** | [Teoría 05 — Constructor, constant e immutable →](05-constructor-constant-e-immutable.md) |
