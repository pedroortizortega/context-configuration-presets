# Gates locales obligatorios

Sustituya los comandos por los reales del repositorio y manténgalos idénticos en CI.

| Gate | Comando inicial recomendado | Bloquea |
|---|---|---|
| Dependencias reproducibles | `uv sync --frozen` | lock desactualizado o instalación rota |
| Formato | `uv run ruff format --check .` | formato |
| Lint | `uv run ruff check .` | errores estáticos |
| Tipos | `uv run mypy src tests` | contrato de tipos |
| Unitarias | `uv run pytest -m 'not integration and not e2e'` | lógica |
| Integración | `docker compose -f INTEGRATION_COMPOSE_FILE up --build --abort-on-container-exit --exit-code-from INTEGRATION_SERVICE` | DB, colas y API |
| Seguridad | `uv run bandit -r src && uv run pip-audit` | patrones inseguros y CVEs |
| Contrato | `uv run pytest CONTRACT_TESTS_PATH` | API pública |

`scripts/verify.sh` ejecuta estos gates en orden y se detiene en el primero que falla; CI debe invocar el mismo script. Para omitir gates: `SKIP_GATES="integration,contract" bash scripts/verify.sh`.

Los tokens en MAYÚSCULAS (`CONTRACT_TESTS_PATH`, `INTEGRATION_COMPOSE_FILE`, `INTEGRATION_SERVICE`) son marcadores que se reemplazan una vez por proyecto, en este archivo y en `scripts/verify.sh`. Si quedan sin reemplazar, `verify.sh` falla con exit code 2 en lugar de ejecutar un comando inventado.

Un gate no aplicable debe registrarse como `not_applicable` con justificación; nunca como `pass`.

## Criterio para READY_FOR_HUMAN

Todos los gates aplicables pasan; las pruebas cubren criterios de aceptación; el juez aprueba; el diff no contiene secretos; existe rollback local y no hay deuda o riesgo crítico sin una aceptación explícita de usted.
