# Teoría 04 — Cuándo no optimizar

## 🎯 Objetivos

- Nombrar lo que cada técnica de las teorías 02 y 03 puede romper, y el test que lo detecta.
- Comparar dos versiones sin que el dispatcher, la entrada o la configuración falseen el número.
- Seguir un proceso fijo: medir, cambiar una cosa, probar que no cambia el comportamiento, guardar
  el número y decidir.
- Rechazar una optimización por su precio en seguridad, en compatibilidad o en claridad, y
  dejarlo escrito.

## Qué problema resuelve

Las teorías 02 y 03 enseñan a gastar menos. Esta enseña a decir que no. Una optimización mueve un
coste: del gas a la seguridad (`unchecked`), del gas a la compatibilidad (reordenar un `struct` en
un proxy), del gas a la claridad (bitmaps, assembly). En una auditoría, el código "optimizado" es
el más difícil de revisar, y el sitio donde un fallo pasa desapercibido con más facilidad. El
ejercicio 03 es un contrato así: cinco optimizaciones, cinco fallos.

## Cómo funciona

### El precio de cada técnica

| Técnica | Lo que puede romper | El test que lo ve |
| ------- | ------------------- | ----------------- |
| Tipos pequeños para empaquetar | `uint96(x)` corta los bits altos sin revertir | Un test con el valor máximo del tipo más 1 |
| Reordenar o quitar campos | El layout de un contrato ya desplegado detrás de un proxy | El mapa de storage de la semana 27 |
| Cachear storage en una variable local | El valor se queda viejo si hay una llamada externa en medio | Un atacante que vuelve a entrar (semana 21) |
| `unchecked` | Un valor fuera de rango da la vuelta | Un test justo en el borde: saldo 1, retirar 2 |
| Bitmaps y desplazamientos | Una máscara mal calculada junta dos índices en un bit | Dos índices de la misma palabra y de palabras vecinas |
| Contadores pequeños | El bucle da la vuelta y no acaba | Un array de más de 255 elementos |
| `immutable` | Detrás de un proxy, el valor es el del constructor de la implementación, el mismo para todos los proxies | Un test que despliega el proxy e inicializa |
| Eventos en vez de storage | Ningún contrato puede leer el dato | — : es una decisión de diseño, no un fallo |
| Assembly | Todo lo que comprueba solc (semana 28) | Diferencial, Halmos y mutantes |

Ninguna de estas técnicas es mala. Cada una necesita **su** test, y ese test no existe hasta que
lo escribes.

### Comparar bien: el dispatcher

Cuando llamas a una función, el contrato compara el selector con los de sus funciones, en orden
(semana 27). Una función cuyo selector se encuentra antes gasta unas decenas menos. Si comparas
dos funciones del **mismo** contrato, esa diferencia se mezcla con la que quieres medir.

**Dónde**: en `src/Myths.sol` de un proyecto Foundry, sin optimizador:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

contract Myths {
    uint256 public hits;

    function greaterThanZero(uint256 x) external returns (bool) {
        if (x > 0) {
            hits++;
            return true;
        }
        return false;
    }

    function notZero(uint256 x) external returns (bool) {
        if (x != 0) {
            hits++;
            return true;
        }
        return false;
    }

    function firstPublic(uint256[] memory xs) public pure returns (uint256) {
        return xs[0];
    }

    function firstExternal(uint256[] memory xs) external pure returns (uint256) {
        return xs[0];
    }
}
```

Desde un test, `greaterThanZero(5)` y `notZero(5)` en dos instancias distintas, y las otras dos
con un array de 10 elementos, con `vm.lastFrameGas().gasTotalUsed`:

```text
  x > 0:  44114
  x != 0: 44089
  public:   3338
  external: 3404
```

Parece que `!= 0` ahorra 25 y que `public` ahorra 66. Pero si cambias `public` por `external` en
`firstPublic`, dejando las dos funciones idénticas, los números no se mueven: 3338 y 3404. La
diferencia es el selector: `firstPublic` es `0x1fcfbae9` y `firstExternal`, `0xb51397dd`, y el
dispatcher encuentra antes el primero. Lo mismo con `notZero` (`0x4b3b1d69`) y `greaterThanZero`
(`0x56c03e86`).

La comparación justa usa el **mismo** nombre en dos contratos:

```solidity
contract GreaterThan {
    uint256 public hits;

    function check(uint256 x) external {
        if (x > 0) hits++;
    }
}

