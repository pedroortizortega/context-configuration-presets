# Context Configuration Presets

Context configuration presets in markdown files to configure your harnesses.

All the files follow the same format depending on the setup. For example, `AGENTS.md` has its own labels, and skills the same.

The idea is that if you follow this template you can adapt it to your sub agents.

## coding

In this folder you can find the files to set up your agent as a coding agent, using good practices and my personal point of view for constraints.

Check my constraints and adapt your style at that point.

It is a delivery team for backend tickets (Claude Code): a ticket becomes an approved OpenSpec change, and a project manager coordinates planner, architect, developer, judge and tester until the work is verified and ready for your approval.

| Path | What it is |
|---|---|
| `coding/CLAUDE.md`, `coding/AGENTS.md` | Project constitution and stable rules |
| `coding/ORCHESTRATION.md` | States, workflow, handoff and delegation templates |
| `coding/QUALITY_GATES.md`, `coding/scripts/verify.sh` | Gates that must pass before delivery |
| `coding/.claude/` | Agents, skills (`feature-delivery` is the entry point), permissions and hooks |
| `coding/openspec/`, `coding/ops/` | Artifact templates and per-change state |

Start with [coding/README.md](coding/README.md): installation, flow and what to adapt per project.
