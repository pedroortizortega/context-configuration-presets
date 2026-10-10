# Mandatory local gates

Replace the commands with the real ones of the repository and keep them identical in CI.

| Gate | Recommended starting command | Blocks |
|---|---|---|
| Reproducible dependencies | `uv sync --frozen` | outdated lock file or broken install |
| Format | `uv run ruff format --check .` | formatting |
| Lint | `uv run ruff check .` | static errors |
| Types | `uv run mypy src tests` | type contract |
| Unit | `uv run pytest -m 'not integration and not e2e'` | logic |
| Integration | `docker compose -f INTEGRATION_COMPOSE_FILE up --build --abort-on-container-exit --exit-code-from INTEGRATION_SERVICE` | DB, queues and API |
| Security | `uv run bandit -r src && uv run pip-audit` | insecure patterns and CVEs |
| Contract | `uv run pytest CONTRACT_TESTS_PATH` | public API |

`scripts/verify.sh` runs these gates in order and stops at the first one that fails; CI must invoke the same script. To skip gates: `SKIP_GATES="integration,contract" bash scripts/verify.sh`.

UPPERCASE tokens (`CONTRACT_TESTS_PATH`, `INTEGRATION_COMPOSE_FILE`, `INTEGRATION_SERVICE`) are placeholders that are replaced once per project, in this file and in `scripts/verify.sh`. If they are left unreplaced, `verify.sh` fails with exit code 2 instead of running an invented command.

A gate that does not apply must be recorded as `not_applicable` with a justification; never as `pass`.

## Criteria for READY_FOR_HUMAN

All applicable gates pass; the tests cover the acceptance criteria; the judge approves; the diff contains no secrets; a local rollback exists and there is no critical debt or risk without an explicit acceptance from the user.
