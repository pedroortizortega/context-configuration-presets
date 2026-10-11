#!/usr/bin/env bash
# Codex PreToolUse hook for Bash: block git merge when it would land on main/master.
# Merges on feature/worktree branches remain allowed; merging into main/master is
# a human decision.
set -uo pipefail

input="$(cat)"
command="$(jq -r '.tool_input.command // empty' <<<"$input")"
cwd="$(jq -r '.cwd // empty' <<<"$input")"

# This hook only decides merge commands.
grep -Eq '\bgit\b.*\bmerge\b' <<<"$command" || exit 0

block() {
  jq -cn \
    --arg reason "Blocked: merging into main/master is not allowed for agents. Ask the user to perform or explicitly authorize the merge." \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $reason}}'
  exit 0
}

# Catch commands that switch to main/master and merge in the same shell input.
grep -Eq '(checkout|switch)[[:space:]]+(-[A-Za-z-]+[[:space:]]+)*(main|master)\b' <<<"$command" && block

# `git -C <dir> merge ...` targets <dir>; otherwise use the hook event cwd.
dir="$(sed -nE 's/.*git[[:space:]]+-C[[:space:]]+([^[:space:]]+).*/\1/p' <<<"$command")"
dir="${dir%\"}"
dir="${dir#\"}"
dir="${dir:-$cwd}"

branch="$(git -C "${dir:-.}" branch --show-current 2>/dev/null || true)"
[[ "$branch" == "main" || "$branch" == "master" ]] && block

exit 0
