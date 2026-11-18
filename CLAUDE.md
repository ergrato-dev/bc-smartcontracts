# CLAUDE.md — bc-smartcontracts

Bootcamp **Smart Contracts Zero to Advanced**: 34 semanas × 14 h = 476 h, autoestudio,
de cero en blockchain (con programación previa) a avanzado. Solidity y Foundry,
estándares ERC, proxies, dApps (viem, wagmi, FastAPI + PostgreSQL), auditoría de
seguridad, EVM y Yul, DeFi, account abstraction y L2.

## Fuente de verdad

**[`.github/copilot-instructions.md`](.github/copilot-instructions.md)**: malla,
estructura de semana, formato de starters, navegación, paleta SVG, rúbrica y checklist.
Léelo antes de generar contenido.

## Reglas duras

1. **Todo fragmento compila y se ejecuta** con la toolchain de `docs/stack-versions.md`,
   verificado en el contenedor (`docker build -t bc-smartcontracts-dev docker`). Ningún
   hash, dirección, gas, error ni warning se cita de memoria: se copia de la salida real.
2. **Cero en blockchain, paso a paso.** Cada término del dominio se define la primera
   vez. Cada ejemplo dice dónde se escribe, cómo se ejecuta y qué imprime. La
   programación general se da por conocida; nada de blockchain se da por sabido.
3. **Progresión estricta.** Ninguna semana usa lo que se enseña después.
4. **Seguridad como eje**: cada construcción nueva trae sus riesgos en la misma teoría.
5. **Nunca dinero real ni claves reales.** anvil o testnets; cuentas de prueba de anvil.
6. **Tuteo siempre, nunca voseo.** Prosa en español; código, identificadores, nombres de
   archivo de código y commits en inglés (Conventional Commits: `feat(week-01): ...`).
7. **Comentarios ¿Qué? ¿Para qué? ¿Impacto?** donde aporten, sin repetirlos.
8. **Herramientas**: Docker con `ubuntu:24.04`, PostgreSQL (nunca MySQL), pnpm (nunca
   npm ni npx), uv (nunca pip).
9. **SVG** los que pida el contenido; tema oscuro, sin degradados, sans-serif.
10. **Navegación en tabla** (Anterior | Actual | Siguiente) al pie de todo `.md` de `bootcamp/`.
11. **Sin soluciones en el repo.** Ejercicios: las líneas `//> ` o `#> ` del starter son la
    solución, nunca hay `solution/`. Proyecto: la solución va a
    `ergrato-dev/bc-instructor/bc-smartcontracts/week-NN-slug/3-proyecto/`; en ese repo se
    hace commit solo de la carpeta propia
    (`git add bc-smartcontracts && git commit -m "..." -- bc-smartcontracts`).
12. **Dominios fuera del repo.** Catálogo en
    `ergrato-dev/bc-dominios/catalogos/bc-smartcontracts.md`. Aquí solo se dice que el
    dominio lo asigna el instructor.
13. **Bloques de 5 semanas por sesión**, una semana por commit, push al cerrar cada semana.

## Antes de dar por terminada una semana

```bash
./scripts/compilar-starters.sh week-NN   # starters fallan; resueltos pasan sin warnings
./scripts/verificar-enlaces.sh           # carpetas, enlaces, navegación, SVG, prohibidos
```

## Estructura

```
bootcamp/   34 semanas + README.md índice
docs/       setup, versiones, hilo conductor, plantillas/starter-foundry
docker/     Dockerfile (ubuntu:24.04 + Foundry + solc + forge-std en /opt/lib)
scripts/    compilar-starters.sh, verificar-enlaces.sh
assets/     header del README
```
