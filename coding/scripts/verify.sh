#!/usr/bin/env bash
# Runs the local quality gates of QUALITY_GATES.md in order and stops at the first failure.
# Keep the commands identical to QUALITY_GATES.md and to CI, so every environment proves the same thing.
# UPPERCASE tokens (e.g. CONTRACT_TESTS_PATH) are placeholders: replace them once per project, or skip the gate.
#
# Usage:   bash scripts/verify.sh
# Skip:    SKIP_GATES="integration,contract" bash scripts/verify.sh
#          A skipped gate is reported as NOT_APPLICABLE; justify it in verification.md, never as a pass.
set -uo pipefail

SKIP_GATES="${SKIP_GATES:-}"

# One compose project per checkout, so parallel worktrees do not collide on container or network names.
export COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-verify-$(basename "$PWD")}"

# name|command
GATES=(
  "dependencies|uv sync --frozen"
  "format|uv run ruff format --check ."
  "lint|uv run ruff check ."
  "types|uv run mypy src tests"
  "unit|uv run pytest -m 'not integration and not e2e'"
  "integration|docker compose -f INTEGRATION_COMPOSE_FILE up --build --abort-on-container-exit --exit-code-from INTEGRATION_SERVICE"
  "security|uv run bandit -r src && uv run pip-audit"
  "contract|uv run pytest CONTRACT_TESTS_PATH"
)

is_skipped() {
  [[ ",${SKIP_GATES}," == *",$1,"* ]]
}

for gate in "${GATES[@]}"; do
  name="${gate%%|*}"
  command="${gate#*|}"

  if is_skipped "$name"; then
    echo "GATE ${name} NOT_APPLICABLE (skipped via SKIP_GATES)"
    continue
  fi

  if [[ "$command" =~ [A-Z]{2,}_[A-Z_]+ ]]; then
    echo "GATE ${name} NOT CONFIGURED: replace the UPPERCASE placeholder in this script and in QUALITY_GATES.md, or skip it with SKIP_GATES=${name}"
    exit 2
  fi

  echo "GATE ${name} RUN: ${command}"
  bash -c "$command"
  exit_code=$?
  echo "GATE ${name} exit_code=${exit_code}"

  if [[ $exit_code -ne 0 ]]; then
    echo "GATE ${name} FAILED; stopping."
    exit "$exit_code"
  fi
done

echo "ALL APPLICABLE GATES PASSED"
