---
name: sweep
description: Clean up what the issue workflow leaves behind in a repo — merged worktrees and branches, orphaned herdr phase tabs, finished issue workspaces, dead or forgotten Claude sessions. Acts only on what is provably done; lists everything else. Use when the user says "sweep", "clean up worktrees", "what's left over", or at the start of a main session's day; the orchestra runs the worktree part at intake.
---

# Sweep

Three passes, each with a hard line between **act** (provably done, remove it) and
**list** (anything else, show it with what you'd need to know). Run pass 2's
workspace closes before pass 1's worktree removals — a workspace's cwd is its
worktree. Never cross the
line because something "looks stale". Print one report at the end; nothing else.

Run from the repo's main checkout (`git rev-parse --show-toplevel` is the repo,
branch `main`). `git fetch --prune` first so "merged" means merged upstream.

## 1. Worktrees and branches

```
git worktree prune
git worktree list --porcelain
git branch --merged origin/main
```

- **act:** a linked worktree whose branch is in the merged list →
  `git worktree remove <path>` then `git branch -d <branch>`. If remove refuses
  (dirty), don't force: move it to the list with `git -C <path> status --short`.
- **act:** a branch in the merged list with no worktree, matching `feat/`, `fix/`,
  `chore/`, `phase/` → `git branch -d`.
- **list:** every other linked worktree: path, branch, ahead/behind `origin/main`,
  dirty or clean, and whether a session has it as cwd (`claude agents --json`).
- **list:** a worktree whose directory name doesn't match its branch name
  (`feat-42-x` vs `feat/47-y`) — flag it; that's the old mess, and someone has to
  say which name is right.
- Anything under `$ROOT/.claude/worktrees/` that `git worktree list` doesn't know
  about is a stray directory → list with size; don't delete.

## 2. herdr

Skip if `test "${HERDR_ENV:-}" = 1` fails. `herdr workspace list`, then per
workspace `herdr tab list --workspace <id>` and `herdr agent list`.

- **act:** a tab labelled `NN-<slug>` (a phase tab) whose `phase/…` branch no
  longer exists → `herdr tab close <tab-id>`. The phase landed; the orchestra
  missed its cleanup.
- **act:** an issue workspace (label `<id>-<slug>`) whose `feat/<id>-<slug>` branch
  is merged into `origin/main` and whose `orch-<id>` is `idle` or gone → `herdr
  workspace close <ws-id>`. Main opened it (`/start-issue`), so main closes it; the
  orchestra can't close the room it's sitting in. Do this *before* pass 1 removes
  the issue worktree — the workspace's cwd is that worktree. Order: close
  workspace → remove worktree → delete branch.
- **list:** an issue workspace whose branch is merged but whose orch is `working`
  or `blocked` — something's still happening there; show it.
- **list:** any pane in `blocked` state, with the agent name — someone is waiting on
  a permission prompt.
- Never close a workspace you can't tie to a merged issue branch, and never a tab
  you can't tie to a merged phase branch.

## 2b. Leftovers — only from what this run swept

Scope: the issues **this run** just cleaned up — the workspaces closed in pass 2
and the `feat/` worktrees removed in pass 1, nothing else. An issue whose cleanup
happened in an earlier run is done with; its `ledger.md` keeps its leftovers and
nobody re-reads them. Listing every merged issue's leftovers on every sweep turns
the report into a backlog that gets skimmed and then ignored — the whole point is
that a leftover surfaces once, at the moment its issue is put away.

For each of those issues, read `docs/design/<id>-<slug>/ledger.md` on `main` (it
survives the worktree removal) and take its `## Leftovers` items that aren't
already marked `dropped — moved to …`:

- **list:** each item as an `L-n` row carrying its source id, `L-1 59/R-01 —
  <title>`. Sweep never writes ledgers; the re-mint is main's, per `main-session`
  step 5: a new repo-level id on the `chore/ledger` branch citing `59/R-01`, and
  the issue line closed `dropped — moved to R-07`. End the report by naming that
  as the next action when any `L-` row exists — this is the only place a merged
  issue's leftovers ever surface, so a sweep that lists them and says nothing
  loses them. No issue cleaned up this run → no `Leftovers` section in the
  report, not an empty one.

## 3. Sessions

```
claude agents --json --all
```

- **list:** entries with a `pid` and kind `background`, idle, older than a day:
  name, pid, cwd, started. The user kills; you don't (`kill <pid>` is one line for
  them, and a background session may be something they're about to resume).
- **list:** entries without a `pid`: dead records; say they can be removed from the
  `claude agents` view.
- `ListAgents`: an `orch-<id>` whose issue branch is merged — say so.

## Report

```
Swept:
- closed workspace 59-venue-follows-pair (MR merged, orch idle)
- removed worktree <path> (branch <b>, merged)
- closed tab <label> in <workspace>
Leftovers to re-mint (mine):
- L-1 59/R-01 — playwright reuseExistingServer picks up another worktree's dev server
- L-2 60/F-08 — pre-existing: deviation copy duplicated in two components
Left for you:
- W-1 <path> — <branch>, 3 ahead, dirty, cwd of market-worker
- S-1 pid 50930 data-market-main — bg, idle 7d, /Users/…/feat-data-market
```

Numbered so the user can answer "W-1 remove, S-1 kill, L-2 drop". `L-` rows are
yours to act on unless the user says drop: re-mint them on `chore/ledger` in the
same turn, then say which ids they became. Nothing swept and nothing left → say
exactly that in one line.
