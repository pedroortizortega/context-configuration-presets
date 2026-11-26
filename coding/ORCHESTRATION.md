<orchestration>

<state_machine>
The project manager maintains `ops/change-state/<change>.yaml` (`feature-delivery` creates it and sets `INTAKE`, `SPEC_READY` and `spec_approved_by_human`; after that only the project-manager writes it). No agent may skip a status.
Group `status` in the file is the lowercase mirror of the global one: `implementing`, `judging`, `verifying`, `rework`, `done` (plus `pending`, `blocked`).

`INTAKE -> SPEC_READY -> HUMAN_SPEC_APPROVED -> IMPLEMENTING -> JUDGING -> VERIFYING -> READY_FOR_HUMAN -> ACCEPTED`

`REWORK` (judge `rework` or failing tests, back to `IMPLEMENTING`) and `BLOCKED` (2 fix loops exhausted and no planner decision, or a missing precondition) can be entered from any working state.

| Status | Set when | Set by |
|---|---|---|
| `INTAKE` | The ticket is received and the state file is created | `feature-delivery` (or the project-manager if the file is missing) |
| `SPEC_READY` | OpenSpec artifacts are complete and waiting for human approval | `feature-delivery` |
| `HUMAN_SPEC_APPROVED` | The user explicitly approves the artifacts (`spec_approved_by_human: true`, which `feature-delivery` may set earlier) and the execution plan | project-manager, only after an explicit yes |
| `IMPLEMENTING` | The implementer starts a group (also after `REWORK`) | project-manager |
| `JUDGING` | The implementer returned `pass` and the judge reviews the branch | project-manager |
| `VERIFYING` | The judge returned `pass` and the tester runs the tests and the gates | project-manager |
| `READY_FOR_HUMAN` | Every group passed judge and tester, and every applicable gate of `QUALITY_GATES.md` has a literal `exit_code: 0` | project-manager |
| `ACCEPTED` | The user approves the result | project-manager, only after an explicit yes |

`status` is the status of the group in progress; a group moves through `IMPLEMENTING -> JUDGING -> VERIFYING` and the next group starts again at `IMPLEMENTING`.
If the spec changes, go back to `SPEC_READY` and clear `spec_approved_by_human`.
No code is written before `HUMAN_SPEC_APPROVED`.
</state_machine>

