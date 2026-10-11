# Install the coding preset

The repository's `install.sh` (Bash) and `install.ps1` (Windows PowerShell) copy the shared coding preset and one harness configuration into a project root. It does not install Codex, Claude Code, dependencies or the other preset collections.

## Quick path

Keep the repository checkout intact: the installer reads `coding/` next to the script. It requires Bash and standard Unix utilities, including `cmp`, `cp`, `ln` and `mktemp`. Verification so far covers Linux; macOS and WSL have not been verified.

From the repository root, preview and then install **Codex**:

```bash
bash install.sh --harness codex --target "/path/to/my project" --dry-run
bash install.sh --harness codex --target "/path/to/my project"
```

For **Claude Code**:

```bash
bash install.sh --harness claude --target "/path/to/my project" --dry-run
bash install.sh --harness claude --target "/path/to/my project"
```

`--dry-run` validates the source and destination and reports the number of new files without creating files or directories. It is not a guarantee that later writes will succeed.

Run `bash install.sh` without arguments to choose the harness and destination interactively. This requires terminal input; automation must provide `--harness` and `--target`. Use `bash install.sh --help` for usage.

### Paths

- Pass the **project root**, not its `.codex/` or `.claude/` directory. Missing destination directories are created during installation.
- Quote paths containing spaces. Use `"$HOME/projects/backend"`, not `"~/projects/backend"`.
- You can run `bash /path/to/context-configuration-presets/install.sh ...` from another directory: sources remain relative to the script, while a relative `--target` is resolved from your current working directory.
- Use an absolute destination path when navigating outside the current directory: components named `..` are rejected.

## Windows PowerShell

PowerShell scripts use `.ps1`; `.bat` files belong to Windows Command Prompt. The Windows installer targets **Windows PowerShell 5.1** and **PowerShell 7 on Windows**, with no additional modules. Keep it next to `coding/`.

```powershell
.\install.ps1 -Harness codex -Target "C:\Projects\my project" -DryRun
.\install.ps1 -Harness codex -Target "C:\Projects\my project"
```

Use `-Harness claude` for Claude Code. With no arguments, the script prompts for both values; automation must provide both. `-Help` prints usage. Exit code `0` means success or a successful preview; failures are nonzero.

Relative targets resolve from your current filesystem directory; sources resolve from the script directory. Paths with spaces or brackets are treated literally. Windows-specific safeguards reject UNC/network and device paths, drive-relative paths such as `C:project`, `..` components, reserved names, alternate data streams, trailing dots/spaces, and source/destination paths of 240 characters or more. Use a normal local drive project directory. Reparse points, including junctions, symlinks and some cloud placeholders, are rejected in selected sources and destination paths, including their ancestors.

If Windows blocks script execution, inspect `Get-ExecutionPolicy -List` and follow your organization's policy. For a downloaded script, review its contents before considering `Unblock-File -LiteralPath .\install.ps1`. The installer does not change execution policy; organizational policy may still prohibit execution. See Microsoft's [execution policy documentation](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies).

The same file mapping and no-overwrite behavior apply on Windows. Files are compared by SHA-256; Unix executable permissions are not checked or reproduced. The copied Bash hooks and `scripts/verify.sh` remain Bash scripts: copying them does **not** make the preset workflow Windows-native. Configure an appropriate Bash environment and review harness commands before using those hooks or gates.

Windows runtime validation is pending: this change was authored on Linux without PowerShell installed. Run the standalone regression suite on Windows in **both** supported engines:

```powershell
powershell.exe -NoProfile -File .\tests\install_test.ps1
pwsh.exe -NoProfile -File .\tests\install_test.ps1
```

The tests use temporary fixtures and junctions; they do not install into your project. They require the chosen engine's execution policy to permit the test and installer scripts.

## What gets copied

Every path below is relative to `coding/` in the source and the project root in the destination. Directories are copied recursively, including hidden entries.

| Selection | Source → destination |
|---|---|
| Codex only | `.codex/` → `.codex/` |
| Claude Code only | `.claude/` → `.claude/`; `CLAUDE.md` → `CLAUDE.md` |
| Both selections | `AGENTS.md`, `ORCHESTRATION.md`, `QUALITY_GATES.md` → the same root filenames |
| Both selections | `deploy/`, `openspec/`, `ops/` → the same directories |
| Both selections | `scripts/verify.sh` → `scripts/verify.sh` |
| Both selections | `.env.test.example`, `.gitignore.extras` → the same root filenames |

The script does not copy `docs/`, itself or its regression tests. It does not automatically merge `.gitignore.extras` into `.gitignore`.

## Existing files and recovery

Before writing, the installer validates the complete selected source manifest and checks destination conflicts:

- Identical files are skipped; unrelated destination files remain untouched. With the Bash installer, if a source file is executable, its existing identical destination must also be executable.
- Different file contents, file/directory collisions, missing or unreadable sources, and symlinks in selected sources or destination paths stop installation. Resolve the reported issue and preview again.
- The filesystem root, your home directory itself, listed system directories, the preset repository, its descendants and its ancestors are rejected as destinations. These checks prevent common mistakes; they are not a general security sandbox.

For a conflicting project configuration, back it up and move the conflicting file out of its installation path before retrying, then manually reconcile the installed preset with your saved customizations. There is no force-overwrite or automatic merge option. After customization, subsequent installs can report conflicts again: this installer is not a preset updater.

New files are published individually without replacing existing files. **The installation is not an all-or-nothing transaction:** a write failure can leave completed files and directories behind. Correct the cause and rerun the same command; unchanged completed files will be skipped. Keep a backup or Git checkpoint before installation and avoid concurrent edits to the destination.

## Finish project setup

1. Review `AGENTS.md`, `QUALITY_GATES.md`, `scripts/verify.sh` and `deploy/docker-compose.test.yml`; adapt their rules and gate commands to your real stack before using the workflow.
2. Review `.gitignore.extras` and manually append or merge its entries into the project's `.gitignore`. Only then do its ignore rules apply; the installer never changes `.gitignore`.
3. Keep `.env.test.example` synthetic. The test compose file reads it directly; the supplied ignore entries exclude it, so recreate it in each worktree that needs the integration gate. Never add real secrets.
4. Follow the [per-project configuration checklist](README.md#per-project-configuration) and make the verification script work locally before the first ticket.

For installer maintenance, regression checks live in `tests/install_test.sh` and `tests/install_test.ps1`; they are not installed into the target project.
