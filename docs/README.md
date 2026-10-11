# Documentation

Documentation for every preset lives here, one folder per preset. The root `install.sh` (Bash) and `install.ps1` (Windows PowerShell) install the coding preset for Codex or Claude Code without copying these docs. Start with the [installation guide](coding/installation.md).

| Preset | Docs | Status |
|---|---|---|
| [`coding/`](../coding/) | [docs/coding/](coding/README.md): installation, flow, per-project configuration and diagrams | Ready |
| [`finnance/`](../finnance/) | [docs/finnance/](finnance/) | Work in progress |
| [`general-skills/`](../general-skills/) | Skills documented in their own `SKILL.md` | Ready |

## Convention

- `docs/<preset>/README.md` is the entry point for that preset.
- Diagrams and other assets sit next to that README; links are relative to it.
- Nothing inside a preset folder may link into `docs/`: the preset must work when copied alone.
