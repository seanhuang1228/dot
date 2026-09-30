---
name: sweep
description: Clean up what the issue workflow leaves behind in a repo — merged worktrees and branches, orphaned herdr phase tabs, finished issue workspaces, dead or forgotten Claude sessions. Acts only on what is provably done; lists everything else. Use when the user says "sweep", "clean up worktrees", "what's left over", or at the start of a main session's day; the orchestra runs the worktree part at intake.
---

# Sweep

Three passes, each with a hard line between **act** (provably done, remove it) and
**list** (anything else, show it with what you'd need to know), plus pass 2b, which
closes the books of the issues the first two passes just put away — the one pass
that writes files. Run pass 2's workspace closes before pass 1's worktree removals
— a workspace's cwd is its worktree. Never cross the
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

## 2b. Close the books — only for the issues this run swept

Scope: the issues **this run** just cleaned up — the workspaces closed in pass 2
and the `feat/` worktrees removed in pass 1, nothing else. An issue cleaned up in
an earlier run had its books closed then and its `ledger.md` is already gone;
there is nothing to re-read. Closing the books is mechanical, so it happens once,
at the moment the issue is put away.

For each of those issues, read `docs/design/<id>-<slug>/ledger.md` on `main` (it
survives the worktree removal) and send **every** item to its destination per the
close table in `item-ledger`. No "deserves to outlive the issue" judgment, no
`dropped` rows, nothing ignored. Every `D` travels; for the other classes only
`open` and `blocked` rows do (a `done` row was finished inside the issue and has
nothing left to carry):

- `D` → append verbatim to `docs/ledger/decisions.md` under `## #<id> <slug>`
  (create the section, issues in ascending order), id unchanged: `8/D-31` stays
  `8/D-31`, because spec and code already cite it.
- `T`, `FT`, `I` → the repo's task system if it has one — the repo's `CLAUDE.md`
  names the integration and the skill that drives it: create each as a Task in
  Triage through that skill, citing `8/T-01`. Nothing named → lift verbatim into
  `LEDGER.md`, ids unchanged, exactly like `D`.
- `R`, `F` → re-mint in `LEDGER.md` with a new repo id, the line citing its
  source: `R-36 open — <title> (8/R-03)`,
  `F-12 open — pre-existing: <title> (8/F-07)`. Carry the `pre-existing:` marker
  across exactly as the issue line has it — the orchestra decided that at mint
  time and nothing here can re-derive it.
- `Q` still `open` → tracked nowhere. One row in the report for the user. The
  orchestra is supposed to have closed these at G3, so an open one is a finding
  about that issue, not a backlog item.
- A `## Leftovers` section appears only in ledgers written before 2026-09-30; it
  duplicates rows already handled above — skip it, don't process an item twice.

Then empty the directory of everything that was working material:

```
git rm -r docs/design/<id>-<slug>/ledger.md docs/design/<id>-<slug>/research.md \
          docs/design/<id>-<slug>/research/ docs/design/<id>-<slug>/phases/
```

`design.md` stays and is the only thing that stays — it is the issue's durable
record (goal, AC, Spec 改動 table, touched modules, phase list), and the
cross-issue questions main answers read exactly that. Everything else was written
to be read once, by a gate or a worker that no longer exists: nobody has ever
reused another issue's research, and a landed phase plan has no reader at all.
Git history keeps all of it, and `design.md`'s links into `research/` go dangling
— that is accepted, the file is frozen and the links resolve in history.

`R` and `F` never go into the GitLab issue tree or the task system — not
actionable, so as child items they hold the tree open forever and a
stale-activity patrol reports them every run.

All of it — both ledger files and the deletion — is one commit on main's rolling
`chore/ledger` branch, in the same batch and MR as every other ledger edit
(`main-session` step 5). Nothing is pushed to `main`. This is the one pass where
sweep writes: it runs inside the main session, which is the only writer of those
files.

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
Books closed:
- #59 venue-follows-pair — 9 items; ledger.md, research/, phases/ deleted
  59/D-04, 59/D-05 → decisions.md
  59/R-01 → R-36   59/F-08 → F-12 (pre-existing)
  59/T-02 → Task "wire OpenAPI client" (Triage)   59/I-01 → Task (Triage)
Open at close (tracked nowhere):
- Q-1 59/Q-02 — orderbook 一定要 20 檔？orchestra closed G3 with it open
Left for you:
- W-1 <path> — <branch>, 3 ahead, dirty, cwd of market-worker
- S-1 pid 50930 data-market-main — bg, idle 7d, /Users/…/feat-data-market
```

`Books closed` is a receipt, not a request: the mapping is already written and
committed on `chore/ledger` when you print it, one line per item so the user can
audit the close without opening either file. No task system in the repo → the
`T`/`FT`/`I` lines read `→ LEDGER.md (id kept)` instead of `→ Task`. `W-`/`S-`/`Q-`
rows are numbered so the user can answer "W-1 remove, S-1 kill". Nothing swept and
nothing left → say exactly that in one line.