contract NotEqual {
    uint256 public hits;

    function check(uint256 x) external {
        if (x != 0) hits++;
    }
}
```

| | Sin optimizador | Con optimizador (200) |
| - | --------------- | --------------------- |
| `x > 0` | 43 861 | 43 607 |
| `x != 0` | 43 858 | 43 607 |

3 de gas sin optimizador, 0 con él. Diferencias de decenas entre dos funciones distintas no
demuestran nada: aísla lo que comparas.

### Un proceso, siempre el mismo

1. **Mide la línea de base** con aislamiento, en la configuración que vas a desplegar, y guárdala:
   un snapshot con nombre o `forge snapshot` (teoría 01).
2. **Busca lo grande primero.** Cuenta los slots que escribe cada función de uso frecuente: un
   `SSTORE` de cero a otro valor que sobra vale más que todos los trucos de la teoría 03 juntos.
3. **Cambia una sola cosa** y vuelve a medir. Dos cambios a la vez no te dicen cuál ahorró.
4. **Prueba que no cambia el comportamiento**: los tests de siempre, las invariantes y las specs
   (semanas 24 y 25), y un test que mire el borde de lo que tocaste (la tabla de arriba). Si
   reescribiste una función, un test diferencial contra la versión vieja (semana 28).
5. **Guarda el número nuevo** y haz commit de él con el cambio. Con `FORGE_SNAPSHOT_CHECK=true`
   en CI, nadie cambia el gas sin verlo.
6. **Decide con números**: lo que ahorra cada usuario en cada llamada, lo que cuesta de más al
   desplegar, y lo que cuesta de más revisar el código.
7. **Escribe lo que no hiciste y por qué.** Una optimización rechazada en el informe ahorra a otro
   la misma discusión.

### Cuándo decir que no

- **El ahorro es menor que el ruido.** Unas decenas de gas en una función que se llama poco no
  pagan una línea más difícil de leer.
- **Rompe el layout de algo desplegado.** En un proxy con datos, reordenar un `struct` o cambiar
  el tipo de un campo no es una optimización: es una migración, con su riesgo (semana 15).
- **Quita una comprobación de seguridad.** Un `require` que "nunca falla" protege del caso que no
  previste nadie. Si de verdad no puede fallar, demuéstralo con Halmos (semana 25) antes de
  quitarlo.
- **Lo resuelve el compilador.** El contador de un bucle (teoría 03), las lecturas que el
  optimizador ya junta: escribirlo a mano solo añade código.
- **Necesita assembly para ahorrar poco.** El assembly vale para lo que Solidity no puede expresar
  (semana 28), no para ganar 30 de gas.

### Diez preguntas antes de fusionar una optimización

| # | Pregunta |
| - | -------- |
| 1 | ¿Cuánto ahorra, medido con aislamiento y en la configuración de despliegue, y en qué llamada? |
| 2 | ¿Cuántas veces se llama esa función, y quién la paga? |
| 3 | ¿Cambia el tamaño del bytecode, y cuánto cuesta eso en cada despliegue? |
| 4 | ¿Algún valor puede salirse de rango por un tipo más pequeño o por un `unchecked`? |
| 5 | ¿Hay una llamada externa entre una lectura cacheada y su escritura? |
| 6 | ¿Cambia el layout de storage de algo ya desplegado, o lo que significa un slot? |
| 7 | ¿Siguen en verde los tests, las invariantes, las specs y los mutantes de siempre? |
| 8 | ¿Hay un test nuevo en el borde de lo que tocaste? |
| 9 | ¿Hay un tope o un snapshot comprobado que proteja el ahorro? |
| 10 | ¿Está escrito, en el código o en el informe, lo que cuesta y lo que se descartó? |

## ⚠️ Antipatrones y riesgos

- **Optimizar antes de tener tests.** Sin tests, no sabes si la versión rápida hace lo mismo. Las
  optimizaciones del ejercicio 03 pasarían cualquier revisión sin sus tests de borde.
- **Medir en una configuración y desplegar en otra.** Otro `optimizer_runs`, `via_ir` u otra
  versión de solc es otro bytecode: otros números y, a veces, otros fallos.
- **Juzgar un truco por un artículo.** `++i`, `!= 0`, `external`: con solc 0.8.38, de 0 a 3 de gas
  por comparación o por vuelta de bucle. Mide con tu compilador antes de cambiar código que
  funciona.
- **Celebrar el porcentaje y no mirar el total.** Un 50 % de una función de 600 de gas son 300;
  un 5 % del alta del registro son más de 10 000.
- **Dejar el ahorro sin un test que lo proteja.** El próximo cambio puede deshacerlo sin que nadie
  lo note: el tope o el snapshot lo hacen visible.

## 💡 Trucos

- Para comparar dos versiones de una función, copia el contrato con otro nombre y cambia solo esa
  función: mismo selector, mismo dispatcher.
- Un mutante que solo cambia el gas (una lectura de más, por ejemplo) y no el comportamiento solo
  lo mata un tope o un snapshot comprobado. Es la forma de saber si tus números están protegidos:
  lo haces en el proyecto.
- Antes de una optimización grande, pregúntate cuántas veces al día se llama esa función y quién
  paga cada llamada.

## ✅ Checklist

- [ ] Sé lo que puede romper cada técnica de las teorías 02 y 03 y qué test lo detecta.
- [ ] Sé por qué dos funciones del mismo contrato no se comparan directamente, y cómo comparar.
- [ ] Sé seguir el proceso: línea de base, una cosa cada vez, tests, número guardado, decisión.
- [ ] Sé cuándo rechazar una optimización y por qué hay que dejarlo escrito.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 03 — El código y el compilador](03-el-codigo-y-el-compilador.md) | **Teoría 04 — Cuándo no optimizar** | [Ejercicio 01 — Storage barato →](../2-practicas/ejercicio-01-storage-barato/README.md) |
