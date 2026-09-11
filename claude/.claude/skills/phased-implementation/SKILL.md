---
name: phased-implementation
description: Plan-then-delegate workflow for implementing one well-scoped unit of work (a phase, a ticket, a feature slice) with a plan-file approval gate (the user, or the dispatching orchestra session), a skeleton-first checkpoint, subagent implementation, automated quality gates, and a bounded revert-and-retry loop. Stack-specific toolchain and review criteria come from a profile under profiles/. Use when the user asks to "implement phase N", "build this ticket", or wants a disciplined implement-review-commit cycle instead of freehand coding.
---

# Phased implementation workflow

A unit of work goes through: understand → plan → approve → skeleton → checkpoint →
delegate → verify → (retry or accept) → wrap up. The point of the ceremony is that
mistakes get caught before they're expensive to unwind: the plan gets an approver's eyes
before code exists, the skeleton locks the test contract before an agent can bend it,
and every implementation attempt has a clean commit to fall back to.

Don't skip steps to save time — the steps are what make delegating the actual coding
to a subagent safe. If the user explicitly asks for a lighter-weight pass, drop back
to normal ad-hoc implementation and say so, rather than silently thinning this out.

## Core vs. profile

This file is the stack-agnostic process. Everything that depends on the language or
toolchain — what a stub looks like, which formatter/linter/test commands are the
gates, what the reviewer should look for, what counts as acceptance — lives in a
profile under `profiles/`. Steps below say **[profile]** wherever they defer to it.

Available profiles:

| profile              | marker         |
| -------------------- | -------------- |
| `profiles/rust.md`   | `Cargo.toml`   |
| `profiles/web.md`    | `package.json` |

**Profile selection (do this before step 1):**

