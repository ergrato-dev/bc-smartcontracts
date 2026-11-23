# 📚 Ebooks gratuitos — Semana 13

| Título | Formato | Descripción | Enlace |
| ------ | ------- | ----------- | ------ |
| Documentación de OpenZeppelin Contracts 5.x | Web (MIT) | La guía oficial de la biblioteca, con una página para el control de acceso y la referencia de cada contrato | https://docs.openzeppelin.com/contracts/5.x/ |
| OpenZeppelin — Access Control | Web (MIT) | `Ownable`, `Ownable2Step`, `AccessControl`, el traspaso a un timelock y `AccessManager` | https://docs.openzeppelin.com/contracts/5.x/access-control |
| Solidity by Example — Multi-Sig Wallet | Web (gratuita) | Un multisig con confirmaciones en una página, como el del ejercicio 03 | https://solidity-by-example.org/app/multi-sig-wallet/ |
| Solidity by Example — Time Lock | Web (gratuita) | Un timelock escrito a mano: `queue`, `execute` y `cancel` | https://solidity-by-example.org/app/time-lock/ |
| Documentación de Safe | Web | El multisig más usado: dueños, umbral y transacciones firmadas fuera de la cadena | https://docs.safe.global/home/what-is-safe |

- **OpenZeppelin**: esta semana, la página *Access Control* entera; termina con
  `AccessManager`, un gestor de permisos para varios contratos a la vez, que no usamos. En la
  referencia, *API → Access* y, para el timelock, *API → Governance → TimelockController*.
  Fíjate en que la URL diga `5.x`: en la 4.x, `Ownable` no pedía el dueño en el constructor.
- **Solidity by Example**: léelos con los ejercicios terminados y compáralos con los tuyos.
  El timelock de la página es más simple que el de OpenZeppelin: sin roles ni estados.
- **Safe**: lee *What is Safe* para ver cómo es un multisig en producción. Funciona con firmas,
  que llegan en la semana 14.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Rúbrica de evaluación](../../rubrica-evaluacion.md) | **Ebooks gratuitos** | [Videografía →](../videografia/README.md) |
