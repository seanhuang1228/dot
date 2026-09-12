---
name: sub-issue
description: Run a change that is too small for an issue — one package, no spec impact, provable by a test — in a single throwaway session from code to green gates to an MR, with no orchestra and no design gate; the user only reviews the MR. Invoked from the main session with a one-line description (`/sub-issue "fix …"`), and loaded again by the spawned session to do the work. Use when the user says "sub-issue", "quick fix", "just fix …", or the main session judges a request small.
---

# Sub-issue

Two halves, same file. The **main session** checks the definition coarsely, spawns a
session, briefs it. The **sub session** checks the definition precisely, does the
work, opens the MR, reports. Nobody designs, nobody reviews except the MR reader.
The whole point is that the definition below is strict enough that "just the MR"
is a safe amount of human attention.

## Definition — all five, checked twice

| | criterion | main checks by | sub session checks by |
| --- | --- | --- | --- |
| C1 | **one package** — every changed file sits under one profile root (one crate, one `package.json` directory) | reading the request | `git diff --name-only main` → one common package root |
| C2 | **no spec impact** — `docs/spec/` untouched, and no file on the repo's contract list (default below) | reading the request | diff touches none of the contract paths |
| C3 | **no new module, no new dependency** — no files in a directory that didn't exist; `Cargo.toml` / `package.json` dependency sections unchanged (a pure version bump is its own kind of sub-issue and may touch exactly those lines) | reading the request | `git diff main -- '**/Cargo.toml' '**/package.json'` empty, or version-bump-only; no new directories |
| C4 | **provable** — a bug fix ships with a test that is red on `main` and green after; a chore (rename, message text, lint, version bump, docs outside `docs/spec/`) ships with the existing suite green | is there something to assert? | run the new test against `main` (stash-free: `git stash` is banned — use `git worktree add` of `main` in `/tmp` or `git show main:<file>`) and record the failure |
| C5 | **nothing to research** — no external system behaviour to confirm, no premise you'd mark unverified | reading the request | if you find yourself opening docs or curling an API, stop |

Default contract list (C2), overridable by a `## Contract files` section in the repo's
`CLAUDE.md`:

```
docs/spec/**   **/*.proto   **/migrations/**   **/openapi*   **/routes*   **/api/**
**/config.rs   **/config.ts   **/errors.rs   **/error-codes*
```

Signals it is **not** a sub-issue: an "and" in the description, a refactor across
modules, a new endpoint or field, a migration, behaviour a user would notice. Any
one of those → `/start-issue`, no discussion.

**Time box:** two failed gate runs, or an hour, and the sub session stops: commits
what exists as `wip:`, reports "not a sub-issue — stuck on Cx / <reason>", and the
main session offers `/start-issue`. Never grind.

## Main session half

1. Coarse-check C1–C5 from the description and a one-minute look at the code. Any
   doubt → `/start-issue` instead; the cost of being wrong here is a session that
   has to abort, so don't stretch the definition.
2. If the user named a GitLab issue, keep its id; otherwise no issue is created —
   the MR is the record.
3. Branch and worktree (absolute path, under the repo):
   ```
   ROOT=$(git rev-parse --show-toplevel)
   git worktree add -b fix/<slug> "$ROOT/.claude/worktrees/fix-<slug>" main
   herdr tab create --workspace $HERDR_WORKSPACE_ID --cwd "$ROOT/.claude/worktrees/fix-<slug>" --label sub-<slug> --no-focus
   herdr agent start sub-<slug> --kind claude --pane <root_pane> -- -n sub-<slug> --model <opus|sonnet>
   ```
   `fix/` for bug fixes, `chore/` for the rest (branch-naming rule). Slug ≤ 4 words.
   **Model from the request, opus or sonnet, never fable:** `sonnet` for chores —
   rename, message text, lint, version bump, docs, a config value; `opus` for a
   fix that needs a red test and a reason. If the user named one, that wins.
4. Brief, one `SendMessage`:
   ```
   Sub-issue <slug> — load /sub-issue and do the sub-session half.
   Request: "<verbatim>"
   Kind: fix | chore | version-bump
   Package: <path>          Branch: fix/<slug>  (you're in its worktree)
   GitLab issue: #<id> or none
   Report to: <repo>-main
   ```
5. When the report comes back (MR URL or abort), `herdr tab close <tab-id>`. Leave
   the worktree: `/sweep` removes it once the branch is merged. Tell the user the
   MR URL, or the abort reason and that `/start-issue` is the next step.

## Sub-session half

0. `git branch --show-current` matches the brief; `git status --porcelain` empty.
   Everything you write is read by a session or lands in git — English throughout,
   MR text in the repo's language.
1. Re-check C1–C5 against the actual code, precisely. Fail → report to main and
   stop; don't "do it anyway, it's small".
2. **Test first** (fix kind): write the test, run it, it must fail; keep the failure
   output. Chore kind: note which existing suite is the evidence.
3. Implement. Stay inside the package; if you need to step outside, that's C1
   failing — abort per the time box.
4. Gates, scoped to the package, from the profile under
   `phased-implementation/profiles/` that matches the package's marker: format,
   lint, test. Green or abort.
5. Mechanical diff check, exactly the right-hand column of the table, and paste the
   commands' output into the MR description. This is the only review there is.
6. Push the branch, `glab mr create` targeting `main`, title from the request, body:
   what and why (three lines), the red-then-green evidence (test name, failing
   output on `main`, green run), the C1–C5 checklist with the command outputs, the
   GitLab issue link if any, the session attribution line the environment gives
   you. Never `--force`.
7. `SendMessage` main: MR URL, package, files changed. End the turn. You'll be
   closed.

## What this skill never does

Design, spec edits, `/code-review`, opening a GitLab issue, merging, touching
another worktree, or growing past the definition because the fix "was almost
done". The definition is the safety; the moment it doesn't hold, the right output
is an abort, not a bigger MR.
