---
name: sweep
description: Clean up what the issue workflow leaves behind in a repo — merged worktrees and branches, orphaned herdr phase tabs, finished issue workspaces, dead or forgotten Claude sessions. Acts only on what is provably done; lists everything else. Use when the user says "sweep", "clean up worktrees", "what's left over", or at the start of a main session's day; the orchestra runs the worktree part at intake.
---

# Sweep

Three passes, each with a hard line between **act** (provably done, remove it) and
**list** (anything else, show it with what you'd need to know). Never cross the
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
- **list:** an issue workspace (label `<id>-<slug>`) whose `feat/<id>-<slug>` branch
  is merged: it's done, but it's the orchestra's — say "close it" and let the user.
- **list:** any pane in `blocked` state, with the agent name — someone is waiting on
  a permission prompt.
- Never close a workspace, and never a tab you can't tie to a merged branch.

## 2b. Leftovers from merged issues

For every `docs/design/<id>-<slug>/` whose `feat/<id>-<slug>` branch is merged and
whose `ledger.md` has a `## Leftovers` section with items not yet marked `dropped —
moved to …`:

- **list:** each item as `<id>/R-01 — <title>`, so main (or the user) can say
  "re-mint" or "drop". Sweep never writes ledgers.

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
- removed worktree <path> (branch <b>, merged)
- closed tab <label> in <workspace>
Left for you:
- W-1 <path> — <branch>, 3 ahead, dirty, cwd of market-worker
- S-1 pid 50930 data-market-main — bg, idle 7d, /Users/…/feat-data-market
```

Numbered so the user can answer "W-1 remove, S-1 kill". Nothing swept and nothing
left → say exactly that in one line.
