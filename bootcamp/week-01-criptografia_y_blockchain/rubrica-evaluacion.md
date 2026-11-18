# Rúbrica de evaluación — Semana 01: Criptografía y blockchain

## 📊 Distribución de evidencias

| Tipo | Peso | Instrumento |
| ---- | ---- | ----------- |
| Conocimiento 🧠 | 30 % | Cuestionario de autoevaluación (10 preguntas) |
| Desempeño 💪 | 40 % | Ejercicios 01, 02 y 03 |
| Producto 📦 | 30 % | Proyecto: ficha criptográfica en tu repositorio |

**Nota mínima para aprobar**: 70 % en **cada** tipo de evidencia, no en el promedio.

---

## 🧠 Conocimiento (30 %)

Responde por escrito, sin mirar la teoría. Las respuestas están al final, plegadas.

| # | Pregunta | Puntos |
| - | -------- | ------ |
| 1 | Un grupo de cinco empresas que no confían entre sí quiere un registro común de envíos. Otro grupo, una sola empresa con cinco sedes, quiere lo mismo. ¿En cuál aporta algo una blockchain y por qué? | 10 |
| 2 | ¿Por qué el efecto avalancha es imprescindible para detectar alteraciones? ¿Qué pasaría si cambiar una letra cambiara solo un dígito del hash? | 10 |
| 3 | Publicas el keccak256 del número de documento de un cliente "para no revelar el dato". ¿Por qué no lo proteges y qué habría que añadir? | 10 |
| 4 | ¿Por qué `cast keccak "hola"` y `cast keccak 0x686f6c61` dan el mismo resultado, y por qué `printf 'hola' \| sha256sum` da otro? | 10 |
| 5 | Describe el camino de una clave privada a una dirección, con el tamaño en bytes de cada paso. ¿Qué paso impide volver atrás? | 10 |
| 6 | ¿Qué protege el checksum EIP-55 y por qué una dirección en minúsculas sigue siendo válida? | 10 |
| 7 | ¿Por qué perder la frase semilla es peor que perder una clave privada concreta? | 10 |
| 8 | Una firma verifica correctamente. Nombra dos cosas que demuestra y dos que **no** demuestra. | 10 |
| 9 | ¿Qué ataque evita el prefijo `\x19Ethereum Signed Message:\n` de EIP-191? | 10 |
| 10 | Alguien altera una transacción del bloque 100 de una cadena que va por el 200. ¿Por qué no basta con recalcular el hash del bloque 100, y qué hace que en Ethereum sea inviable rehacerlo todo? | 10 |

**Total**: 100 puntos → 30 % de la nota.

<details>
<summary>Respuestas</summary>

1. En el de las cinco empresas desconfiadas: ninguna quiere que otra controle el registro
   y pueda alterarlo o excluirla. En la empresa con cinco sedes hay un único responsable
   en el que todos confían: una base de datos PostgreSQL es más barata, rápida y simple.
2. Porque la alteración más pequeña debe producir un hash irreconocible. Si una letra
   cambiara un solo dígito, se podrían buscar cambios que dejaran el hash "casi igual" y
   sería mucho más fácil construir datos falsos con un hash aceptable.
3. Los números de documento son pocos y predecibles: se prueban todos, se hashean y se
   compara. Hay que añadir un valor aleatorio secreto (*salt*) antes de hashear, o no
   publicar nada derivado del dato.
4. `cast keccak` interpreta lo que empieza por `0x` como bytes, y `0x686f6c61` son
   exactamente los bytes UTF-8 de `hola`: misma entrada, mismo hash. `sha256sum` usa otro
   algoritmo (SHA-256), así que da otro resultado para los mismos bytes.
5. Clave privada (32 bytes) → con secp256k1 → clave pública (64 bytes) → keccak256 (32
   bytes) → últimos 20 bytes = dirección. Ningún paso se puede invertir: el de la curva
   no tiene vuelta práctica y el hash tampoco (resistencia a preimagen); además, recortar
   pierde información.
6. Detecta errores al copiar: el patrón de mayúsculas depende del hash de la dirección y
   un carácter cambiado lo rompe. Las minúsculas siguen siendo la misma dirección (el hex
   no distingue mayúsculas), solo que sin esa comprobación.
7. Porque de la frase se derivan **todas** las claves de todos los índices. Quien la
   tiene controla todas tus cuentas; quien tiene una clave, solo una.
8. Demuestra autoría (la firmó quien controla esa dirección) e integridad (el mensaje no
   cambió). No demuestra cuándo se firmó, ni con qué intención, ni que no se haya usado
   antes (*replay*).
9. Que una web te haga "firmar un mensaje" que en realidad son los bytes de una
   transacción. Con el prefijo, lo firmado nunca es una transacción válida.
10. El bloque 101 guarda el hash original del 100: al recalcularlo, deja de coincidir y
    hay que rehacer el 101, luego el 102... hasta el 200. Y los nodos honestos conservan
    la cadena original y siguen añadiendo bloques; en Ethereum, con prueba de
    participación, rehacer bloques finalizados exigiría destruir un tercio de todo el ETH
    depositado por los validadores.

</details>

---

## 💪 Desempeño (40 %)

| Ejercicio | Criterio | Puntos |
| --------- | -------- | ------ |
| 01 — Hashes con cast | `bash test.sh`: 6 de 6 | 20 |
| | Explica por qué el paso 6 detecta el cambio sin conocer el dato original | 10 |
| 02 — Claves y direcciones | `bash test.sh`: 6 de 6 | 20 |
| | Explica por qué los pasos 1 y 3 coinciden | 10 |
| 03 — Firmar y verificar | `bash test.sh`: 6 de 6 | 25 |
| | Explica por qué los pasos 3 y 4 se rechazan por motivos distintos | 15 |

**Total**: 100 puntos → 40 % de la nota.

---

## 📦 Producto (30 %)

| Criterio | Puntos |
| -------- | ------ |
| Repositorio `bc-smartcontracts-<dominio>` con carpeta `week-01/` y pull request `week-01` → `main` | 10 |
| `bash test.sh`: 8 de 8 tests en verde | 50 |
| Datos y registros concretos de tu dominio (no `Item`), `INDEX` propio | 20 |
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
| [← Proyecto — Ficha criptográfica](3-proyecto/README.md) | **Rúbrica de evaluación** | [Ebooks gratuitos →](4-recursos/ebooks-free/README.md) |
