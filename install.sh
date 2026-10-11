#!/usr/bin/env bash
# Install coding presets into a project root without replacing user files.
set -Eeo pipefail
fail() { printf 'Error: %s\n' "$*" >&2; exit 1; }
usage() {
    cat <<'HELP'
Usage: bash install.sh --harness codex|claude --target PROJECT_DIR [--dry-run]
Without arguments, an interactive terminal prompts for the harness and directory.
The target is the project root, not its .codex or .claude directory.
Existing identical files are skipped; conflicting files abort before any writes.
Symlinks and paths containing '..' are rejected. Use an absolute path instead.
--dry-run validates and previews without creating files or directories.
Requires Bash and standard Unix utilities (Linux, macOS, or WSL).
HELP
}
harness='' target='' dry_run=false
if (($# == 0)); then
    [[ -t 0 ]] || fail 'No interactive terminal. Provide --harness and --target.'
    printf 'Harness: 1) Codex  2) Claude Code\n'
    read -r -p 'Choose 1 or 2: ' choice || fail 'Input cancelled.'
    case "$choice" in 1) harness=codex ;; 2) harness=claude ;; *) fail 'Invalid harness.' ;; esac
    read -r -p 'Project directory: ' target || fail 'Input cancelled.'
else
    while (($#)); do
        case "$1" in
            --harness|--target)
                (($# >= 2)) || fail "Missing value for $1."
                [[ -n "$2" && "$2" != --* ]] || fail "Missing value for $1."
                if [[ "$1" == --harness ]]; then harness=$2; else target=$2; fi
                shift 2 ;;
            --dry-run) dry_run=true; shift ;;
            -h|--help) usage; exit 0 ;;
            *) fail "Unknown argument: $1" ;;
        esac
    done
fi
case "$harness" in codex|claude) ;; *) fail 'Use --harness codex or --harness claude.' ;; esac
[[ -n "$target" ]] || fail 'A nonempty --target project directory is required.'
[[ "$target" != '~'* ]] || fail 'Use $HOME or an expanded absolute path, not a quoted tilde.'
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
source_root=$repo/coding
[[ "$target" == /* ]] || target="$PWD/$target"
# Check each component before normalization so links cannot hide behind '..'.
normalized=''
remaining=$target
while [[ -n "$remaining" ]]; do
    component=${remaining%%/*}
    if [[ "$remaining" == */* ]]; then remaining=${remaining#*/}; else remaining=''; fi
    case "$component" in ''|.) continue ;; ..) fail "Parent traversal is not allowed: $target" ;; esac
    normalized="$normalized/$component"
    [[ ! -L "$normalized" ]] || fail "Symlink destination: $normalized"
    [[ ! -e "$normalized" || -d "$normalized" ]] || fail "Not a directory: $normalized"
done
target=$normalized
[[ -n "$target" ]] || fail 'Refusing filesystem root as target.'
case "$target" in
    /bin|/bin/*|/sbin|/sbin/*|/etc|/etc/*|/usr|/usr/*|/dev|/dev/*|/proc|/proc/*|/sys|/sys/*|/boot|/boot/*|/run|/run/*)
        fail 'Refusing a system directory as target.' ;;
esac
[[ "$target" != "${HOME:-}" ]] || fail 'Choose a project directory, not your home directory.'
case "$target" in "$repo"|"$repo"/*) fail 'Target must be outside the preset repository.' ;; esac
case "$repo" in "$target"/*) fail 'Target must not contain the preset repository.' ;; esac
case "${target##*/}" in .codex|.claude) fail 'Pass the project root, not the harness directory.' ;; esac
paths=(".$harness" deploy openspec ops scripts/verify.sh .env.test.example .gitignore.extras AGENTS.md ORCHESTRATION.md QUALITY_GATES.md)
[[ "$harness" != claude ]] || paths+=(CLAUDE.md)
directories=() files=()
shopt -s nullglob dotglob
# Build and validate the whole manifest before touching the destination.
collect() {
    local relative=$1 source="$source_root/$1" child
    [[ ! -L "$source" ]] || fail "Symlink source: $source"
    if [[ -d "$source" ]]; then
        [[ -r "$source" && -x "$source" ]] || fail "Unreadable source directory: $source"
        directories+=("$relative")
        for child in "$source"/*; do collect "$relative/${child##*/}"; done
    elif [[ -f "$source" && -r "$source" ]]; then
        files+=("$relative")
    else
        fail "Missing, unreadable, or unsupported source: $source"
    fi
}
[[ -d "$source_root" && ! -L "$source_root" ]] || fail "Invalid preset root: $source_root"
for path in "${paths[@]}"; do collect "$path"; done
directories+=(scripts)
check_parents() {
    local path=$1
    while [[ "$path" != "$target" ]]; do
        [[ ! -L "$path" ]] || fail "Symlink destination: $path"
        [[ ! -e "$path" || -d "$path" ]] || fail "Directory conflict: $path"
        path=${path%/*}
    done
}
for path in "${directories[@]}"; do check_parents "$target/$path"; done
pending=()
for path in "${files[@]}"; do
    destination="$target/$path"
    check_parents "${destination%/*}"
    [[ ! -L "$destination" ]] || fail "Symlink destination: $destination"
    if [[ -e "$destination" ]]; then
        [[ -f "$destination" ]] && cmp -s "$source_root/$path" "$destination" || fail "File conflict: $destination (back up or move it first)."
        [[ ! -x "$source_root/$path" || -x "$destination" ]] || fail "Executable permission conflict: $destination"
    else
        pending+=("$path")
    fi
done
printf 'Validated %s presets for %s (%s new files).\n' "$harness" "$target" "${#pending[@]}"
if "$dry_run"; then printf 'Dry run: no changes made.\n'; exit 0; fi
# Runtime failures can leave a partial installation; unchanged files are safe to retry.
trap 'printf "Installation failed; some new files may remain. Resolve the error and retry.\n" >&2' ERR
temporary=''
trap 'if [[ -n "$temporary" ]]; then rm -f -- "$temporary"; fi' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
mkdir -p -- "$target"
for path in "${directories[@]}"; do mkdir -p -- "$target/$path"; done
for path in "${pending[@]}"; do
    # Publish complete files atomically without replacing a concurrent file.
    destination="$target/$path"
    temporary=$(mktemp "${destination%/*}/.preset-install.XXXXXX")
    cp -p -- "$source_root/$path" "$temporary"
    ln -- "$temporary" "$target/$path"
    rm -f -- "$temporary"
    temporary=''
done
printf 'Installation complete. Existing files were preserved.\n'
