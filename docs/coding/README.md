# Coding preset: orchestration for Python backends

A preset with Codex and Claude Code configurations that turns a ticket into verified changes on local branches, ready for your approval. A team of agents (project-manager, planner, architect, developer, judge, tester) works from an OpenSpec specification that a human has approved. It gives no access to AWS and authorizes no deployments or pushes.

Install your selected harness using the [installation guide](installation.md). The operating flow and diagrams below describe the Claude Code workflow.

## Diagrams

Open them in a browser (they have light/dark mode, zoom and export).

| Diagram | What it shows |
|---|---|
| [Ticket delivery flow](ticket-delivery-flow.html) | Lanes, human gates, the developer → judge → tester loop, rework and blocked states |
| [Context architecture](context-architecture.html) | Which file reaches which role's context, and what the harness enforces outside the model |

The editable sources (`*.workflow.json`, `*.architecture.json`) live next to them in this folder.

## Contents

| Path | What it is |
|---|---|
| `CLAUDE.md` | Claude Code only: execution contract; imports only `AGENTS.md` (which reaches every subagent) |
| `AGENTS.md` | Stable project rules (constraints and output format) |
| `ORCHESTRATION.md` | States, workflow, handoffs and worktrees; read by the project-manager and the skill, not imported |
| `QUALITY_GATES.md` | Gates that must pass before delivery |
| `.codex/` | Codex configuration, agents, skills, rules and hooks (installed only with `--harness codex`) |
| `.claude/agents/` | The 6 agents of the Claude Code team (installed with the rest of `.claude/` only with `--harness claude`) |
| `.claude/skills/` | `feature-delivery` (entry point), `spec-designer`, `design-patterns` |
| `.claude/settings.json` | Real permissions: `allow` and `deny` (no AWS, no `git push`) and a hook that prevents `git merge` on `main`/`master` |
| `.claude/hooks/block-merge-to-main.sh` | PreToolUse hook (requires `jq`): blocks merging into `main`/`master`; merges inside working branches stay allowed |
| `openspec/` | Templates (`openspec/templates/`) for `test-plan`, `threat-model` and `verification` |
| `ops/change-state/template.yaml` | Template for the state of each change |
| `scripts/verify.sh` | Runs the gates in order (same script for local and CI) |
| `deploy/docker-compose.test.yml`, `.env.test.example` | Local stack for the integration gate |
| `.gitignore.extras` | Entries to append to the target repo's `.gitignore` (not a `.gitignore` itself, so it never overrides yours) |

## Installation

Use the root installer instead of copying all of `coding/`:

```bash
bash install.sh --harness claude --target "/path/to/backend" --dry-run
bash install.sh --harness claude --target "/path/to/backend"
```

Use `--harness codex` for Codex. The destination is the project root. Existing differing files, including `AGENTS.md` or `CLAUDE.md`, are never merged or overwritten automatically.

On Windows, use `.\install.ps1 -Harness claude -Target "C:\Projects\backend" -DryRun`, then remove `-DryRun` to install. Use `-Harness codex` for Codex.

See [Installation](installation.md) for the exact file mapping, conflict recovery and post-install setup. Copying the files alone does not configure your project's gates or update its `.gitignore`.

## Operating flow

1. Open Claude Code in the repo and hand over the ticket: `/feature-delivery <ticket>`.
2. The skill creates `ops/change-state/<change>.yaml`, runs `spec-designer` and stops until you approve the specification (`SPEC_READY`).
3. With your approval it launches the `project-manager`, which reads `ORCHESTRATION.md`, asks the `planner` for a plan and waits for your approval of the plan.
4. For each task group: `developer` → `judge` → `tester`, each in its own worktree and with a handoff in `.claude/handoffs/<change>/`.
5. When everything passes, the status is `READY_FOR_HUMAN` and you receive a single decision package: summary, gates with `exit_code`, risks and rollback. You authorize every merge.

If you need the project-manager to ask you questions more smoothly, run it as the main agent: `claude --agent project-manager`.

## Principles

- `openspec/changes/<change>/` is the source of truth for the current change; `ops/change-state/<change>.yaml` is its state (state and links only).
- Every agent delivers a handoff with a YAML block (commands, `exit_code`, artifacts) plus prose. A `pass` without evidence is invalid.
- The judge does not write code. The developer does not approve their own work.
- Every behavior change includes an automated test or an explicit, approved exception.
- At most 2 fix loops per group; after that the planner decides.
- Nothing is merged without your explicit approval; Claude does not `push` or `merge` into `main`/`master` (a hook prevents it).

## Per-project configuration

- `base_branch` is confirmed with you in the project-manager's preflight and stored in the change state.
- Gates and commands: `QUALITY_GATES.md` and `scripts/verify.sh`. Replace the UPPERCASE placeholders (`CONTRACT_TESTS_PATH`, `INTEGRATION_COMPOSE_FILE`, `INTEGRATION_SERVICE`) once in both files, or skip the gate with `SKIP_GATES`. CI must run the same script.
- Templates in `openspec/templates/`: the planner fills `test-plan.md`, the architect fills `threat-model.md` and the tester fills `verification.md` (all coordinated from `feature-delivery`).
- Models: the frontmatter of each agent defines `model` and `effort`; adjust them to your team's plan.
- Language: these files are in English. Agents still talk to you and write handoff prose in Spanish, as their own prompts instruct; change that in the agent files if your team prefers another language.

## Before the first ticket

- Make `bash scripts/verify.sh` work locally.
- If you create a real `.env.test`, make sure it is not versioned: append `.gitignore.extras` to your `.gitignore` (it ignores `.env*`, including `.env.test.example`).
- Protect `main`: pull requests, required checks and human approval.
- The OpenSpec change is created by the `spec-designer` skill (it does not need the `openspec` CLI). `openspec/config.yaml` and `schema.yaml` only apply if you use the CLI. Note: `schemas/production/schema.yaml` looks for its templates next to it and today they are not there (they live in `openspec/templates/`), and the `proposal`, `spec`, `design` and `tasks` templates are missing; with the CLI that schema would not work until they are added (or until you generate a new one with `openspec schema fork`). It does not affect the flow of this preset.
