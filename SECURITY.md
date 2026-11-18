# Política de seguridad

## Alcance

Este repositorio es material educativo. Contiene un `Dockerfile`, scripts de shell, contratos
Solidity y, desde la fase 4, una dApp y un indexador con base de datos. Un fallo de
seguridad aquí es, sobre todo, **un mal ejemplo que alguien copiará a mainnet**: un
contrato vulnerable presentado como correcto, una clave privada real en el código,
SQL concatenado, contenedores como root.

## Cómo reportar

No abras un issue público. Usa
[GitHub Security Advisories](https://github.com/ergrato-dev/bc-smartcontracts/security/advisories/new)
con el título `[SECURITY] bc-smartcontracts: <resumen>`, la ruta del archivo y cómo
reproducirlo. Respuesta en un máximo de 7 días.

## Fuera de alcance

- Fallos de Solidity, Foundry, OpenZeppelin, viem o Docker como productos: repórtalos a sus proyectos.
- Código de ejemplo marcado explícitamente con `// ❌` como lo que **no** se hace, y los
  contratos vulnerables a propósito de la fase 5 (están marcados como tales).
- Las claves de las cuentas de prueba de anvil: son públicas por diseño.
