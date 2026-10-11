#!/usr/bin/env bash
set -Eeuo pipefail
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
mkdir -p "$tmp/repo/coding" "$tmp/work"
cp "$repo/install.sh" "$tmp/repo/install.sh"
for path in .codex .claude deploy openspec ops scripts; do
    mkdir -p "$tmp/repo/coding/$path"
    printf '%s\n' "$path" > "$tmp/repo/coding/$path/preset"
done
for path in .env.test.example .gitignore.extras AGENTS.md ORCHESTRATION.md QUALITY_GATES.md CLAUDE.md scripts/verify.sh; do
    printf '%s\n' "$path" > "$tmp/repo/coding/$path"
done
chmod +x "$tmp/repo/coding/scripts/verify.sh"
cd "$tmp/work"
run() { bash "$tmp/repo/install.sh" "$@"; }
reject() { if run "$@" > "$tmp/log" 2>&1; then echo "Expected rejection: $*" >&2; exit 1; fi; }
run --help >/dev/null
run --harness codex --target "$tmp/new project" >/dev/null
[[ -f "$tmp/new project/.codex/preset" && ! -e "$tmp/new project/.claude" ]]
[[ -x "$tmp/new project/scripts/verify.sh" ]]
run --harness codex --target "$tmp/new project" >/dev/null
[[ ! -e "$tmp/new project/.codex/.codex" ]]
mkdir -p "$tmp/new project/unrelated"
printf custom > "$tmp/new project/unrelated/keep"
run --harness codex --target "$tmp/new project" >/dev/null
[[ $(cat "$tmp/new project/unrelated/keep") == custom ]]
run --harness claude --target "$tmp/claude" >/dev/null
[[ -f "$tmp/claude/CLAUDE.md" && ! -e "$tmp/claude/.codex" ]]
run --harness codex --target "$tmp/dry" --dry-run >/dev/null
[[ ! -e "$tmp/dry" ]]
mkdir "$tmp/conflict"
printf 'custom\n' > "$tmp/conflict/QUALITY_GATES.md"
reject --harness codex --target "$tmp/conflict"
[[ ! -e "$tmp/conflict/.codex" && $(cat "$tmp/conflict/QUALITY_GATES.md") == custom ]]
ln -s "$tmp/claude" "$tmp/link"
reject --harness codex --target "$tmp/link/child"
mkdir "$tmp/nested-link"
ln -s "$tmp/claude" "$tmp/nested-link/.codex"
reject --harness codex --target "$tmp/nested-link"
reject --harness codex --target /
reject --harness codex --target /etc --dry-run
reject --harness codex --target "$tmp/repo/output"
reject --harness codex --target "$tmp/repo/../output"
reject --harness codex --target ''
reject --harness invalid --target "$tmp/invalid"
reject --target
reject --unknown
reject </dev/null
mv "$tmp/repo/coding/QUALITY_GATES.md" "$tmp/missing"
reject --harness codex --target "$tmp/missing-source"
[[ ! -e "$tmp/missing-source" ]]
mv "$tmp/missing" "$tmp/repo/coding/QUALITY_GATES.md"
ln -s "$tmp/missing" "$tmp/repo/coding/.codex/link"
reject --harness codex --target "$tmp/source-link"
[[ ! -e "$tmp/source-link" ]]
rm "$tmp/repo/coding/.codex/link"
mkdir "$tmp/bin"
printf '#!/usr/bin/env bash\nexit 1\n' > "$tmp/bin/cp"
chmod +x "$tmp/bin/cp"
PATH="$tmp/bin:$PATH" reject --harness codex --target "$tmp/copy-failure"
[[ -z $(find "$tmp/copy-failure" -type f -print) ]]
printf 'Installer regression checks passed.\n'
