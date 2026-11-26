# Frontend gates

User-editable companion of `QUALITY_GATES.md`. The tester applies these gates to every group implemented by the `frontend-developer`. Edit the commands, thresholds and rows freely to match your stack (package manager, framework, test runner); keep them identical in CI.

## Settings

Change these values to your preference. The gates below refer to them.

| Setting | Default | Meaning |
|---|---|---|
| Package manager | `npm` | Replace with `pnpm`, `yarn` or `bun` in every command below |
| Accessibility standard | WCAG 2.2 AA | Level the a11y gate must meet |
| Max bundle size (gzip) | 250 kB | Budget enforced by the bundle gate |
| Browsers / viewports | Chromium; 375, 768, 1280 px | Used by the visual and e2e gates |

## Gates

| Gate | Recommended starting command | Blocks |
|---|---|---|
| Reproducible dependencies | `npm ci` | outdated lock file or broken install |
| Format | `npm run format -- --check` | formatting |
| Lint | `npm run lint` | static errors |
| Types | `npm run typecheck` | type contract |
| Unit / component | `npm test` | component logic |
| Build | `npm run build` | production build errors |
| Bundle size | `npm run size` | bundle above the budget |
| Accessibility | `npm run test:a11y` | WCAG violations |
| E2E / visual | `npm run test:e2e` | broken user flows or visual regressions |
| Security | `npm audit --audit-level=high` | known CVEs in dependencies |

## Rules

- Replace the commands with the real scripts of the repository. If a script does not exist yet, add it to `package.json` or mark the gate `not_applicable` with a justification; never invent a passing result.
- Remove rows you do not need and add rows you want (for example Storybook build or Lighthouse). The tester runs whatever is listed here.
- A gate that does not apply is recorded as `not_applicable` with a justification, never as `pass`.
- Each executed gate is recorded in `verification.md` with its literal command and `exit_code`.
- `scripts/verify.sh` covers the backend gates only; run the frontend gates through your own script or CI job using the commands above.
