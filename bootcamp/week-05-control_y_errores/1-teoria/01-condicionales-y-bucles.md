# Teoría 01 — Condicionales y bucles

## 🎯 Objetivos

- Escribir `if`/`else`, el operador ternario y los bucles `for`, `while` y `do-while` en
  Solidity.
- Usar `break` y `continue`.
- Medir cuánto gas gasta un bucle y explicar por qué el número de vueltas es un riesgo.

---

## 1. Qué problema resuelve

Hasta la semana 04 cada función hacía siempre lo mismo: sumar, guardar, devolver. Un
protocolo real decide: si el registro está lleno, no admite más; si quien llama no es el
dueño, no puede cerrar. El **control de flujo** (las instrucciones que eligen qué código se
ejecuta y cuántas veces) es lo que permite decidir. Esta teoría repasa su sintaxis en
Solidity, que se parece a la de C, Java o JavaScript, y se detiene en lo que cambia: en un
contrato, cada vuelta de un bucle cuesta gas.

## 2. `if`, `else` y el ternario

```solidity
function fee(uint256 amount) external pure returns (uint256) {
    if (amount >= 1000) {
        return amount / 50;      // 2 %
    } else if (amount >= 100) {
        return amount / 100;     // 1 %
    } else {
        return 0;
    }
}
```

La condición tiene que ser un `bool`. Solidity no convierte números a booleanos:
`if (amount)` no compila,

```
Error (7407): Type uint256 is not implicitly convertible to expected type bool.
```

y hay que escribir `if (amount != 0)`.

El **operador ternario** (`condición ? valor_si_true : valor_si_false`) elige entre dos
valores en una sola expresión:

```solidity
function larger(uint256 a, uint256 b) external pure returns (uint256) {
    return a > b ? a : b;
}
```

Úsalo para elegir un valor, no para encadenar decisiones: tres ternarios anidados se leen
peor que un `if`.

## 3. Bucles

Los tres bucles de Solidity:

```solidity
// for: inicialización; condición; paso.
for (uint256 i = 0; i < 5; i++) {
    total += i;
}

// while: comprueba la condición antes de cada vuelta. Puede no entrar nunca.
while (n >= 10) {
    n /= 10;
}

// do-while: comprueba después. Entra al menos una vez.
do {
    digits++;
    n /= 10;
} while (n > 0);
```

Dentro de cualquiera de ellos:

- **`continue`** salta al final de la vuelta actual y pasa a la siguiente.
- **`break`** sale del bucle.

```solidity
for (uint256 i = 1; i <= n; i++) {
    if (i % 3 != 0) continue;   // solo los múltiplos de 3
    if (i > 30) break;          // y nunca más allá de 30
    total += i;
}
```

La variable del bucle (`i`) se declara como cualquier variable local: con su tipo y dentro
del `for`. Solo existe dentro del bucle.

## 4. Cada vuelta cuesta gas

En un lenguaje normal, un bucle de mil vueltas tarda unos microsegundos. En un contrato,
cada vuelta ejecuta instrucciones de la EVM y cada instrucción gasta gas. Esta función
suma de 1 a `n`:

```solidity
function sumTo(uint256 n) external pure returns (uint256 s) {
    for (uint256 i = 1; i <= n; i++) {
        s += i;
    }
}
```

Desplegada en anvil, `cast estimate` dice cuánto gas gastaría una transacción que la
llamara:

```bash
cast estimate "$CONTRACT" "sumTo(uint256)" 10
cast estimate "$CONTRACT" "sumTo(uint256)" 100
cast estimate "$CONTRACT" "sumTo(uint256)" 1000
```

```
25553
58313
385925
```

El gas crece con `n`. Recuerda de la semana 02 que cada bloque tiene un gas limit de bloque (30 000 000 en anvil): con
un `n` suficientemente grande, la transacción no cabe en ningún bloque y no se puede
ejecutar nunca.

## 5. Riesgos

- **Bucles sin límite**: si quien llama decide el número de vueltas (un parámetro, o una
  lista que crece con cada usuario, que verás en la semana 06), puede hacer que la función
  se quede sin gas. Si una función imprescindible (cerrar el registro, repartir fondos)
  depende de ese bucle, el contrato queda bloqueado. Es un ataque de **denegación de
  servicio** (DoS): impedir que otros usen el contrato. Pon siempre un máximo a las
  vueltas.
- **Una `view` no es gratis dentro de una transacción**: un bucle en una función `view` no
  cuesta nada con `cast call`, pero sí cuando otra función la llama dentro de una
  transacción.
- **Condiciones mal acotadas**: `i <= n` frente a `i < n` es la diferencia entre una vuelta
  de más y una de menos. Los tests de borde (0, 1, el máximo) lo detectan.

## 6. Trucos

- Antes de escribir un bucle, pregúntate si hay una fórmula: la suma de 1 a `n` es
  `n * (n + 1) / 2`, con coste fijo.
- Si un bucle necesita un límite, declara ese límite como `constant` (`MAX_BATCH`) y
  compruébalo al principio de la función. La teoría 02 enseña cómo.

## ✅ Checklist

- [ ] Escribo `if`/`else if`/`else` y sé por qué `if (amount)` no compila.
- [ ] Elijo entre `for`, `while` y `do-while` según si el bucle debe entrar al menos una vez.
- [ ] Uso `continue` y `break`.
- [ ] Explico por qué un bucle cuyo número de vueltas decide quien llama es un riesgo.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Semana 05 — Control de flujo y errores](../README.md) | **Teoría 01 — Condicionales y bucles** | [Teoría 02 — require y revert →](02-require-y-revert.md) |
