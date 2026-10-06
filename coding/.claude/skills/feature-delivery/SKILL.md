---
name: feature-delivery
description: Punto de entrada para un ticket de backend. Convierte el ticket en un cambio OpenSpec aprobado por el humano y lanza al project-manager para implementarlo. Úsala para cualquier feature, cambio de API, actualización o bug no trivial.
---

# Entrega de feature

Lee `ORCHESTRATION.md` antes de empezar (estados, plantilla de delegación y handoff). Esta skill solo cubre la **Fase 1 (especificación, sin código)** y el arranque del project-manager. La implementación, el juicio y la verificación los coordina el agente `project-manager` según `ORCHESTRATION.md`. No dupliques ese protocolo aquí.

## Entrada

Recibe ticket, enlace o descripción. Extrae objetivo, actores, reglas, criterios de aceptación, dependencias, datos sensibles y fuera de alcance. Si faltan criterios de aceptación, pregunta antes de continuar.

## Fase 1: especificación; no código

1. Define el identificador `<change>` en kebab-case y crea `ops/change-state/<change>.yaml` desde `ops/change-state/template.yaml` con `status: INTAKE`, `change` y `ticket`.
2. Invoca la skill `spec-designer` para crear `openspec/changes/<change>/` (proposal, design, tasks y specs). Esta fase es interactiva: corre en este hilo, no en un subagente.
3. Crea `verification.md` en el cambio a partir de `openspec/templates/verification.md`, sin evidencia: lo llena el `tester` por grupo durante la implementación.
4. Lanza al `planner` para que complete `test-plan.md` desde `openspec/templates/test-plan.md` (criterio de aceptación → prueba → datos sintéticos, a partir de specs y design) y al `architect` para que complete `threat-model.md` desde `openspec/templates/threat-model.md`. Usa la plantilla `<delegation_brief>` de `ORCHESTRATION.md` (grupo `spec`, handoffs en `.claude/handoffs/<change>/`, p. ej. `spec-planner.md`). Ambos reportan además las contradicciones que vean entre artefactos. Corrígelas.
5. Cambia `status` a `SPEC_READY` y presenta al humano: alcance, criterios, riesgos, tareas, cambios en el diagrama de arquitectura y de flujo, contrato API y migraciones. DETENTE hasta aprobación explícita.
6. Solo con un sí explícito, pon `spec_approved_by_human: true` en el estado (el `status` se mantiene en `SPEC_READY`; el project-manager lo avanza). Si el humano pide cambios, vuelve al paso 2 y deja `spec_approved_by_human: false`.

## Arranque del project-manager

Con la especificación aprobada, lanza el agente `project-manager` con la herramienta Agent (en primer plano) y este brief mínimo:

- `change`: `<change>`
- ruta del estado: `ops/change-state/<change>.yaml`
- ruta del cambio: `openspec/changes/<change>/`
- instrucción: leer `ORCHESTRATION.md` y ejecutar el flujo hasta `READY_FOR_HUMAN`.

El project-manager puede lanzar a planner, developer, judge y tester, y estos a su vez a architect (máximo 3 niveles de subagentes).

Alternativa: si el project-manager necesita preguntarte con frecuencia, ejecútalo como agente principal con `claude --agent project-manager` (la lista `Agent(...)` de su frontmatter solo se respeta en ese modo).

## Entrega final

Cuando el project-manager reporte `READY_FOR_HUMAN`, entrega exactamente: resumen, archivos modificados, criterios cubiertos, gates con su `exit_code`, riesgos residuales, migraciones, rollback y comando para levantar Docker localmente.

No hagas merge ni despliegue. No declares éxito sin pruebas ejecutadas.
