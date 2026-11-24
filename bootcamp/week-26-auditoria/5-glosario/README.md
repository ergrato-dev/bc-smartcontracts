# 📖 Glosario — Semana 26

| Término | Definición | Ejemplo |
| ------- | ---------- | ------- |
| Activo (*asset*) | Lo que un atacante querría llevarse o romper: fondos, derechos registrados o la disponibilidad | El ETH depositado en el `Escrow` |
| Actor | Quien llama al protocolo o del que el protocolo depende, con su nivel de confianza | Alice, Bob, el árbitro, Mallory |
| Alcance (*scope*) | Los contratos y el commit que cubre una auditoría, y lo que queda fuera | `src/Escrow.sol` en un commit fijo |
| Amenaza | Algo que no debe pasar nunca, escrito desde el atacante, con su defensa y su prueba | T-05: el árbitro se lleva el ETH |
| Auditoría (*audit*) | Revisión de seguridad de un código fijo, con método, que termina en un informe | Las siete fases de la teoría 01 |
| Bug bounty | Programa público que paga por fallos divulgados de forma responsable | Un programa en Immunefi |
| Causa raíz (*root cause*) | El error de fondo de un hallazgo; varios escenarios con la misma causa son un solo hallazgo | `claim` compara con el saldo del contrato |
| CTF (*capture the flag*) | Reto con un contrato vulnerable y una condición de victoria | `Level1Setup.isSolved()` |
| Divulgación responsable (*responsible disclosure*) | Avisar en privado al equipo de un fallo y dar tiempo a corregirlo antes de publicar nada | Un informe por el canal de `SECURITY.md` |
| Estado (de un hallazgo) | Su situación tras la revisión de correcciones: corregido, corregido parcialmente, reconocido o disputado | H-04 del proyecto: reconocido |
| Falso positivo (*false positive*) | Aviso de una herramienta que, revisado, no es explotable | `reentrancy-eth` en `refundAll` |
| Frontera de confianza (*trust boundary*) | Sitio por donde entra algo de fuera: argumentos, llamadas, precios o firmas | El argumento `to` de `resolve` |
| Hallazgo (*finding*) | Fallo documentado con severidad, descripción, impacto, prueba, recomendación y estado | H-02: un aportante bloquea las devoluciones |
| Impacto | Lo que se pierde si un fallo se explota | Alto: fondos bloqueados para siempre |
| Informe (*report*) | Documento final de una auditoría: resumen, alcance, hallazgos y limitaciones | `audit/README.md` |
| Modelo de amenazas (*threat model*) | Descripción del protocolo desde el atacante: actores, activos, fronteras y amenazas | La tabla T-01 a T-05 del ejercicio 01 |
| nSLOC | Líneas de código sin comentarios ni líneas en blanco; mide el tamaño de un alcance | Lo que cuenta una firma para presupuestar |
| Probabilidad | Lo que hace falta para que un fallo se explote | Baja: hace falta la clave del árbitro |
| Prueba de concepto (*proof of concept*, PoC) | Test que pasa porque el fallo existe y dice cuánto se pierde | `test_Paso4_PoC_FeeRoundsDown` |
| Revisión de correcciones (*fix review*) | Comprobar cada corrección del equipo y que no trae fallos nuevos | La PoC deja de pasar tras corregir |
| Riesgo aceptado | Amenaza que el protocolo asume a propósito y el informe declara | El árbitro decide mal entre Alice y Bob |
| Riesgo de centralización (*centralization risk*) | Una sola cuenta con poder para cambiar el código o mover los fondos | `DEFAULT_ADMIN_ROLE` en una sola cuenta, sin timelock |
| Severidad (*severity*) | Prioridad de un hallazgo según impacto y probabilidad: crítica, alta, media, baja o informativa | H-01 del ejercicio 02: crítica |
| Superficie de ataque (*attack surface*) | Las funciones externas que cambian estado: las puertas por las que entra alguien de fuera | `forge inspect Escrow methodIdentifiers` |

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Webgrafía](../4-recursos/webgrafia/README.md) | **Glosario** | [Semana 27 — La EVM por dentro →](../../week-27-evm_por_dentro/README.md) |
