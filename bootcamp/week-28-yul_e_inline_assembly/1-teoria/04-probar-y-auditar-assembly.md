# Teoría 04 — Probar y auditar assembly

## 🎯 Objetivos

- Explicar por qué un bloque de assembly necesita más pruebas que el mismo código en Solidity.
- Escribir un test diferencial: el assembly contra una referencia en Solidity, con fuzzing.
- Demostrar con Halmos que una función en assembly hace lo mismo que su referencia.
- Saber qué ven y qué no ven Slither y `forge lint` dentro de un bloque de assembly.
- Revisar un bloque de assembly con una lista fija de preguntas.

## Qué problema resuelve

Las teorías 01 a 03 acaban con la misma frase: lo que no escribes, no se hace. Desbordamientos,
direcciones sin código, `ok` sin mirar, returndata corta, puntero de memoria libre, bits sucios.
En Solidity, solc hace cada una de esas comprobaciones en cada línea, y lleva años de auditorías
encima. En assembly las haces tú, y nadie te avisa si olvidas una.

Encima, las herramientas de la fase 5 ven menos. Slither y `forge lint` analizan Solidity; un
bloque de assembly es, para ellos, casi una caja negra. Las invariantes y Halmos sí ejecutan el
bytecode, así que siguen sirviendo, pero solo si les preguntas lo correcto.

La respuesta es la de toda la fase 5, aplicada con más rigor: cada bloque de assembly lleva una
**referencia** (lo que haría Solidity) y pruebas que comparan el bloque con ella.

## Cómo funciona

### La referencia

Antes de escribir assembly, escribe la función en Solidity. Esa versión es la **especificación**:
lenta o cara, pero clara, y con las comprobaciones de solc. El assembly tiene que dar lo mismo
para **toda** entrada, incluidos los bordes: cero, el máximo, negativos, datos vacíos, datos de
1 a 3 bytes, datos enormes.

Una prueba que compara dos implementaciones de lo mismo se llama **test diferencial**
(*differential testing*). No dice si la referencia es correcta; dice si las dos coinciden, y eso
es justo lo que añade el assembly.

### Tres niveles de comparación

| Nivel | Herramienta | Qué da |
| ----- | ----------- | ------ |
| Casos escritos a mano | `forge test` | Los bordes que conoces: `max + 1`, el array vacío, el revert de 3 bytes |
| Entradas al azar | Fuzzing de forge (semana 09) | Cientos de entradas por ejecución, más los valores límite que forge prueba solo |
| Todas las entradas | Halmos (semana 25) | Una demostración, dentro de sus límites: bucles acotados y sin llamadas externas complejas |

Y un cuarto, que comprueba los otros tres: **mutantes** (semana 24). Si cambias una línea del
assembly y ninguna prueba falla, esa línea no está probada.

## Cómo se escribe

### Un test diferencial con fuzzing

Del ejercicio 01: `addChecked` en assembly contra `a + b` de Solidity, que revierte con
`Panic(0x11)` si se desborda.

```solidity
function testFuzz_Paso2_AddCheckedLikeSolidity(uint256 a, uint256 b) public {
    uint256 wrapped;
    unchecked {
        wrapped = a + b;
    }
    if (wrapped < a) {
        vm.expectRevert(stdError.arithmeticError);
        math.addChecked(a, b);
    } else {
        assertEq(math.addChecked(a, b), wrapped);
    }
}
```

Las dos ramas importan: con desbordamiento, el **mismo error** que Solidity (`stdError.arithmeticError`
es `Panic(0x11)` codificado); sin él, el mismo número. Un assembly que revierte con `revert(0, 0)`
pasaría la rama de los números y fallaría la del error.

Cuando el resultado es un evento, la referencia es una función del test que dice qué tendría que
emitirse. Del proyecto de esta semana:

```solidity
function _expectedReason(bytes memory data) internal pure returns (bytes memory) {
    return data.length < 4 ? bytes("") : abi.encodePacked(bytes4(data));
}

function testFuzz_FailedHookEmitsSelector(bytes memory data) public {
    _setHook(address(new RevertDataHook(data)));
    uint256 fee = registry.registrationFee();

    vm.expectEmit(address(registry));
    emit Registry.HookFailed(1, _expectedReason(data));
    vm.prank(alice);
    registry.register{value: fee}("uno");
}
```

