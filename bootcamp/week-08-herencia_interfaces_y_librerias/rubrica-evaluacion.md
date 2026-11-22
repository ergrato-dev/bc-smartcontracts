# Rúbrica de evaluación — Semana 08: Herencia, interfaces y librerías

## 📊 Distribución de evidencias

| Tipo | Peso | Instrumento |
| ---- | ---- | ----------- |
| Conocimiento 🧠 | 30 % | Cuestionario de autoevaluación (10 preguntas) |
| Desempeño 💪 | 40 % | Ejercicios 01, 02 y 03 |
| Producto 📦 | 30 % | Proyecto: registro modular en tu repositorio |

**Nota mínima para aprobar**: 70 % en **cada** tipo de evidencia, no en el promedio.

---

## 🧠 Conocimiento (30 %)

Responde por escrito, sin mirar la teoría. Las respuestas están al final, plegadas.

| # | Pregunta | Puntos |
| - | -------- | ------ |
| 1 | `Counter is Owned, Capped` se despliega. ¿Cuántas direcciones hay en la cadena y por qué? | 10 |
| 2 | ¿Qué diferencia a `internal` de `private` cuando hay herencia? ¿`private` oculta el dato? | 10 |
| 3 | Un hijo sustituye `transferOwnership` y escribe `owner = newOwner` en vez de llamar a `super`. ¿Qué se pierde? | 10 |
| 4 | `contract Market is Fees, Limits`, los dos hijos de `Base`, y cada `layers()` llama a `super`. ¿Qué devuelve `Market.layers()` y por qué? | 10 |
| 5 | ¿Qué hace que un contrato tenga que ser `abstract`? Da dos casos. | 10 |
| 6 | En el patrón de plantilla, ¿por qué la plantilla no es `virtual` y el hook sí? | 10 |
| 7 | ¿Qué puede y qué no puede declarar una interfaz? | 10 |
| 8 | ¿Cómo se calcula `type(I).interfaceId`? ¿Qué te garantiza que `supportsInterface` devuelva `true`? | 10 |
| 9 | ¿Por qué una librería con funciones `internal` no tiene dirección propia? ¿Cómo modifica el storage del contrato que la usa? | 10 |
| 10 | Con importes en wei, ¿por qué `amount * rate / 10000` y no `amount / 10000 * rate`? | 10 |

**Total**: 100 puntos → 30 % de la nota.

<details>
<summary>Respuestas</summary>

1. Una. El compilador copia en `Counter` el código de sus padres: el bytecode desplegado
   lo lleva todo. Ni `Owned` ni `Capped` existen solos en la cadena.
2. Las dos impiden llamar desde fuera, pero `internal` lo ve el hijo y `private` no.
   `private` no oculta nada: el dato está en el storage y `cast storage` lo lee.
3. Las comprobaciones del padre que no estaban en su cuerpo, como el `onlyOwner` de la
   firma. Cualquiera puede quedarse con el contrato. Con `super` se ejecuta la versión del
   padre entera.
4. `"Market > Limits > Fees > Base"`. Solidity ordena la jerarquía en una fila leyendo la
   lista `is` de derecha a izquierda; `super` es el siguiente de la fila, así que el `super`
   de `Limits` es `Fees` aunque `Limits` no herede de `Fees`. `Base` va una vez, al final.
5. Tener una función sin cuerpo (propia o heredada de un padre o de una interfaz, sin
   completar) o no dar argumentos al constructor de un padre que los pide. También se
   puede marcar a propósito para que nadie lo despliegue solo.
6. La plantilla fija los pasos que nadie debe saltarse (comprobaciones, eventos, cuentas).
   Si fuera `virtual`, un hijo podría sustituirla entera. El hook es la única pieza que
   cambia de un hijo a otro.
7. Puede declarar funciones `external` sin cuerpo, eventos, errores, structs y enums, y
   heredar de otras interfaces. No puede tener variables de estado, constructor,
   modificadores ni funciones con cuerpo.
8. Es el XOR de los selectores de sus funciones, sin las heredadas. `true` solo dice que
   el contrato **promete** cumplir la interfaz; cualquiera puede devolver `true`, así que
   no garantiza el comportamiento ni que sea de fiar.
9. Sus funciones `internal` se copian en el contrato al compilar, como la herencia: no se
   despliega nada aparte. Para el storage recibe una referencia (`Data storage self`) a
   una variable del contrato y la modifica a través de ella.
10. La división entera redondea hacia abajo. Dividir primero tira los decimales antes de
    multiplicar: con 999 wei y 2 500 bps, `999 / 10000` es 0 y el resultado es 0 en vez de
    249. Multiplicando primero solo se pierde lo de la última división.

</details>

---

## 💪 Desempeño (40 %)

| Ejercicio | Criterio | Puntos |
| --------- | -------- | ------ |
| 01 — Herencia | `forge test`: 4 de 4 sin warnings | 15 |
| | Explica por qué copiar el cuerpo de `Owned` en vez de `super` deja que alice se quede con la taquilla, y la fila de `Ticketing` con los dos órdenes | 15 |
| 02 — Interfaces | `forge test`: 5 de 5 sin warnings | 15 |
| | Explica por qué el 0 se comprueba en la plantilla y qué riesgo tiene que `Converter` acepte `HalfFeed` | 15 |
| 03 — Librerías | `forge test`: 5 de 5 sin warnings | 20 |
| | Explica cuánto se pierde con `amount / MAX * rate` y por qué el bote es el resto | 20 |

**Total**: 100 puntos → 40 % de la nota.

---

## 📦 Producto (30 %)

| Criterio | Puntos |
| -------- | ------ |
| Carpeta `week-08/` en tu repositorio, sin `out/` ni `cache/`, y pull request `week-08` → `main` | 10 |
| `forge test`: 44 de 44 tests en verde, sin warnings | 40 |
| Desplegado en anvil desde la cuenta de tu `INDEX`, con la salida de `forge create`, las consultas de `supportsInterface` y un error de cada pieza en el pull request | 15 |
| `Registry is IERC165, IRegistry, Openable` sin nada repetido; `Owned`, `Openable` y `LabelLib` no dependen de `Registry` | 15 |
| NatSpec: `@inheritdoc` en lo que implementa una interfaz y `@notice`/`@param` en el resto de funciones `external` | 5 |
| Calidad: sin `// TODO:` restantes, comentarios ¿Qué? ¿Para qué? ¿Impacto? en cada pieza, identificadores en inglés y comentarios en español, mensaje de commit claro | 15 |

**Total**: 100 puntos → 30 % de la nota.

---

## 🏅 Bandas

| Banda | Rango |
| ----- | ----- |
| Sobresaliente | 90-100 |
| Notable | 80-89 |
| Aprobado | 70-79 |
| No aprobado | < 70 en alguna evidencia |

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Proyecto — Registro modular](3-proyecto/README.md) | **Rúbrica de evaluación** | [Ebooks gratuitos →](4-recursos/ebooks-free/README.md) |
