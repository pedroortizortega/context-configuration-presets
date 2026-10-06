---
name: feature-delivery
description: Entry point for a backend ticket. Turns the ticket into an OpenSpec change approved by the human and launches the project-manager to implement it. Use it for any feature, API change, update or non-trivial bug.
---

# Feature delivery

Read `ORCHESTRATION.md` before starting (states, delegation template and handoff). This skill only covers **Phase 1 (specification, no code)** and the launch of the project-manager. Implementation, judging and verification are coordinated by the `project-manager` agent according to `ORCHESTRATION.md`. Do not duplicate that protocol here.

## Input

Receive a ticket, link or description. Extract the goal, actors, rules, acceptance criteria, dependencies, sensitive data and out-of-scope items. If acceptance criteria are missing, ask before continuing.

## Phase 1: specification; no code

1. Define the `<change>` identifier in kebab-case and create `ops/change-state/<change>.yaml` from `ops/change-state/template.yaml` with `status: INTAKE`, `change` and `ticket`.
2. Invoke the `spec-designer` skill to create `openspec/changes/<change>/` (proposal, design, tasks and specs). This phase is interactive: it runs in this thread, not in a subagent.
3. Create `verification.md` in the change from `openspec/templates/verification.md`, without evidence: the `tester` fills it per group during implementation.
4. Launch the `planner` to fill `test-plan.md` from `openspec/templates/test-plan.md` (acceptance criterion → test → synthetic data, based on specs and design) and the `architect` to fill `threat-model.md` from `openspec/templates/threat-model.md`. Use the `<delegation_brief>` template of `ORCHESTRATION.md` (group `spec`, handoffs in `.claude/handoffs/<change>/`, e.g. `spec-planner.md`). Both also report any contradictions they see between artifacts. Fix them.
5. Change `status` to `SPEC_READY` and present to the human: scope, criteria, risks, tasks, changes to the architecture and flow diagrams, API contract and migrations. STOP until there is explicit approval.
6. Only with an explicit yes, set `spec_approved_by_human: true` in the state (`status` stays `SPEC_READY`; the project-manager advances it). If the human asks for changes, go back to step 2 and leave `spec_approved_by_human: false`.

## Launching the project-manager

With the specification approved, launch the `project-manager` agent with the Agent tool (in the foreground) and this minimal brief:

- `change`: `<change>`
- state path: `ops/change-state/<change>.yaml`
- change path: `openspec/changes/<change>/`
- instruction: read `ORCHESTRATION.md` and run the flow until `READY_FOR_HUMAN`.

The project-manager can launch the planner, developer, judge and tester, and these in turn can launch the architect (at most 3 levels of subagents).

Alternative: if the project-manager needs to ask you questions often, run it as the main agent with `claude --agent project-manager` (the `Agent(...)` list in its frontmatter is only honored in that mode).

## Final delivery

When the project-manager reports `READY_FOR_HUMAN`, deliver exactly: summary, modified files, covered criteria, gates with their `exit_code`, residual risks, migrations, rollback and the command to bring Docker up locally.

Do not merge or deploy. Do not declare success without executed tests.