`RevertDataHook` revierte con los bytes exactos de `data`, con `revert(p, n)` en assembly: también
con 1, 2 o 3 bytes, que ningún `revert` de Solidity produce y que son justo los que rompen un
`returndatacopy(0, 0, 4)` sin comprobar.

### Una demostración con Halmos

Con Halmos, la misma comparación vale para **todos** los valores. En el starter resuelto del
ejercicio 01, en `test/MathAsmSpec.t.sol`:

```solidity
function check_AddCheckedLikeSolidity(uint256 a, uint256 b) public view {
    try math.addChecked(a, b) returns (uint256 c) {
        assertEq(c, a + b);
    } catch {
        unchecked {
            assertLt(a + b, a);
        }
    }
}

function check_SignLikeSolidity(int256 x) public view {
    assertEq(math.sign(x), x > 0 ? int256(1) : x < 0 ? -1 : int256(0));
}
```

Halmos necesita en `foundry.toml` `dynamic_test_linking = false` y `ast = true` (semana 25):
añádelos al del ejercicio 01. Ese `foundry.toml` ya trae `lint_on_build = false`; sin él,
`Counter.yul` hace fallar la compilación con `post-build lint step failed`, porque el linter solo
entiende Solidity. En el contenedor:

```bash
halmos --no-status --match-contract MathAsmSpec
```

```text
Running 2 tests for test/MathAsmSpec.t.sol:MathAsmSpec
[PASS] check_AddCheckedLikeSolidity(uint256,uint256) (paths: 2, time: 0.01s, bounds: [])
[PASS] check_SignLikeSolidity(int256) (paths: 3, time: 0.01s, bounds: [])
Symbolic test result: 2 passed; 0 failed; time: 0.04s
```

`paths: 2` en la suma: con desbordamiento y sin él. `paths: 3` en el signo: positivo, cero y
negativo. Para `sum`, con un bucle sobre un array de longitud simbólica, Halmos solo prueba hasta
la longitud que le digas (`--loop`): la demostración tiene un límite, y se escribe.

### Lo que ven las herramientas

**Slither** tiene un detector solo para esto, `assembly`, que lista cada bloque. En el starter
resuelto del ejercicio 01, sin `Counter.yul` (con él, Slither falla con `KeyError: 'ast'`):

```bash
slither . --detect assembly
```

```text
MathAsm.addChecked(uint256,uint256) (src/MathAsm.sol#19-31) uses assembly
	- INLINE ASM (src/MathAsm.sol#21-30)
```

Es informativo: dice dónde mirar, no qué está mal. La configuración del proyecto excluye los
informativos (`exclude_informational`), así que en `test.sh` no aparece. Los demás detectores
apenas entran en los bloques. El mismo pago sin mirar si salió bien, en Solidity y en assembly:

```solidity
function payAsm(address to, uint256 amount) external {
    assembly {
        pop(call(gas(), to, amount, 0, 0, 0, 0))
    }
}

function paySol(address to, uint256 amount) external {
    to.call{value: amount}("");
}
```

```bash
slither .
```

```text
Pay.paySol(address,uint256) (src/Bad.sol#11-13) sends eth to arbitrary user
Pay.paySol(address,uint256) (src/Bad.sol#11-13) ignores return value by to.call{value: amount}() (src/Bad.sol#12)
Pay.payAsm(address,uint256) (src/Bad.sol#5-9) uses assembly
```

`paySol` da dos hallazgos, `arbitrary-send-eth` y `unchecked-lowlevel`. `payAsm`, que tiene los
dos mismos fallos, solo da "uses assembly".

**`forge lint`** ve las asignaciones de assembly, pero no siempre sabe si se ejecutan. Con una
asignación dentro de un `if` de Yul:

```solidity
bytes4 selector;
assembly {
    ok := call(gas(), target, 0, 0, 0, 0, 0)
    if and(iszero(ok), gt(returndatasize(), 3)) {
        returndatacopy(0, 0, 4)
        selector := mload(0)
    }
}
return abi.encodePacked(selector);
```

```text
warning[uninitialized-local]: local variable is read before being initialized
   ╭▸ src/Bad.sol:15:33
   │
15 │         return abi.encodePacked(selector);
   │                                 ━━━━━━━━
```

