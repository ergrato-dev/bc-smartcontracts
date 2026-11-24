# Ejercicio 03 — Medusa

> Al terminar habrás escrito un harness con una propiedad y una aserción, habrás encontrado con
> Medusa y con forge el mismo fallo de un vesting, y sabrás leer la secuencia y el informe de
> cobertura de Medusa.

**Duración estimada**: 1 h 30 min
**Prerrequisitos**: [Teoría 04 — Medusa](../../1-teoria/04-medusa.md) leída y el
[ejercicio 02](../ejercicio-02-handlers/README.md) terminado.

## Contexto

`Vesting` libera `TOTAL` tokens en línea recta durante `DURATION` segundos: a mitad de plazo, la
mitad. `release()` envía al beneficiario lo liberado que todavía no le ha enviado, y `released`
lleva la cuenta de lo enviado. Sus dos tests unitarios pasan: una liberación a mitad de plazo, y
otra a mitad y otra al final.

`test.sh` ejecuta `forge test`, compila sin warnings y lanza una campaña de Medusa con
`medusa.json`: 50 000 llamadas o 120 segundos, con 4 workers.

| Archivo | Qué es |
| ------- | ------ |
| `src/Vesting.sol` | El vesting. Paso 3 |
| `src/Token.sol` | ERC-20 de prueba. Hecho |
| `test/Vesting.t.sol` | Dos tests unitarios, en verde. **No lo modifiques** |
| `test/VestingProperties.sol` | El harness: despliega el vesting, con el harness como beneficiario. Pasos 1 y 2 |
| `test/VestingInvariants.t.sol` | La misma propiedad con forge. **No lo modifiques** |
| `medusa.json` | La configuración de Medusa. **No la modifiques** |
| `foundry.toml` | Con `dynamic_test_linking = false` para Medusa (teoría 04) |

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-24-fuzzing_de_invariantes/2-practicas/ejercicio-03-medusa/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
bash test.sh
```

**Verifica**: `test.sh` se para en `forge test`: `VestingTest` pasa y
`invariant_ReceivedWithinVested` falla con `TODO: Paso 1`. Medusa, solo:

```bash
medusa fuzz --config medusa.json --no-color
```

**Verifica**: compila en unos segundos (`Finished compiling targets`) y acaba con
`[FAILED] Property Test: VestingProperties.property_receivedWithinVested()`: una propiedad que
revierte también falla.

## Paso 1: La propiedad

**Por qué**: lo que promete un vesting es que el beneficiario nunca tiene más de lo liberado hasta
ahora. El harness es el beneficiario, así que su saldo es lo recibido.

```solidity
function property_receivedWithinVested() external view returns (bool) {
    return token.balanceOf(address(this)) <= vesting.vested(block.timestamp);
}
```

**Abre** `test/VestingProperties.sol` y, en `property_receivedWithinVested`, borra el `revert` y
descomenta la línea.

**Verifica**: `medusa fuzz --config medusa.json --no-color` falla con tres llamadas a `release`:

```text
⇾ [FAILED] Property Test: VestingProperties.property_receivedWithinVested()
[Call Sequence]
1) VestingProperties.release()() (block=13, time=13, gas=12500000, gasprice=0, value=0, sender=0x20000)
2) VestingProperties.release()() (block=13, time=13, gas=12500000, gasprice=0, value=0, sender=0x20000)
3) VestingProperties.release()() (block=13, time=13, gas=12500000, gasprice=0, value=0, sender=0x10000)
```

En la traza de la propiedad, `vested` devuelve `380517503805175038` y `balanceOf`, el doble. Las
tres llamadas son en el mismo segundo: no hace falta que pase el tiempo. `forge test` falla igual,
con una secuencia parecida. Tus números pueden ser otros.

## Paso 2: Una aserción

**Por qué**: la propiedad mira el resultado; una aserción mira cada acción. Lo enviado en una
llamada a `release` tiene que ser exactamente lo que sube `released`.

```solidity
function release() external {
    uint256 releasedBefore = vesting.released();
    uint256 amount = vesting.release();
    assert(vesting.released() == releasedBefore + amount);
}
```

**Abre** `VestingProperties.sol` y descomenta las dos líneas del paso 2 en `release`.

**Verifica**: Medusa sigue fallando, y para en el primer fallo que encuentra: la propiedad o
`[FAILED] Assertion Test: VestingProperties.release()`, que trae `[panic: assertion failed]` al
final de la traza. forge también ve el `assert`:

```text
Assertion Tests: 1 assertion bug(s) found
[FAIL: panic: assertion failed (0x01)] test/VestingProperties.sol:VestingProperties::release
```

## Paso 3: `released` acumula

**Por qué**: `release` guarda en `released` lo de **esta** llamada, no el total. Tras la segunda
llamada, `released` vuelve a ser 0 y la tercera envía otra vez todo lo liberado. Los tests
unitarios hacen dos llamadas, y con dos no se nota.

```solidity
released += amount;
```

**Abre** `src/Vesting.sol` y, en `release`, sustituye la línea `// <- Paso 3` por la de debajo.

**Verifica**: `bash test.sh` termina sin error. forge, en verde; Medusa:

```text
⇾ Transaction test limit reached, halting now...
⇾ [PASSED] Assertion Test: VestingProperties.release()
⇾ [PASSED] Assertion Test: VestingProperties.skipTime(uint256)
⇾ [PASSED] Property Test: VestingProperties.property_receivedWithinVested()
⇾ Test summary: 3 test(s) passed, 0 test(s) failed
⇾ html report(s) saved to: crytic-export/coverage/coverage_report.html
```

Abre `crytic-export/coverage/coverage_report.html` en tu navegador (está en la carpeta del
ejercicio, fuera del contenedor también). Busca `Vesting.sol`: ¿está marcada la rama
`if (timestamp >= START + DURATION) return TOTAL;`?

## Para pensar

- Medusa encontró el fallo sin mover el tiempo. Con `released += amount` hecho, cambia `vested`
  para que tras el plazo devuelva `TOTAL + 1`: ¿lo encuentra Medusa? ¿Y forge? ¿Qué acción usa
  cada uno para llegar al final del plazo?
- `skipTime` acota el salto a 30 días con `%`. ¿Por qué no `bound`, como en el ejercicio 02? (Pista:
  ¿de dónde sale `bound`?)
- ¿Qué propiedad añadirías para el final del plazo, cuando todo está liberado?

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 02 — Handlers](../ejercicio-02-handlers/README.md) | **Ejercicio 03 — Medusa** | [Proyecto — Invariantes de tu protocolo →](../../3-proyecto/README.md) |
