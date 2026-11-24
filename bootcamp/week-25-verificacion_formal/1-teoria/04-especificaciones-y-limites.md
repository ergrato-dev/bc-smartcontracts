# Teoría 04 — Especificaciones y límites

## 🎯 Objetivos

- Escribir specs que digan lo que el protocolo promete, en las dos direcciones: lo que acepta y
  lo que rechaza.
- Reconocer una spec vacía, la que pasa sin probar nada, y saber cuándo lo detecta Halmos.
- Leer los avisos que dicen que una demostración no es completa: bucles y tiempo agotado.
- Elegir entre una llamada simbólica y una lista explícita de funciones.
- Desplegar con Halmos un protocolo que necesita direcciones calculadas.

## Una spec dice lo que se promete

Una spec de Halmos se escribe como una invariante de la semana 24: desde lo que el protocolo
**promete**, no desde lo que hace el código. "Solo quien tiene el certificado puede retirar" es
una promesa. Copiar en la spec el `if` de `retire` no es una spec: demuestra que el código es
igual a sí mismo.

Y como en el handler de la semana 24, la promesa tiene dos lados. "Solo quien tiene el
certificado" dice que los demás **no** pueden, y también que quien lo tiene **sí** puede:

```solidity
bool accepted;
vm.prank(caller);
try registry.retire(id) {
    accepted = true;
} catch {}
assertEq(accepted, caller == alice);
```

Un `assertEq` entre lo que pasó y lo que tenía que pasar cubre las dos direcciones a la vez: un
registro que deja retirar a cualquiera falla, y uno que no deja retirar a nadie, también.

## Specs vacías

Una spec **vacía** (o *vacuous*) pasa porque no comprueba nada: ninguna entrada llega a la
aserción. Halmos detecta el caso extremo, cuando **todos** los caminos revierten:

```solidity
function check_Vacuous(uint256 x) public pure {
    vm.assume(x > 10 && x < 5);
    assertEq(x, 0);
}
```

```text
WARNING  check_Vacuous(uint256): all paths have been reverted; the setup state
         or inputs may have been too restrictive.
[ERROR] check_Vacuous(uint256) (paths: 1, time: 0.01s, bounds: [])
```

Lo que no detecta es el caso parcial: que **algunos** caminos revierten justo donde estaba el
fallo. Pasa en el proyecto de esta semana. La spec "una cuenta sin roles no puede llamar a
`withdrawFees`" pasaba incluso sin `onlyRole`: el registro no tenía saldo, `withdrawFees`
revertía por `NothingToWithdraw`, y ese revert era un camino descartado. Con saldo en el `setUp`,
la misma spec mata ese fallo.

La herramienta para encontrar specs vacías es la de la semana 24: **mutantes**. Si metes un fallo
y la spec sigue en verde, no está mirando ahí.

## Cuándo un `PASS` no es una demostración

### Bucles

Cuando un bucle depende de un símbolo, Halmos lo sigue un número limitado de vueltas, 2 por
defecto, y avisa:

```solidity
function check_SumFormula(uint256 n) public pure {
    vm.assume(n <= 10);
    assertEq(sumTo(n), n * (n + 1) / 2);
}
```

```text
[PASS] check_SumFormula(uint256) (paths: 11, time: 0.17s, bounds: [])
WARNING  check_SumFormula(uint256): paths have not been fully explored due to
         the loop unrolling bound: 2
```

Es un `PASS` con letra pequeña: demostrado para `n` hasta 2, nada más. Con `--loop 11`, Halmos
sigue hasta 11 vueltas, cubre todos los `n` que deja el `assume` y el aviso desaparece:

```text
[PASS] check_SumFormula(uint256) (paths: 43, time: 0.42s, bounds: [])
```

Los bucles con un número fijo de vueltas, como `for (i = 0; i < 5; i++)`, no tienen este límite:
no dependen de ningún símbolo.

### Tiempo agotado

El solver resuelve bien sumas, restas, comparaciones y operaciones de bits. Con multiplicaciones
y divisiones **entre dos símbolos** (aritmética no lineal), puede no terminar. Con la configuración por
defecto de esta versión, Halmos se rinde a los 60 segundos:

```solidity
function check_feeCoversUsd(int256 answer) public {
    vm.assume(answer > 0);
    feed.updateAnswer(answer);
    uint256 fee = registry.registrationFee();
    assertGe(fee * uint256(answer), registry.usdFee() * 1e8);
}
```

```text
[TIMEOUT] check_feeCoversUsd(int256) (paths: 6, time: 60.59s, bounds: [])
```

Con yices y con z3, igual. `registrationFee` divide por el precio con `Math.mulDiv`: una división
de 512 bits por un símbolo. `TIMEOUT` cuenta como fallo en el resultado, y no es ni un fallo ni
una demostración. Hay tres salidas:

- **Estrechar la spec**: precios de un rango, o un precio fijo y la tasa simbólica.
- **Probarlo de otra forma**: tests con precios concretos y fuzz, como `RegistryV3.t.sol`.
- **Escribirlo en el informe**: "no se pudo demostrar", con el motivo.

Lo que no se hace es subir el tiempo hasta que pase "por si acaso".

## Llamadas simbólicas o lista explícita

`svm.createCalldata("Token")` genera una llamada a cada función de `Token` y, además, una llamada
con **cualquier otro selector**, para cubrir un `fallback`. Con un contrato pequeño, como el token
del ejercicio 03, es la forma más corta de decir "ninguna función".