<workflow>
0. planner -> execution plan and micro tasks for the change, plus any decisions visible upfront.
   The plan assigns an `agent` to every group (see step 1). Show the plan to the user and wait for approval. Then set `HUMAN_SPEC_APPROVED` in `ops/change-state/<change>.yaml`
   and store the plan summary in `groups` (including each group's `agent`) and `decisions`.

Then work task group by task group (the `## N.` sections of `tasks.md`):
1. Assign the implementer. The planner decides it in the plan; the project-manager never decides it. The project-manager copies each group's
   `agent` to `groups[].agent` in the state file and invokes that agent. In this workflow, **implementer** means the agent assigned to the group:
   - `frontend-developer`: only when every micro task of the group is UI/UX (components, pages, styles, visual assets, client-side interaction and its rendering).
   - `developer`: everything else (services, data, APIs, scripts, configuration).
   - A group that mixes both is split by the planner into separate groups. If the UI consumes an API that is new, the backend group runs first and the
     frontend group branches from the updated base.
   - If the planner cannot classify a group, it is a USER_APPROVAL decision.
2. implementer -> implements the group's micro tasks in its worktree. Status `IMPLEMENTING`.
3. judge -> status `JUDGING`; reviews that branch against the group's micro tasks and scenarios.
   - For a `frontend-developer` group, the judge also checks the `front-design` review checklist: every component maps to a user goal in the spec
     (Occam's razor), accessibility basics, and no unjustified weight (dependencies, assets, requests).
   - `rework`: status `REWORK`, increment `rework_cycles` and the group's `fix_loops`, send the implementer back,
     pointing to the judge's handoff file. Maximum 2 fix loops; after that, send the handoff paths to the
     planner and act on its decision.
   - Any subagent reports a spec ambiguity: send it to the planner; do not let the implementer guess.
4. tester -> status `VERIFYING`; merges the implementer branch into its worktree, writes/runs one test per micro task
   and runs the applicable gates of `QUALITY_GATES.md`, recording literal commands and exit codes in `verification.md`.
   - Failing tests caused by production code go back to the implementer (status `REWORK`), counting toward the same 2-loop limit.
   - For a `frontend-developer` group, the tester records the applicable frontend checks (accessibility, build, bundle size) as gates with a literal command and
     `exit_code`, or as `not_applicable` with a justification, as defined in `QUALITY_GATES_FRONTEND.md`.
   - A tester `pass` is valid only if its handoff lists every applicable gate with its real `exit_code`; otherwise treat it as `rework`.
5. Tick a task ID in `tasks.md` only when all of its micro tasks passed judge and tester.
6. Update the group's fields and link its handoffs in `ops/change-state/<change>.yaml`, then give the user a short status in Spanish.
7. Ask the user to authorize merging the group's branches into `base_branch` (from the state file)
   (`--ff-only` when possible). Merge only after an explicit yes; the next dependent group branches from the updated base.
8. Continue with the next group.

Designer: it has two callers, never both on the same files at the same time (never two designers, nor a designer and an implementer, on the same files concurrently).
- The project-manager may launch it directly for a group that is purely visual/design (no logic), in a worktree and branch it assigns under the normal group worktree rules.
- The frontend-developer may launch it inside its own worktree and branch (no new worktree), sequentially, never in parallel with its own edits.
Its brief reuses the Change, Read first, Your task, Branch, Constraints and Handoff sections of `<delegation_brief>`; its handoff file is `<group>-designer[-loopN].md`
in the same handoff directory, with `role: designer`. When the frontend-developer launches it, the frontend-developer returns both handoff paths and the designer's open
questions and asset briefs in its final message, and the project-manager links both files in `handoffs` of the state file without reading them. When the
project-manager launches it, it already knows the path.

Parallelism follows the approved plan: independent groups run their implementer in parallel (one Agent
call per group in the same message); dependent groups run sequentially.

When all groups pass, set `READY_FOR_HUMAN`, ask the planner for an integration proposal and present it to the user.
Never push, rebase or delete branches, and never merge without explicit user approval.
</workflow>

<role_independence>
- Planner: converts design/specs into small, ordered, testable tasks. Fills `test-plan.md` from its template.
- Architect: validates boundaries, contracts, data, compatibility and threats before code. Fills `threat-model.md` from its template.
- Implementer: the `developer` (non-frontend tasks) or the `frontend-developer` (UI/UX tasks, may call the `designer`) assigned to the group. Implements approved tasks, without widening the scope.
- Designer: designs the visual layer, launched by the project-manager (design-only groups) or by the frontend-developer (inside its worktree and branch).
- Tester: writes or improves tests, runs the gates and reproduces the acceptance criterion. Fills `verification.md` with literal evidence, one section per group.
- Judge: compares code and evidence against the specs; may only recommend `pass`, `rework` or `blocked`.
- Project manager: coordinates; never accepts a change the judge has not approved.
</role_independence>

<worktrees>
Worktrees are created manually by the project manager (not by subagent isolation), under `.claude/worktrees/`:
`git worktree add .claude/worktrees/<unique-name> -b <branch> <base>`.
- Branch names: implementer (when launched by the frontend-developer, the designer commits on its branch; a design-only group gets its own branch) `feat/<change>/gN-<slug>`, tester `feat/<change>/gN-tests`.
- Worktree names must be new and unique; never reuse a removed worktree name.
- `<base>` is `base_branch` from the state file (confirmed with the user in preflight; it must NOT be `main`/`master` because the merge hook blocks merges there, so use an integration branch such as `integration/<change>`), or the branch named in the approved plan for dependent groups.
</worktrees>

<delegation_brief>
Never send a subagent without the minimum context. Every brief MUST contain these sections:

````
## Change
<change-name> — one-sentence goal from proposal.md

## Read first
- <absolute path to proposal.md>
- <absolute path to design.md>
- <absolute path to tasks.md>
- <absolute paths to the relevant specs/**/spec.md>
- <absolute path to ops/change-state/<change>.yaml>
- <absolute paths to the per-run handoff files this task depends on (e.g. the judge's FAIL findings), or "none">

## Your task
<exact task IDs and their text, e.g. 4.1–4.3>
<the planner's micro tasks for those IDs: micro ID, description, acceptance criterion, test>
<requirements and scenarios this covers, quoted or referenced by name>

## Branch
<implementer/tester: worktree path + branch you work on (+ implementer branch to merge, for tester)>
<judge: implementer branch + base branch to diff against + worktree path>

## Constraints
- Spec-driven: implement only what the spec and these task IDs require. If the spec is ambiguous or
  incomplete, stop and report it instead of guessing.
- Follow the project rules in AGENTS.md and the gates in QUALITY_GATES.md.
- Follow existing code patterns in the repo; do not refactor unrelated code.
- Work only inside the worktree given above. The only file you may write outside it is your handoff file.
- Never push, merge into the base branch, or add Co-Authored-By trailers to commits.

## Handoff file
Write your full output and HANDOFF to: <absolute path, e.g. .../handoffs/<change>/g2-developer.md or g2-frontend-developer.md>
The file starts with the YAML block below, followed by the prose HANDOFF (see <handoff>).

## Handoff YAML block
```yaml
change: <kebab-case>
role: planner|architect|developer|frontend-developer|designer|tester|judge
decision: pass|rework|blocked
inputs_read: []
artifacts_written: []
requirements_covered: []
commands_run:
  - command: <literal>
    exit_code: 0
    summary: <literal>
risks: []
open_questions: []
```
A `pass` without artifacts, commands or evidence is invalid and must be treated as `rework`.

## Final message
Return only: status (`done|pass|rework|blocked`), branch, handoff file path (a frontend-developer also returns the designer handoff path(s) and the designer's open questions and asset briefs), and items the project-manager
must act on (ambiguities, USER_APPROVAL options, failing micro IDs). Maximum 10 lines.
````
</delegation_brief>
<handoff>
Every subagent writes its HANDOFF into its handoff file, produced from this prompt. Include it verbatim in every brief:

"Summarize this session so that another person can continue it without reading anything above.
You must include:
- The goal and how it changed during the session
- The concrete data that was established (figures, names, rules)
- The decisions made and their reason
- What we tried and did not work, so it is not repeated
- The instructions or preferences I gave you that are still in force
- The concrete next step
Write it in Spanish, in the second person, addressed to whoever will continue."

If a subagent returns without writing its handoff file, ask it to write it before moving on.
Do not read per-run handoff files yourself unless you need a specific fact to route a decision.
</handoff>

</orchestration>
