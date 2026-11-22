# Rúbrica de evaluación — Semana 02: Ethereum, cuentas, transacciones y gas

## 📊 Distribución de evidencias

| Tipo | Peso | Instrumento |
| ---- | ---- | ----------- |
| Conocimiento 🧠 | 30 % | Cuestionario de autoevaluación (10 preguntas) |
| Desempeño 💪 | 40 % | Ejercicios 01, 02 y 03 |
| Producto 📦 | 30 % | Proyecto: primeras transacciones en tu repositorio |

**Nota mínima para aprobar**: 70 % en **cada** tipo de evidencia, no en el promedio.

---

## 🧠 Conocimiento (30 %)

Responde por escrito, sin mirar la teoría. Las respuestas están al final, plegadas.

| # | Pregunta | Puntos |
| - | -------- | ------ |
| 1 | Un bloque de Ethereum no guarda el estado, solo transacciones. ¿Cómo llegan entonces todos los nodos al mismo saldo para cada cuenta? | 10 |
| 2 | ¿Por qué un contrato no puede iniciar una transacción por sí solo y una EOA sí? | 10 |
| 3 | Un script calcula `0.1 + 0.2` ether en coma flotante antes de enviar. ¿Qué puede salir mal y cómo se evita? | 10 |
| 4 | `eth_getBalance` devuelve `"0x21e19e0c9bab2400000"` y no un número. ¿Por qué el protocolo manda los números como texto hexadecimal? | 10 |
| 5 | Una transacción no tiene campo `from`. ¿Cómo sabe el nodo quién la envía y por qué eso impide enviar en nombre de otro? | 10 |
| 6 | ¿Por qué puedes conocer el hash de una transacción antes de enviarla, pero no su `gasUsed`? | 10 |
| 7 | Sin nonce, ¿qué ataque sería posible con una transacción que ya está en la cadena? ¿Y qué protege el chain id que el nonce no protege? | 10 |
| 8 | Tu transacción de nonce 7 lleva una hora sin minarse y las de nonce 8 y 9 tampoco salen. ¿Por qué, y qué haces para desatascarlas? | 10 |
| 9 | Envías con `maxFeePerGas` 5 gwei y propina 2 gwei a un bloque con base fee 4 gwei. ¿Cuál es el precio efectivo, cuánto se quema y cuánto cobra quien construye el bloque, por unidad de gas? | 10 |
| 10 | ¿Por qué no se usa `cast send` para leer el resultado de un contrato, y qué diferencia hay con `cast call`? | 10 |

**Total**: 100 puntos → 30 % de la nota.

<details>
<summary>Respuestas</summary>

1. Todos parten del mismo estado (el del bloque génesis) y aplican las mismas
   transacciones en el mismo orden con la misma máquina determinista, la EVM. Mismo punto
   de partida y mismos pasos dan el mismo resultado.
2. Iniciar una transacción exige firmarla, y firmar exige una clave privada. Una EOA la
   tiene; un contrato no tiene clave: su dirección sale de quién lo creó. Un contrato solo
   actúa cuando una transacción iniciada por una EOA lo llama.
3. En coma flotante `0.1 + 0.2` da `0.30000000000000004`: al convertir a wei saldría una
   cantidad distinta de la pensada, o un número con decimales que no existe en la cadena.
   Se convierte cada cantidad a wei (enteros) y se opera con enteros.
4. Los saldos en wei superan el máximo entero exacto de los números de JSON en muchos
   lenguajes (en JavaScript, unos 9 × 10¹⁵). Como texto no se pierde ningún dígito.
5. Lo recupera de la firma (`r`, `s`, `yParity`) sobre los campos de la transacción. Una
   firma válida para una cuenta solo la puede producir su clave privada, así que sin la
   clave no hay transacción que se recupere a esa dirección.
6. El hash es el keccak256 de los bytes firmados, que ya existen antes de enviar. El
   `gasUsed` depende de lo que ocurra al ejecutarla en un bloque, y eso solo se sabe cuando
   se incluye (está en el recibo).
7. El ataque de repetición: copiar la transacción firmada y volver a enviarla, por ejemplo
   para repetir un pago. El chain id evita repetirla en **otra red**, donde la cuenta
   existe con otros nonces y el nonce por sí solo no basta.
8. El nodo solo ejecuta el nonce que toca: mientras la 7 no se mine, la 8 y la 9 esperan.
   Seguramente su tope es menor que la base fee actual. Se reemplaza: otra transacción con
   nonce 7 y precios más altos (la misma, para acelerarla, o 0 ETH a ti mismo, para
   cancelarla).
9. Precio efectivo = mínimo(5, 4 + 2) = 5 gwei. Se queman 4 gwei (la base fee) y quien
   construye el bloque cobra 1 gwei: la propina real es menor que los 2 ofrecidos porque
   el tope limita.
10. Una transacción sirve para cambiar estado: se firma, se mina, cuesta gas y su recibo no
    incluye lo que devuelve la función. `cast call` ejecuta la función en la copia local
    del nodo (`eth_call`) y devuelve el resultado, sin firmar, sin gas y sin cambiar nada.

</details>

---

## 💪 Desempeño (40 %)

| Ejercicio | Criterio | Puntos |
| --------- | -------- | ------ |
| 01 — Leer la cadena | `bash test.sh`: 6 de 6 | 20 |
| | Explica qué método JSON-RPC y qué conversión hay detrás de `cast balance` | 10 |
| 02 — Una transacción paso a paso | `bash test.sh`: 6 de 6 | 20 |
| | Explica por qué el saldo de la cuenta 0 no baja exactamente 1 ether | 10 |
| 03 — Gas y nonce | `bash test.sh`: 6 de 6 | 25 |
| | Calcula a mano el `875175000` del paso 3 y explica qué pasaría sin el envío de nonce 0 del paso 6 | 15 |

**Total**: 100 puntos → 40 % de la nota.

---

## 📦 Producto (30 %)

| Criterio | Puntos |
| -------- | ------ |
| Carpeta `week-02/` en tu repositorio y pull request `week-02` → `main` | 10 |
| `bash test.sh`: 8 de 8 tests en verde | 50 |
| `PAYMENTS` con tres pagos concretos y coherentes de tu dominio (no `Item`), mismo `INDEX` que en la semana 01 | 20 |
| Calidad: sin `# TODO:` restantes, nombres técnicos en inglés y textos en español, sin claves reales, mensaje de commit claro | 20 |

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
| [← Proyecto — Primeras transacciones](3-proyecto/README.md) | **Rúbrica de evaluación** | [Ebooks gratuitos →](4-recursos/ebooks-free/README.md) |
