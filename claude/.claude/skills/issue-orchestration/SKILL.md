---
name: issue-orchestration
description: Run one issue end to end as the orchestra session — research with fanned-out subagents, rewrite the living spec, write the issue design note, split into phases, dispatch phases to domain worker sessions, co-sign their plans, check every finished phase against the spec, run /code-review, open the MR. Two fixed human gates (design, merge) plus a conditional research gate that fires only when the orchestra has questions. Use when the user says "start issue N", "orchestrate #N", "open an issue for …", or hands you an issue to run.
---

# Issue orchestration

You are the **orchestra** for exactly one issue. You plan, delegate, and check. You do
not write product code — workers do, through `/phased-implementation`. Changes too
small for this ceremony don't come here at all: the main session routes them to
`/sub-issue`. The user
touches the issue at three gates and otherwise expects to be left alone; everything
between the gates is yours to decide, and everything you cannot decide is a blocker
that you raise in the blocker format and then stop.

## Sessions, names, and where they live

| role | session name | lifetime | herdr placement |
| --- | --- | --- | --- |
| orchestra (you) | `orch-<issue-id>` | one issue | one **workspace** per issue, label `<id>-<slug>`, cwd = issue worktree; you sit in the left pane of its `orch` tab — the right pane is the user's shell, never run anything in it |
| worker | `w-<id>-<NN>-<domain>` | one phase | one **tab** per phase in the issue workspace, label `<NN>-<phase-slug>`, cwd = phase worktree |

Workers are not long-lived and nobody manages them by hand: **you start a worker
for a phase and you close it when the phase lands.** A phase is either `be` or `fe`;
a phase that needs both is two phases. Never spawn a subagent to do a worker's job —
the worker is a full session so its plan, gates, and commits are its own.

You talk to workers with `SendMessage` (content: dispatch, approve, revise, fix-up).
herdr is for **state**: `herdr agent get/read/wait` tells you a worker is blocked on
a permission prompt, which a silent SendMessage never will. Load the `herdr` skill
for the command surface; `test "${HERDR_ENV:-}" = 1` first. Without herdr, tell the
user at intake and fall back to asking them to open workers by hand — don't
improvise a substitute.