1. If the user named a profile (in the skill args or the request — "use the rust
   profile", `/phased-implementation rust`), use that one. It wins over any marker
   file, no confirmation needed. If the named profile doesn't exist under
   `profiles/`, say so and stop; don't fall back to marker detection.
2. Otherwise look for a marker file at the repo root or the touched package's root.
   Exactly one match → load that profile and follow it. More than one → ask which.
3. No match → stop and tell the user there's no profile for this stack; offer to
   (a) write one first, or (b) run the workflow with a toolchain the user spells
   out inline. Don't silently guess commands for an unprofiled stack.

## Model/effort per role

- **Main agent** (steps 1-6, 8, 10-12 — planning, organizing, gating): opus, high effort.
- **Implementation subagent** (step 7): sonnet, medium effort.
- **Review subagent** (step 9): opus, high effort.

Set these via the `model`/`effort` params on the `Agent` call (or workflow `agent()`
opts) when launching each subagent — don't leave them defaulted.

## Steps

0. **Confirm the worktree.** Dispatched: you were started inside the phase
   worktree; `git branch --show-current` must equal the branch the dispatch names
   and `git status --porcelain` must be empty. Anything else → report it to the
   approver and stop; don't fix it by creating or switching worktrees. Never remove
   the worktree or close your own session when you're done: the approver does both
   when it lands the phase. Standalone: work in the tree you were started in; don't
   open a worktree unless the user asks.

   Language: dispatched, your reader is the approver session — write everything
   in English (plan file excepted: docs follow the repo's language). Standalone,
   the user's CLAUDE.md rule applies (replies in Chinese).

1. **Read the requirement.** Pull the specific target for this unit of work — not the
   whole spec/PRD, just the scoped piece being implemented now (e.g. one phase entry
   from an implementation plan, one ticket). If a pass-criteria list exists, it's the
   contract for step 5's tests and step 9's review.

2. **Explore the codebase.** Find existing patterns this work should follow — adjacent
   modules, naming conventions, how similar things were tested. Use a read-only agent
   (Explore / general-purpose) if the codebase is large enough that this would burn
   significant context inline.

3. **Write the plan file.** Do not enter plan mode — the plan is a file that gets
   submitted, so it can be reviewed by another session and lands in git with the
   checkpoint. Path:
   - dispatched under an issue (the dispatch message names the issue directory):
     `docs/design/<issue>/phases/NN-<slug>.md`, `NN` from the phase list in that
     issue's `design.md`
   - standalone (the user asked directly, no issue directory): `docs/plans/<slug>.md`

   Header lines: what this phase is, who the approver is, and a `status:` line
   (`submitted <date>` now; updated in step 4). Then:
   - which acceptance criteria (AC ids) and which `docs/spec/` files this phase
     covers — the approver checks the plan against those, so name them
   - what changes, file by file
   - a table of every hardcoded parameter this will introduce vs. every configurable
     one — this table is the point where "should this be configurable?" gets decided
     deliberately instead of by accident. **[profile]** lists the categories that
     typically show up for the stack.
   - the tests to be written in step 5, one line each
   - open questions / assumptions the plan is making

   The plan follows the repo's language for docs. Write it as the plan, not as a
   proposal — no "we could" alternatives; open questions go in their own section.

4. **Submit and wait for approval.** Never proceed past this point on your own.
   - **Dispatched:** `SendMessage` the approver named in the dispatch: the plan file
     path, a 3–5 line summary, and the open questions. Then **end the turn** — the
     reply arrives as a new turn. `approve` → set `status: approved by <approver>
     <date>` in the plan header and continue to step 5. A revision request → update
     the plan file, resubmit, end the turn again. After 2 revision rounds without
     approval, stop and tell the approver you're stuck; don't keep iterating.
   - **Standalone:** give the user the same summary in chat and end the turn; their
     reply is the approval. Same status line, same revision cap.

   Treat the approval as real — if the approver pushes back, revise and re-present
   rather than partially proceeding.

5. **Write the implementation skeleton and tests.** Signatures, module structure, and
   a test suite that encodes the pass criteria from step 1 — tests should fail
   against stub bodies, not pass vacuously. The subagent in step 7 implements
   *against* this contract; it should not need to (and should not be able to
   justify) changing test intent to make its own code pass. **[profile]** says what
   a stub looks like and how the tests are organized for the stack.

6. **Commit as checkpoint.** Include the approved plan file. This is the revert
   target for the retry loop. Commit message should make clear it's a skeleton, not
   a finished implementation.

7. **Launch a subagent to implement** (sonnet, medium effort). Give it the plan, the
   skeleton, the test file locations, and the profile's implementation guidance
   **[profile]**. Tell it explicitly: tests define correctness, don't edit them to
   make them pass. On a retry (see step 10), also give it the prior attempt's review
   findings so it doesn't repeat the same mistake.

   **When the subagent returns, commit its output immediately as an attempt commit**
   (message like `wip: attempt N — <unit>`) before running any gate. From here to
   step 11 the working tree must be clean. This is what makes steps 8-9 safe: any
   probe that temporarily edits source (mutation checks, commenting out a branch to
   see which test catches it) can be undone with `git restore <file>` and lands
   back on the attempt, not on the skeleton. An uncommitted attempt plus a
   `git checkout`/`git restore` to undo a probe silently erases the implementation
   — this has happened; don't run gates on an uncommitted tree.

8. **Fast check** (gate — must pass to continue):
   - `git status --porcelain` is empty (the attempt is committed — see step 7).
   - `git diff <checkpoint-sha>..HEAD` : confirm test files and skeleton signatures
     are unchanged (or changed only in ways step 1's contract allows). An agent
     quietly loosening an assertion or deleting an inconvenient test case is the
     single most common way this kind of delegation goes wrong — check for it
     explicitly, don't assume good faith.
   - the profile's format / lint / test commands **[profile]**, scoped to the touched
     package(s) — don't run a full-workspace pass every iteration if the project is
     large enough that it's slow.

9. **Launch a subagent to review** (opus, high effort; gate — must pass to continue).
   Focus areas common to every stack:
   - over-engineering (abstractions, config knobs, or generality beyond what step 1
     asked for)
   - test-cheating (weakened assertions, deleted cases, tests that assert on mocks
     instead of behavior, tautological tests)
   - **pass-criteria compliance**: does the implementation actually satisfy step 1's
     pass criteria, not just "does it compile and pass its own tests" — a subagent
     grading its own contract can miss criteria the tests didn't encode

   Plus the profile's stack-specific review criteria **[profile]** — paste them into
   the review prompt rather than summarizing them.

   **Mutation checks by the reviewer** (deliberately breaking the implementation to
   confirm a test fails) are a legitimate way to catch tautological tests, but put
   these rules in the review prompt verbatim:
   - Before the first mutation, run `git status --porcelain`; if it is not empty,
     do not mutate — report the dirty tree as a finding instead.
   - Undo each mutation with `git restore <that file>` (or by reversing the exact
     edit), never `git checkout .`, `git checkout <branch>`, `git stash`, or
     `git reset`. Those operate on the whole tree, and the reviewer has no way to
     know what else is in it.
   - After the last mutation, `git status --porcelain` must be empty again and
     `git diff HEAD --stat` must print nothing. Include that output in the report.
   - Never commit a mutation. Never amend.

10. **If either gate (8 or 9) fails**: `git reset --hard <checkpoint-sha>` — this drops
    the attempt commit and nothing else, because the tree was clean — and retry from
    step 7, attaching the specific failure findings to the retry prompt.
    **Cap retries at 2.** If it still fails after 2 retries, stop — surface the
    findings to the user instead of looping again. A workflow that can loop forever
    on the same mistake is worse than one that asks for help.

11. **Finalize the accepted implementation** once both gates pass: reword the `wip:`
    attempt commit into a proper message (`git commit --amend` is fine here — it
    only touches the attempt commit, which is HEAD). It stays a separate commit from
    the step-6 checkpoint — never squash into or amend the skeleton commit.

12. **Wrap up inline** (no subagent). Report briefly — to the approver via
    `SendMessage` when dispatched, to the user in chat when standalone: the commits
    created (shas), any **deviations** from the plan or from `docs/spec/` (one line
    each — these live only in this session's head and are cheap to capture now; a
    behaviour change you did not rewrite into the spec is itself a finding, say so),
    and any **deferred/out-of-scope items** with one line of reason each. Don't
    produce a structure overview, test map, or coverage analysis here — the approver
    does its own AC and structure check on the diff with fresh eyes, and a
    self-report adds nothing. End the turn here; don't keep going to the next unit
    of work without being asked.

    A **rebase request** from the approver ("another phase landed first") arrives
    as a new turn: `git rebase <base-branch>` in your worktree, resolve conflicts
    against `docs/spec/` (the spec wins, not either branch), re-run step 8's gates,
    report the new HEAD. No merge commits.

    A **fix-up request** from the approver (findings from its phase check) arrives as
    a new turn. Treat it as one more step 7 attempt with the findings attached: the
    accepted-so-far HEAD is the new checkpoint, so commit the fix-up as its own
    `wip:` attempt, run steps 8–9, and on failure reset to that HEAD, not to the
    original skeleton. Same retry cap.

## Notes on destructive steps

Step 10's revert touches uncommitted-vs-committed state — follow the repo's git
safety norms (check `git status` first, never force-push, never revert past the
step-6 checkpoint into the user's own prior work). If the checkpoint commit and the
failed attempt are the only things being discarded, a plain `git reset --hard
<checkpoint-sha>` is fine; if anything else landed in the tree meanwhile, stop and
ask rather than guessing what to keep.

The other destructive operation in this workflow is any `git checkout`/`git restore`
used to undo a temporary probe. It is only safe when the thing being probed is
committed. The invariant across steps 7-11 is therefore: **implementation committed
first, probes second, tree clean after each probe.** If you ever find yourself about
to `git restore` a file that has uncommitted work in it, stop — the correct move is
to commit (or at minimum `git stash push -- <file>` after confirming what's in it),
not to restore.

## Writing a new profile

A profile is one markdown file under `profiles/` with these sections, in this order,
so the core steps can point at them by name:

1. **Marker** — the file whose presence selects this profile.
2. **Parameter table categories** (step 3).
3. **Skeleton conventions** (step 5) — stub form, test layout, what "fails against
   the stub" means for this stack.
4. **Implementation guidance** (step 7) — stack-specific instructions to paste into
   the implementation subagent's prompt.
5. **Fast check commands** (step 8) — format, lint, test, in gate order, with the
   scoping flag for a single package.
6. **Review criteria** (step 9) — stack-specific items to paste into the review
   prompt, each with a one-line "why" so the reviewer can tell signal from noise.
7. **Acceptance** — anything beyond "tests pass" that counts as done for this stack
   (e.g. run the app and look at it).