No es un fallo: una variable local de Solidity empieza a cero. Pero el aviso es razonable, porque
el valor depende de una rama que el linter no sigue. En el proyecto lo resuelves con una función
privada con las devoluciones con nombre, que también empiezan a cero y no dan el aviso.

### La revisión de un bloque

Cada bloque de assembly de un contrato que auditas pasa por las mismas preguntas:

| # | Pregunta | Dónde lo viste |
| - | -------- | -------------- |
| 1 | ¿Por qué assembly? ¿Qué no puede hacer Solidity aquí? | Teoría 01 |
| 2 | ¿Puede desbordar alguna cuenta? | Teoría 01 |
| 3 | ¿Respeta las reglas de memoria? Si dice `memory-safe`, ¿es verdad? | Teoría 02 |
| 4 | ¿Limpia los valores que salen hacia tipos de menos de 256 bits? | Teoría 02 |
| 5 | ¿Cada slot de storage sale de `.slot` o de una fórmula, no de un número a ojo? | Teoría 02 |
| 6 | ¿Mira el `ok` de cada `call`, `staticcall` y `create`? | Teoría 03 |
| 7 | ¿Qué pasa si el destino no tiene código? | Teoría 03 |
| 8 | ¿Cada `returndatacopy` está dentro de `returndatasize()`? ¿Copia solo lo que necesita? | Teoría 03 |
| 9 | ¿Cada selector y cada error tiene un test que lo compare con el de Solidity? | Teoría 03 |
| 10 | ¿Hay test diferencial, y algún mutante de cada línea muere? | Esta teoría |

El informe de tu proyecto lleva una tabla por bloque con las respuestas de la 3 y la 10.

## ⚠️ Antipatrones y riesgos

- **Assembly sin referencia.** Si no puedes escribir lo que el bloque tendría que hacer en
  Solidity, tampoco puedes probar que lo hace.
- **Fuzzing que no llega a los bordes.** Un `bytes` al azar casi nunca mide 1, 2 o 3 bytes; un
  `uint256` casi nunca es el máximo. Escribe esos casos a mano, como `test_ShortRevertsEmitEmptyReason`
  en el proyecto.
- **Fiarse del verde de Slither.** Cero hallazgos con assembly dentro no dice nada del assembly.
- **Assembly "por gas" sin medir.** El optimizador de solc ya hace mucho; el assembly a mano a
  veces gasta más. Medir es la semana 29; sin la medida, el riesgo no compensa.
- **Copiar assembly de otro proyecto.** Lo que es seguro en su contexto (su memoria, sus
  supuestos) puede no serlo en el tuyo. Si necesitas una pieza conocida, usa la biblioteca
  auditada entera, con su versión fijada.
- **Un mutante que no se puede matar, tomado por un hueco.** A veces el cambio no altera el
  comportamiento: es un **mutante equivalente**. En el proyecto, quitar la máscara del selector no
  cambia nada porque solc limpia antes de `abi.encodePacked`. Explica por qué es equivalente en el
  informe; no lo borres de la lista en silencio.

## 💡 Trucos

- Escribe la referencia en el mismo test, como función `internal pure`: la lees al lado del
  assembly que compruebas.
- Un hook, token o destino de prueba escrito con `revert(p, n)` o `return(p, n)` en assembly te
  da returndata que Solidity no sabe producir.
- `forge test --mt <test> -vvvv` enseña la traza con cada llamada, su gas y su returndata: la
  primera herramienta cuando un test diferencial falla.

## ✅ Checklist

- [ ] Sé qué es un test diferencial y por qué el assembly lo necesita.
- [ ] Sé escribir un fuzz test que compare el assembly con Solidity, también en sus errores.
- [ ] Sé escribir un `check_` de Halmos que compare dos implementaciones, y sus límites.
- [ ] Sé qué dicen y qué no dicen Slither y `forge lint` de un bloque de assembly.
- [ ] Sé las diez preguntas de la revisión de un bloque.
- [ ] Sé qué es un mutante equivalente.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 03 — Llamadas, errores y despliegues](03-llamadas-errores-y-despliegues.md) | **Teoría 04 — Probar y auditar assembly** | [Ejercicio 01 — Yul paso a paso →](../2-practicas/ejercicio-01-yul-paso-a-paso/README.md) |