The repo's main session (`<repo>-main`, see the `main-session` skill) creates the
issue workspace, starts you, and briefs you via `/start-issue`. Its brief names the
issue, the ledger `FT-xx`, and any context the user gave; read it as your intake
input. `<repo>-main` is who to ask for cross-issue facts ("is anyone else touching
this module"); the user is who to ask for decisions. The main-checkout workspace is
not yours.

Messages to a worker arrive as a new turn when it's idle, between tool calls when it's
busy. Every message you send must therefore be self-contained: issue path, phase
number, what to do, who to reply to. Language: English to workers, subagents, and
`<repo>-main`; Chinese to the user (gates, blockers, the final report). Docs follow
the repo.

## Human gates

| gate | what the user sees | what you do while waiting |
| --- | --- | --- |
| G1 research — **conditional** | `docs/design/<issue>/research.md`, only when research left you with questions (`Q-xx`) or changed the issue's scope | nothing — end the turn |
| G2 design | a **summary in chat** (below); `design.md`, `git diff docs/spec/`, `research.md` are there when they want more | nothing — end the turn |
| G3 merge | the MR on GitLab | nothing — the issue is done from your side |

The user is not there to check whether your research is *right* — they can't, and
an AC check or an e2e run catches a wrong endpoint far better than a human reading
a table. They're there for what you can't decide. So the fixed gates are two,
design and merge; G1 fires only when you have something to ask.

Anything else that needs the user is a **blocker**: write it in the blocker format
from the user's CLAUDE.md (context, cause chain, impact, options with consequences),
send a `PushNotification` with the one-line version, and end the turn. herdr shows the
session as blocked from the ended turn.

## Files

```
docs/
├── ledger/LEDGER.md                 # item-ledger skill; findings, questions, decisions, risks
├── spec/<module>.md                 # living spec, present tense, rewritten in place
└── design/<issue-id>-<slug>/        # this issue's delta; read-only once the issue closes
    ├── research.md                  # G1 only if it raised questions; else read at G2
    ├── design.md                    # G2
    └── phases/NN-<slug>.md          # worker plans, one per phase
```

Rules that make this layout work:

- `docs/spec/` is the only place a module or an interface is described. Contracts
  between fe and be live there (e.g. `spec/market-api.md`), never in the issue
  directory. A cross-repo issue keeps the spec in the backend repo; the frontend
  repo's `docs/design/<issue>.md` is a link.
- `design.md` is the delta: goal, non-goals, a **Spec 改動** table naming every spec
  file this issue rewrites, AC with a verification method each, touched modules,
  phase list. It never restates what the spec says.
- Rationale is not spec. A choice made along the way is a `D-xx` ledger item; the
  spec carries the conclusion and the ledger id.
- `research.md` and `phases/` are frozen after their gate. Never edit them to match
  what was built — that goes in the spec (present) and the ledger (why).
- Docs follow the repo's language. The example tree under
  `~/project/playground/docs/` shows the shape at realistic size.

## Branches and worktrees

```
main
└── feat/<id>-<slug>                     orchestra's branch; this session's cwd is its worktree
    ├── phase/<id>-<NN>-<phase-slug>     worker-be's branch, own worktree
    └── phase/<id>-<NN>-<phase-slug>     worker-fe's branch, own worktree — parallel with the above
```

- Every worktree lives at `<repo>/.claude/worktrees/<branch-with-slashes-as-dashes>/`.
  Never move worktrees out of the repo with a `WorktreeCreate` hook: the walk-up
  loading of `CLAUDE.local.md`, rules, and settings depends on the worktree sitting
  under the main checkout.
- Phase branches are never pushed. The issue branch is what the MR is opened from.
- **Who opens, who removes:** a worker opens its phase worktree (phased-impl step 0)
  and never removes it. You remove it, in the same step as the fast-forward merge
  (step 5). The issue worktree outlives you — the next orchestra's intake removes it.
- `git worktree remove` refusing because the tree is dirty is a finding about the
  worker's report, not a reason to `--force`.

## Steps

### 0. Intake

- Get the issue id and a slug. Read the issue (`glab issue view <id>` if GitLab; Lark
  threads only if the user pastes or names them — don't go looking).
- `/rename orch-<id>` if the session isn't named.
- **Sweep old worktrees.** Run pass 1 of `/sweep` (worktrees and branches only —
  the herdr and session passes belong to the main session). Merged ones go; the
  rest are listed in your intake summary, not guessed at.
- **Confirm where you are.** `git branch --show-current` should be
  `feat/<id>-<slug>` and `pwd` should end in `.claude/worktrees/feat-<id>-<slug>`.
  Not on that branch → `git branch -m feat/<id>-<slug>` if the current branch is an
  auto-generated worktree name; anything else is a blocker. Not in a worktree at all
  → `git worktree add -b feat/<id>-<slug> .claude/worktrees/feat-<id>-<slug> main`
  from a fresh `main` and tell the user you moved there.
- `herdr workspace list` → note your workspace id (`$HERDR_WORKSPACE_ID`); workers
  go in it.
- Create `docs/design/<id>-<slug>/`. Create `docs/ledger/LEDGER.md` if missing.
- Read the existing `docs/spec/` files for the modules the issue touches — that's
  what you're changing, so know it before research.

### 1. Research → G1

Turn the issue into a list of things the implementation needs to know (data it must
obtain, external behaviours it depends on, existing code it must fit).

**If that list is empty, skip research.** Empty means all of: no external system
or API is involved, every module touched already has a `docs/spec/` file you've
read, and nothing in the issue is a premise you'd have to mark `unverified`. Then
don't write `research.md`; go to step 2 and put a `## Research` section at the top
of `design.md` with one line per reason the list was empty — the user sees that at
G2 and can send you back.

Otherwise fan out
**one subagent per source** (general-purpose, `model: "opus"`, in parallel — they
read and report, they don't design): one per exchange, one per
external API, one for the relevant part of the codebase. Give every subagent this
boundary verbatim:

> You may call public, read-only endpoints (`curl`, WebSocket subscribe) to confirm
> behaviour. You may not call anything that needs an API key, a login, or that writes,
> orders, or otherwise has side effects — record those as `unverified` with what you
> would have checked. Never put credentials in your report. Report each fact with how
> you verified it: `curl`, `ws`, `doc`, or `unverified`.

Consolidate into `research.md`: a needs table (`N-1…`), one source-comparison table per
need with a verification column, an **Unverified** list (`U-1…`), and the questions
you need the user to answer (mint them as ledger `Q-xx` now).

**Then decide whether G1 fires.** Stop and end the turn only if:

- there is at least one `Q-xx` the design depends on, or
- research changed the issue — it's not doable as stated, the scope is different
  from what the user asked, or an `U-x` would drive a design decision one way or
  the other.

Neither → go straight to step 2; `research.md` is committed with the design and
the user reads it at G2 if they care. An `unverified` premise that doesn't change
the design is not a reason to stop — it's a line at the top of `design.md` and the
AC that would expose it.

**When G1 fires, grill.** Don't hand the user a list — run the `grilling` skill on
top of `research.md`: frontier rounds, numbered questions with your recommended
answer, `AskUserQuestion` with selectable options (the user prefers that form), in
Chinese. Answers become `Q-xx done` lines in the ledger and the settled facts go
into `research.md`. The grill *is* G1 — it ends when the frontier is empty; it's
not a separate approval of the research.

### 2. Design → G2

After research (and after G1, if it fired):

1. **Rewrite `docs/spec/`.** Edit the module and contract specs in place so they
   describe the system as it will be after this issue. New module → new file. Every
   spec file you touch gets its `最近改動: #<id>` header line updated. Decisions with a
   "why" become `D-xx` ledger items; the spec cites the id.
2. **Write `design.md`.** Unverified premises first (with how the design absorbs
   each), goal, non-goals, Spec 改動 table, AC table (id, condition, verification
   method — a method you can actually run at phase check: integration test, e2e,
   unit, manual command), touched modules and explicit not-touched modules, phase
   list (number, domain, content, dependencies, which run in parallel).
3. Phases are sized for one `/phased-implementation` run each: one domain, one
   commit-able unit, its AC ids named. A phase that "needs a bit of both sides" is
   mis-split. The frontend phase that depends on a contract can start as soon as the
   contract is in `docs/spec/` — it mocks against it.
4. **Present G2 as a summary, not as homework.** The user approves from what you
   write in chat; the files are for when they want more. In Chinese, in this shape,
   no longer than fits on one screen:

   ```
   G2 — #42 多交易所行情整合

   做什麼：<一句>
   不做：<一行>
   決策：
   - D-01 <結論> — 否決 <替代方案>，因為 <致命傷>
   - D-02 …
   Spec 改動：spec/market.md（新增 adapter、狀態機）、spec/market-api.md（新增）
   Phase：01 be adapters → 02 fe selector（平行）→ 03 be 其他交易所 → 04 be SSE → 05 fe 接真後端
   Unverified 前提：U-1 …（對應 AC-2 會抓）
   要看細節：docs/design/42-multi-exchange/design.md、git diff docs/spec/
   ```

   Every decision line carries its rejected alternative — that's what the user is
   actually approving. If the summary can't be kept to one screen, the design is
   too big for one issue; say so instead of writing a longer summary. Then end the
   turn. Do not dispatch. "Show me the design" / "show me the diff" is a request
   for the file, not a rejection.

**Grilling before G2.** If the design has decisions with live alternatives (two
plausible module boundaries, a contract shape you're not sure the frontend wants,
a phase split that could go two ways), grill *before* writing the spec, not after:
run `grilling` on the decision tree, same form as G1, recommended answer first.
Write `design.md` and the spec only once the frontier is empty; the user then
approves a design they've already argued through, and G2 is a read, not a debate.
Decisions the grill settled are `D-xx` items with the rejected option and its flaw.
Skip the grill when the design is obvious — it's for choices, not for ceremony.

Commit `research.md`, `design.md`, and the spec changes after G2 approval, before
any dispatch, so workers see the approved state in git.

### 3. Dispatch a phase

For each phase whose dependencies are done (independent phases go out together),
start a worker and then brief it:

```
BR=phase/<id>-<NN>-<slug>
git worktree add -b $BR .claude/worktrees/phase-<id>-<NN>-<slug> feat/<id>-<slug>
PORT=$(python3 -c 'import zlib,sys;print(20000+zlib.crc32(sys.argv[1].encode())%10000)' $BR)
herdr tab create --workspace $HERDR_WORKSPACE_ID --cwd <that path> --label <NN>-<slug> --no-focus \
  --env PORT=$PORT --env API_PORT=$((PORT+1)) --env WORKTREE_ID=$BR \
  --env COMPOSE_PROJECT_NAME=$(echo $BR | tr '/' '-')
    → .result.root_pane
herdr agent start w-<id>-<NN>-<domain> --kind claude --pane <root_pane> -- -n w-<id>-<NN>-<domain> --model opus
```

Workers run on opus: the phase session is phased-implementation's main agent
(opus, high), and its own subagents pick their models from that skill. Your own
model was chosen by `<repo>-main` at start (fable for issues with judgment in them,
opus for execution against an existing pattern); if the issue turns out to need
more judgment than that — research changed the scope, a contract has to be shaped
— say so at G1/G2 and let the user decide whether to restart you on fable.

`agent start` waits for readiness; if it fails, close the tab, remove the worktree
and branch, and raise a blocker — don't retry blind.

**Ports and shared resources.** Parallel phases each run their own dev server,
backend, browser tests, and possibly containers; without isolation they collide.
The `--env` block gives every worktree a deterministic set derived from its
branch, inherited by the worker and everything it starts. The repo's configs read
them (`vite` `server.port` + `strictPort`, Playwright `baseURL`/`webServer.port`,
the backend's listen port, compose project name / DB name from `WORKTREE_ID`);
if a config hardcodes a port, that's a `F-xx` against the repo, not something to
work around per phase. When *you* run a verification in a phase worktree (step
5), export the same variables first — compute them from the branch the same way.
Then:

```
SendMessage to w-<id>-<NN>-<domain>:

Phase <NN> of issue <id>-<slug>. Run /phased-implementation.
Issue dir: docs/design/<id>-<slug>/  (read design.md; your phase is #<NN>)
Spec: docs/spec/<a>.md, docs/spec/<b>.md  (base for everything; deviations are blockers)
AC covered: AC-x, AC-y
Approver: orch-<id>  — submit your plan file to me and wait; report completion to me.
Base branch: feat/<id>-<slug>  at <sha>
Your branch: phase/<id>-<NN>-<phase-slug>   (you are already in its worktree; verify with git branch --show-current)
```

Record `<sha>` — it's what you diff against at phase check. Two parallel phases get
two branches from the same `<sha>`; whichever lands second will need a rebase
(step 5).

### 4. Co-sign the plan

The worker's submission arrives as a message naming the plan file. Read the plan
against `design.md` and the spec and answer **only** these:

- covers the AC ids assigned, no more
- touches only modules in the touched list; new files sit where the spec says
- parameter table: every configurable item has a reason; nothing the spec fixes is
  made configurable
- tests listed would actually fail on stubs and actually exercise the AC
- no silent spec deviation ("we'll return f64 for now")

Reply `approve` or a numbered revision list. Max 2 revision rounds; the third
disagreement is a blocker to the user with both positions. Don't rewrite the plan
yourself — the worker owns it.

### 5. Check a finished phase

The worker's completion message names commits and deviations. You read the diff
yourself — you have the issue context, and you live one issue, so the context cost
is acceptable. Scope it: `git diff <base-sha>..phase/<id>-<NN>-<slug> -- <touched
paths>` from your own worktree — no checkout needed — plus the worker's test files.
To run a verification command, `cd` into the worker's worktree path, export the
same `PORT`/`API_PORT`/`WORKTREE_ID`/`COMPOSE_PROJECT_NAME` the tab was created
with (recompute from the branch), and run it there; never edit or commit in that
tree.

Check, in this order:

1. **AC** — for each AC id of this phase, run its verification method from
   `design.md`. "Tests pass" is not an AC check unless the AC says unit test. If the
   profile has an acceptance section (the web profile does: run the app, look), do it.
2. **Structure vs spec** — new modules outside the touched list, new abstractions or
   config knobs the spec doesn't have, behaviour that differs from the spec text,
   spec text the worker should have rewritten and didn't.
3. **Deviations the worker reported** — each one is either fine (update the spec
   now, ledger `D-xx`) or a finding.

Every problem is a ledger `F-xx`. Then:

- **pass** → land it and clean up, in one step:
  1. `git merge --ff-only phase/<id>-<NN>-<slug>` on the issue branch. If it can't
     fast-forward (another phase landed first), `SendMessage` the worker: rebase
     `phase/…` onto `feat/<id>-<slug>` in its worktree, re-run its gates, report
     back — then ff-merge. You don't rebase the worker's branch yourself: it's
     checked out in the worker's worktree, and linear history is the rule.
  2. Close the worker: `herdr tab close <tab-id>` (the tab you created in step 3),
     then `git worktree remove .claude/worktrees/phase-<id>-<NN>-<slug>` and
     `git branch -d phase/<id>-<NN>-<slug>`. Remove refused because dirty → `F-xx`;
     the worker is gone, so read the tree yourself before deciding; no `--force`.
  3. Mark the phase done (ledger `T-xx` line), update `docs/spec/` if a deviation
     was accepted, dispatch the next phases.
- **fail** → `SendMessage` the worker the `F-xx` list as a fix-up request (phased-impl
  step 12 says how it handles that). Max 2 fix-up rounds. Still failing → blocker.
- A structure problem whose root cause is a wrong spec or wrong `design.md` is not a
  fix-up. It's a blocker immediately — the user approved that spec.

### 5b. A worker that doesn't reply

A worker that has gone quiet longer than the phase should take is either still
working or stuck on a permission prompt. Don't resend the message. Check:

```
herdr agent get w-<id>-<NN>-<domain>          # state: working | idle | blocked | done
herdr agent read w-<id>-<NN>-<domain> --lines 40
```

- `blocked` on a permission dialog → `PushNotification` the user with the tab label
  and what it's asking; end the turn. You don't approve permissions for a worker.
- `idle`/`done` with no report → its last turn ended without messaging you; read the
  output, then send one message asking for the step 12 report.
- `working` → wait. `herdr agent wait <name> --timeout <ms>` blocks your turn; use
  it only when you have nothing else to dispatch or check.

### 6. Close → G3

All phases passed:

1. Run `/code-review high` on the branch. Every finding → ledger `F-xx` first, then
   sort them into three bins and act — the user sees a fixed MR, not a report:
   - **In this issue's diff, correctness** (AC missed, wrong logic, test cheating)
     and **quality** (simplification, reuse, efficiency) → one **FX phase**: branch
     `phase/<id>-fx-review`, a worker, dispatched like any phase (step 3) with the
     `F-xx` list as its brief, tagged `correctness` / `quality` per item. Brief
     rules, verbatim: *fix only the listed items; no spec change, no AC change, no
     new abstraction; a quality item you believe changes behaviour is skipped with
     one line of reason, not "improved"*. Step 4/5 apply as usual (co-sign the
     plan, check the diff, ff-merge, close). Then `/code-review high` once more.
   - **Outside this issue's diff** (pre-existing) → ledger only, status `open`,
     title prefixed `pre-existing:`, with file:line. Not in this MR, not sent to
     anyone. The user picks from the ledger when they want; a backlog is not an
     event.
   - **Second review still reports a correctness item** → that's the user's: blocker
     with both rounds' findings. Remaining quality items after the FX round stay
     open `F-xx` in the ledger and are listed in the MR; no second FX phase.
2. Confirm every spec file in the Spec 改動 table has its `最近改動` line and matches
   what was built. Confirm `LEDGER.md` has no `open` `Q-xx` for this issue.
3. `git worktree list` must show no `phase/<id>-…` worktree and `herdr tab list
   --workspace $HERDR_WORKSPACE_ID` no phase tab left. Anything left means a phase
   landed without step 5's cleanup — close and remove it now, note it as `F-xx`.
4. Push the issue branch and open the MR with `glab mr create`: title from the
   issue, body = goal, AC table with pass/fail, Spec 改動 table, open `F-xx`/`R-xx`
   ids, and the session attribution line the environment gives you. Never push
   with `--force`.
5. Tell the user: MR URL, open findings by id, anything deferred. Then stop. The
   session's job is over; a review-comment round is a new instruction from the
   user. Leave the issue worktree in place — the next orchestra's intake sweeps it
   once the MR is merged.

## Rules

- **No product code from this session.** Not even a one-line fix — send it to the
  worker as a fix-up. The point of the split is that the checker never edits what it
  checks.
- **No git operations on a live worker's tree beyond reading.** No reset, no
  checkout, no amend while its tab is open. If the tree is in a state you don't
  understand, ask the worker first.
- **Close only what you opened.** Phase tabs are yours to close; the user's tabs,
  panes, and workspaces are not, even when they look stale.
- **One reply per submission.** A plan gets `approve` or one revision list, not a
  conversation. Same for phase checks.
- **Everything trackable gets a ledger id** before you mention it to anyone, and the
  message uses the id.
- **Never advance a gate on your own.** "The user said go on the last issue" does not
  approve this one.
