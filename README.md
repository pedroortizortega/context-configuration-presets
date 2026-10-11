# Context Configuration Presets

Context configuration presets in markdown files to configure your harnesses.

All the files follow the same format depending on the setup. For example, `AGENTS.md` has its own labels, and skills the same.

The idea is that if you follow this template you can adapt it to your sub agents.

## Layout

Preset files live in `coding/`, `finnance/` and `general-skills/`; documentation lives separately in [docs/](docs/README.md). The installer currently supports only the **coding preset**, selecting Codex or Claude Code without copying documentation or the other harness. Other presets are not installed by this script.

## Installation quickstart

From this repository, preview the selected harness and then install it into your **project root** (not `.codex/` or `.claude/`):

```bash
bash install.sh --harness codex --target "/path/to/my project" --dry-run
bash install.sh --harness codex --target "/path/to/my project"
```

For Claude Code, use `--harness claude`. Run `bash install.sh` without arguments for terminal prompts. Existing identical files are skipped; conflicting files stop installation before any writes.

On Windows, use **PowerShell** (`.ps1`, not `.bat`):

```powershell
.\install.ps1 -Harness codex -Target "C:\Projects\my project" -DryRun
.\install.ps1 -Harness codex -Target "C:\Projects\my project"
```

Use `-Harness claude` for Claude Code, or run `.\install.ps1` for prompts. The Windows installer targets Windows PowerShell 5.1 and PowerShell 7; Windows runtime verification is still pending.

See the [installation guide](docs/coding/installation.md) for prerequisites, copied files, conflict handling and required project customization.

## coding

In this folder you can find the files to set up your agent as a coding agent, using good practices and my personal point of view for constraints.

Check my constraints and adapt your style at that point.

It includes Codex and Claude Code configurations for a delivery team handling backend tickets: a ticket becomes an approved OpenSpec change, and a project manager coordinates planner, architect, developer, judge and tester until the work is verified and ready for your approval.

| Path | What it is |
|---|---|
| `coding/CLAUDE.md`, `coding/AGENTS.md` | Project constitution and stable rules |
| `coding/ORCHESTRATION.md` | States, workflow, handoff and delegation templates |
| `coding/QUALITY_GATES.md`, `coding/scripts/verify.sh` | Gates that must pass before delivery |
| `coding/.codex/`, `coding/.claude/` | Harness-specific agents, skills and configuration; only the selected harness is installed |
| `coding/openspec/`, `coding/ops/` | Artifact templates and per-change state |
| `coding/deploy/`, `coding/.gitignore.extras` | Test compose stack and `.gitignore` entries to append |

Start with [docs/coding/README.md](docs/coding/README.md): installation, flow and what to adapt per project.
