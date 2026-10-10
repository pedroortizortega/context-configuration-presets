#!/usr/bin/env bash
# PreToolUse hook for Bash: blocks `git merge` when it would land on main or master.
# Merges inside feature/worktree branches stay allowed; merging into main/master is a human decision.
# Exit code 2 blocks the command and shows the message to Claude.
set -uo pipefail

input="$(cat)"
command="$(jq -r '.tool_input.command // empty' <<<"$input")"
cwd="$(jq -r '.cwd // empty' <<<"$input")"

# Not a merge: nothing to check.
grep -Eq '\bgit\b.*\bmerge\b' <<<"$command" || exit 0

block() {
  echo "Blocked: merging into main/master is not allowed for agents. Ask the user to do it or to authorize it explicitly." >&2
  exit 2
}

# Switching to main/master in the same command, then merging.
grep -Eq '(checkout|switch)[[:space:]]+(-[A-Za-z-]+[[:space:]]+)*(main|master)\b' <<<"$command" && block

# `git -C <dir> merge ...` targets <dir>; otherwise the hook's cwd.
dir="$(sed -nE 's/.*git[[:space:]]+-C[[:space:]]+([^[:space:]]+).*/\1/p' <<<"$command")"
dir="${dir:-$cwd}"

branch="$(git -C "${dir:-.}" branch --show-current 2>/dev/null || true)"
[[ "$branch" == "main" || "$branch" == "master" ]] && block

exit 0
