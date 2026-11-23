# Rúbrica de evaluación — Semana 21: Vulnerabilidades clásicas

## 📊 Distribución de evidencias

| Tipo | Peso | Instrumento |
| ---- | ---- | ----------- |
| Conocimiento 🧠 | 30 % | Cuestionario de autoevaluación (10 preguntas) |
| Desempeño 💪 | 40 % | Ejercicios 01, 02 y 03 |
| Producto 📦 | 30 % | Proyecto: ataques clásicos a tu protocolo |

**Nota mínima para aprobar**: 70 % en **cada** tipo de evidencia, no en el promedio.

---

## 🧠 Conocimiento (30 %)

Responde por escrito, sin mirar la teoría. Las respuestas están al final, plegadas.

| # | Pregunta | Puntos |
| - | -------- | ------ |
| 1 | ¿Qué hace la EVM con tu función mientras se ejecuta una llamada a otro contrato, y por qué eso permite una reentrancy? | 10 |
| 2 | Tu `withdraw` sigue checks-effects-interactions. ¿Por qué eso también para la reentrancy entre funciones, y para qué pondrías además `nonReentrant`? | 10 |
| 3 | ¿Qué es una reentrancy de solo lectura, quién pierde dinero con ella y qué ofrece OpenZeppelin para evitarla? | 10 |
| 4 | Alice firma una transacción a un contrato A, que llama a B. ¿Qué valen `msg.sender` y `tx.origin` en B, y cómo roba A a una cartera que autoriza con `tx.origin`? | 10 |
| 5 | Tienes un contrato detrás de un proxy. ¿Qué tres cosas haces para que nadie se quede con él por su inicializador? | 10 |
| 6 | ¿Por qué una denegación de servicio en un contrato puede ser permanente? Pon el ejemplo de la subasta y su arreglo. | 10 |
| 7 | Un reparto recorre un array que crece con cada usuario. ¿Qué pasa cuando hay muchos, y qué tres arreglos tienes? | 10 |
| 8 | ¿Por qué `address(this).balance` no sirve para decidir nada, aunque tu contrato no tenga `receive`? | 10 |
| 9 | Nombra tres operaciones que Solidity 0.8 **no** comprueba y di qué haces con cada una. | 10 |
| 10 | ¿Qué es un return bomb, quién paga su coste y cómo lo cierra tu registro sin perder qué error dio el hook? | 10 |

**Total**: 100 puntos → 30 % de la nota.

<details>
<summary>Respuestas</summary>

1. La pausa: ejecuta el código del otro contrato y, al terminar, sigue con la línea siguiente.
   Mientras tanto, el otro contrato puede llamar otra vez al tuyo. Si tu función ha decidido
   algo (pagar) pero no lo ha anotado (restar el saldo), la segunda entrada ve el estado viejo
   y vuelve a pagar.
2. Porque cuando se envía el ETH el saldo ya es 0: cualquier otra función que lo lea, como
   `transfer`, ve el valor final. `nonReentrant` no depende del orden: protege aunque mañana
   alguien escriba una función mal ordenada. El cerrojo es uno para todo el contrato y va en
   todas las funciones que comparten estado.
3. Otro protocolo lee un `view` tuyo (un precio, un total) mientras tu contrato está a mitad de
   una operación y recibe un número falso. Tú no pierdes nada; pierde quien confía en ese
   número, por ejemplo prestando de más. `nonReentrantView` hace que ese `view` revierta
   mientras el cerrojo está echado.
4. `msg.sender` es A; `tx.origin`, Alice. A es un cebo: Alice lo llama creyendo que reclama algo,
   y A llama a la cartera, que ve `tx.origin == owner` y obedece. Con `msg.sender`, la cartera
   vería a A y revertiría.
5. `initializer` en `initialize`, para que solo se ejecute una vez; `_disableInitializers()` en
   el constructor, para que nadie inicialice la implementación; y desplegar el proxy con la
   llamada a `initialize` dentro, para que nadie se adelante entre crear e inicializar.
6. Porque el código no cambia: una función que revierte siempre, revierte para siempre, y lo que
   depende de ella queda dentro. La subasta push devuelve el ETH al pujador anterior y revierte
   si falla; un contrato que rechaza ETH puja una vez y nadie puede superarlo. Arreglo: apuntar
   lo debido y que cada uno lo retire (pull).
7. El gas del bucle crece con el array hasta no caber en un bloque (30 millones en anvil): la
   función deja de poder ejecutarse, y si `join` es abierto, un atacante lo provoca. Arreglos:
   que cada uno reclame lo suyo, procesar por lotes con un índice guardado, o un máximo.
8. Porque se le puede meter ETH sin llamar a ninguna función: `selfdestruct` envía el saldo sin
   ejecutar `receive`, y una recompensa de bloque puede ir a cualquier dirección. Se lleva una
   cuenta propia que solo cambian tus funciones.
9. `unchecked` (solo con una comprobación justo encima), las conversiones a tipos más pequeños o
   de `int` a `uint` (`SafeCast`), la división entera que pierde decimales (multiplicar antes,
   `Math.mulDiv`), los desplazamientos y todo lo de `assembly`.
10. Un contrato llamado revierte con un motivo enorme. Quien llama lo copia a memoria y, si lo
    emite, paga 8 de gas por byte de log: lo paga quien hace la transacción, no el contrato
    malicioso. El registro emite solo los 4 primeros bytes, el selector del error, que dicen qué
    error fue.

</details>

---

## 💪 Desempeño (40 %)

| Ejercicio | Criterio | Puntos |
| --------- | -------- | ------ |
| 01 — Reentrancy | `forge test`: `7 passed` | 20 |
| | Explica por qué el paso 3 ya para el ataque del paso 4 y qué añade el paso 5 que el 3 no da | 10 |
| 02 — Control de acceso y `tx.origin` | `forge test`: `7 passed` | 15 |
| | Explica por qué `test_Paso5_OwnerSweeps` pasaba desde el principio y qué demuestra el test de Mallory que ese no | 10 |
| 03 — DoS y aritmética | `forge test`: `7 passed` | 15 |
| | Explica por qué el bloqueador no puede retirar en `Auction` y por qué eso no es un problema de la subasta | 15 |
| Todos | Sin tocar `test/` ni los contratos marcados como "no la arregles" | 15 |

**Total**: 100 puntos → 40 % de la nota.

---

## 📦 Producto (30 %)

| Criterio | Puntos |
| -------- | ------ |
| Carpeta `week-21/` sin `out/`, `cache/` ni `broadcast/` de anvil, y pull request `week-21` → `main` | 10 |
| `bash test.sh`: `8 passed` y `7 passed`, sin warnings | 30 |
| Cada atacante comprueba el efecto del ataque y tiene su comentario de qué intenta | 15 |
| `test_RevertWhen_StrangerCallsPrivileged` incluye todas las funciones privilegiadas de tu protocolo | 15 |
| En anvil: el alta con el return bomb antes y después de `PatchV3` | 10 |
| `audit/README.md`: revisión de las cinco clases en tu protocolo y H-01 con severidad justificada | 20 |

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
| [← Proyecto — Ataques clásicos a tu protocolo](3-proyecto/README.md) | **Rúbrica de evaluación** | [Ebooks gratuitos →](4-recursos/ebooks-free/README.md) |
