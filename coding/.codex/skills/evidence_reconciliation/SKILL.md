---
name: evidence-reconciliation
description: "Trigger: evidence conflict, context summary, repeated verification loop. Reconcile observations and continue safely without redundant checks."
license: Apache-2.0
metadata:
  author: "pedroortizortega"
  version: "1.0"
---

## Activation Contract

Use this skill when:

- a context summary conflicts with a newer observation;
- the agent repeatedly verifies the same fact;
- context compression causes the agent to restart discovery;
- uncertainty about prior evidence blocks the pending action.

## Hard Rules

Treat a context summary as a working-state snapshot, not as an
inherently untrusted source or a permanent source of truth.

Reuse a summarized fact without verification when:

- it identifies the exact resource relevant to the current action;
- no later state-changing operation could have invalidated it;
- no newer observation contradicts it;
- its precision is sufficient for the current decision.

Verify a summarized fact only when:

1. A newer observation contradicts it.
2. A state-changing operation occurred after it was observed.
3. The fact is volatile and the current action depends on it.
4. The summary marks it as uncertain, stale, incomplete, or inferred.
5. An incorrect value could cause destructive or irreversible consequences.

## Evidence Precedence

Apply precedence only when observations refer to the same resource,
scope, and property:

1. A newer direct observation outranks an older direct observation.
2. A direct observation outranks an inference based on older data.
3. A summarized fact remains valid until contradictory evidence or a
   relevant state-changing event invalidates it.
4. A newer but unrelated observation does not invalidate a summarized fact.

## Contradiction Resolution

After resolving a contradiction:

- adopt the winning observation as the canonical fact for the current turn;
- do not verify it again unless a subsequent mutation or new contradictory
  evidence occurs;
- continue the pending action instead of restarting discovery.

## Loop Breaker

- Perform at most one verification attempt per disputed fact, unless
  that attempt fails or produces incomplete evidence.
- Never repeat the same tool call with the same target and purpose
  unless a relevant state change has occurred.
- If uncertainty remains, state it explicitly and choose the safest
  reversible action.
- Do not treat context compression alone as evidence that previous
  discovery must be repeated.

## Output Contract

Report:

- the contradiction that was evaluated;
- the observation selected as canonical;
- any remaining uncertainty;
- the pending action that should continue.