Con un protocolo grande se complica:

- Con `createCalldata("RegistryV3")`, Halmos explora todas las funciones con todos sus argumentos.
  `multicall(bytes[])` y `registerBatch(string[])` reciben arrays de bytes simbólicos que
  multiplican los caminos. Medido sobre el proyecto: `[ERROR]` tras 16 429 caminos y 464 segundos.
- Con una interfaz que solo declara las funciones privilegiadas, el "cualquier otro selector"
  llega al resto de funciones del registro, que sí existen, y la spec falla con contraejemplos
  que no son fallos (una función `view` que sale bien).

La salida es una **lista explícita**, con un parámetro que elige la función:

```solidity
function check_strangerCannotAdmin(address caller, uint8 which, address a, uint256 x, uint256 y, bytes32 role)
    public
{
    vm.assume(caller != address(this));
    bytes memory data;
    if (which == 0) data = abi.encodeCall(registry.pause, ());
    else if (which == 1) data = abi.encodeCall(registry.unpause, ());
    // ...
    else data = abi.encodeCall(registry.revokeRole, (role, a));
    vm.prank(caller);
    (bool ok,) = address(registry).call(data);
    assertFalse(ok);
}
```

`which` es un símbolo: Halmos explora todas las ramas a la vez, y los argumentos son símbolos
también. La lista es tuya, y lo que no está en ella no se prueba: el informe la nombra.

## Direcciones que no son las de la EVM

Halmos no calcula la dirección de un contrato nuevo con la fórmula de la EVM (semana 10). Las
numera: `0xaaaa0001`, `0xaaaa0002`... con `CREATE`, y `0xbbbb0000`... con `CREATE2`. Para casi
todo da igual. Para tu protocolo no: `LoyaltyToken` y `Certificate` reciben la dirección del
registro en su constructor, antes de que exista, y el handler de la semana 24 la calcula con la
fórmula de `CREATE`. En Halmos, esa dirección no es la del proxy, y `initialize` revierte.

La salida es elegir la dirección y poner ahí el proxy:

```solidity
address proxy = address(0x5E6157A7);
loyalty = new LoyaltyToken(proxy);
certificate = new Certificate(IRegistry(proxy));
ERC1967Proxy model = new ERC1967Proxy(address(implementation), abi.encodeCall(Registry.version, ()));
vm.etch(proxy, address(model).code);
vm.store(proxy, IMPLEMENTATION_SLOT, bytes32(uint256(uint160(address(implementation)))));
Registry(proxy).initialize(CAPACITY, loyalty, certificate);
```

`vm.etch` copia el código de un proxy de verdad a la dirección elegida, y `vm.store` escribe la
implementación en el slot de ERC-1967 (semana 15), que es donde el proxy la busca. El proxy
modelo se crea con una llamada inofensiva (`version()`): el `ERC1967Proxy` de OpenZeppelin 5.7
revierte con `ERC1967ProxyUninitialized` si los datos están vacíos. Funciona igual en forge y en
Halmos, y el informe dice que el despliegue de la spec no es el del script.

## Qué técnica para qué

| Pregunta | Técnica |
| -------- | ------- |
| ¿Funciona este caso que conozco? | Test unitario |
| ¿Falla con alguna entrada rara de esta función? | Fuzz, y si importa, Halmos |
| ¿Se rompe algo tras muchas llamadas en cualquier orden? | Invariantes (semana 24) |
| ¿Se cumple esta regla para **cualquier** llamante, valor o argumento? | Halmos |
| ¿Se cumple este `assert` tras **cualquier** secuencia, en un contrato pequeño? | SMTChecker |
| ¿Atrapa mi suite los fallos que importan? | Mutantes |

Ninguna sustituye a las otras. Un protocolo serio tiene todas, y su informe dice qué cubre cada
una y qué no cubre ninguna.

## ⚠️ Riesgos

- **Specs que copian el código.** Demuestran que el código hace lo que hace. Escríbelas desde la
  promesa, como las invariantes.
- **Specs vacías a medias.** Halmos solo avisa cuando revierten todos los caminos. Los mutantes
  encuentran el resto.
- **`PASS` con aviso.** Un `PASS` con el aviso de bucles es una demostración parcial. Sube
  `--loop` o escribe el límite en el informe.
- **`TIMEOUT` escondido.** Un tiempo agotado no se arregla subiendo el tiempo hasta que pase: se
  estrecha la spec, se prueba de otra forma o se declara.
- **Un despliegue que no es el real.** Si el `setUp` usa `vm.etch` o direcciones elegidas, lo que
  se demuestra es sobre ese estado. El informe lo dice.

## 📝 Resumen

- Una spec dice lo que el protocolo promete, en las dos direcciones, y compara lo que pasó con lo
  que tenía que pasar.
- Halmos detecta la spec vacía del todo; la vacía a medias, solo los mutantes.
- Los avisos de bucles y los `TIMEOUT` dicen que la demostración no es completa.
- En protocolos grandes, una lista explícita de funciones es más clara que una llamada simbólica.
- Halmos numera las direcciones; un `setUp` con `vm.etch` y `vm.store` pone el proxy donde lo
  necesitas.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 03 — Halmos](03-halmos.md) | **Teoría 04 — Especificaciones y límites** | [Ejercicio 01 — SMTChecker →](../2-practicas/ejercicio-01-smtchecker/README.md) |
