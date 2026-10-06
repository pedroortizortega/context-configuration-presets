# Preset de orquestación para backend Python

Plantilla para que Claude Code convierta un ticket en cambios verificados en ramas locales, listos para tu aprobación. Un equipo de agentes (project-manager, planner, architect, developer, judge, tester) trabaja sobre una especificación OpenSpec aprobada por un humano. No da acceso a AWS ni autoriza despliegues ni pushes.

## Contenido

| Ruta | Qué es |
|---|---|
| `CLAUDE.md` | Contrato de ejecución; importa solo `AGENTS.md` (llega a todos los subagentes) |
| `AGENTS.md` | Reglas estables del proyecto (restricciones y formato de salida) |
| `ORCHESTRATION.md` | Estados, workflow, handoffs y worktrees; lo leen el PM y la skill, no se importa |
| `QUALITY_GATES.md` | Gates que deben pasar antes de entregar |
| `.claude/agents/` | Los 6 agentes del equipo |
| `.claude/skills/` | `feature-delivery` (entrada), `spec-designer`, `design-patterns` |
| `.claude/settings.json` | Permisos reales: `allow` y `deny` (sin AWS, sin `git push`) y un hook que impide `git merge` sobre `main`/`master` |
| `.claude/hooks/block-merge-to-main.sh` | Hook PreToolUse (requiere `jq`): bloquea el merge a `main`/`master`; los merges dentro de ramas de trabajo siguen permitidos |
| `openspec/` | Plantillas (`openspec/templates/`) de `test-plan`, `threat-model` y `verification` |
| `ops/change-state/template.yaml` | Plantilla del estado de cada cambio |
| `scripts/verify.sh` | Ejecuta los gates en orden (mismo script para local y CI) |
| `docker-compose.test.yml`, `.env.test.example` | Stack local para el gate de integración |

## Instalación

1. Copia el contenido de esta carpeta (incluida `.claude/`) a la raíz del backend.
2. Si el repo ya tiene `AGENTS.md` o `CLAUDE.md`, fusiona el contenido en lugar de sobrescribir.
3. Adapta una vez al stack real: `QUALITY_GATES.md` y `scripts/verify.sh` (mantenlos idénticos), `docker-compose.test.yml` y las reglas de `AGENTS.md`.
4. `.env.test.example` se versiona a propósito (solo valores sintéticos): `docker-compose.test.yml` lo lee directamente, así que cada worktree lo tiene. Nunca pongas secretos reales ahí.

## Flujo operativo

1. Abre Claude Code en el repo y entrega el ticket: `/feature-delivery <ticket>`.
2. La skill crea `ops/change-state/<change>.yaml`, ejecuta `spec-designer` y se detiene hasta que apruebes la especificación (`SPEC_READY`).
3. Con tu aprobación lanza al `project-manager`, que lee `ORCHESTRATION.md`, pide un plan al `planner` y espera tu aprobación del plan.
4. Por cada grupo de tareas: `developer` → `judge` → `tester`, cada uno en su worktree y con un handoff en `.claude/handoffs/<change>/`.
5. Cuando todo pasa, el estado es `READY_FOR_HUMAN` y recibes un único paquete de decisión: resumen, gates con `exit_code`, riesgos y rollback. Tú autorizas cada merge.

Si necesitas que el project-manager te pregunte con más fluidez, ejecútalo como agente principal: `claude --agent project-manager`.

## Principios

- `openspec/changes/<cambio>/` es la fuente de verdad del cambio actual; `ops/change-state/<cambio>.yaml` es su estado (solo estado y enlaces).
- Cada agente entrega un handoff con bloque YAML (comandos, `exit_code`, artefactos) más prosa. Un `pass` sin evidencia es inválido.
- El juez no escribe código. El developer no aprueba su propio trabajo.
- Todo cambio de comportamiento incluye prueba automatizada o una excepción explícita aprobada.
- Máximo 2 ciclos de corrección por grupo; después decide el planner.
- Nada se mergea sin tu aprobación explícita; Claude no hace `push` ni `merge` sobre `main`/`master` (lo impide un hook).

## Por proyecto: qué configurar

- `base_branch` se confirma contigo en el preflight del project-manager y queda en el estado del cambio.
- Gates y comandos: `QUALITY_GATES.md` y `scripts/verify.sh`. Reemplaza una vez los marcadores en MAYÚSCULAS (`CONTRACT_TESTS_PATH`, `INTEGRATION_COMPOSE_FILE`, `INTEGRATION_SERVICE`) en ambos archivos, o omite el gate con `SKIP_GATES`. CI debe ejecutar el mismo script.
- Plantillas de `openspec/templates/`: `test-plan.md` lo completa el planner, `threat-model.md` el architect y `verification.md` el tester (todo se coordina desde `feature-delivery`).
- Modelos: el frontmatter de cada agente define `model` y `effort`; ajústalos al plan de tu equipo.

## Antes del primer ticket

- Haz funcionar localmente `bash scripts/verify.sh`.
- Si creas un `.env.test` real, que no se versione (no hay `.gitignore` en este preset).
- Protege `main`: PR, checks obligatorios y aprobación humana.
- El cambio OpenSpec lo crea la skill `spec-designer` (no requiere el CLI de `openspec`). `openspec/config.yaml` y `schema.yaml` solo aplican si usas el CLI. Ojo: `schemas/production/schema.yaml` busca sus plantillas junto a él y hoy no están ahí (viven en `openspec/templates/`), y faltan las de `proposal`, `spec`, `design` y `tasks`; con el CLI ese schema no funcionaría hasta completarlas (o generar uno nuevo con `openspec schema fork`). No afecta al flujo de este preset.
