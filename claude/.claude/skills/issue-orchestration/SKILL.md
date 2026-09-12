---
name: issue-orchestration
description: Run one issue end to end as the orchestra session — research with fanned-out subagents, rewrite the living spec, write the issue design note, split into phases, dispatch phases to domain worker sessions, co-sign their plans, check every finished phase against the spec, open the MR. Two fixed human gates (design, merge) plus a conditional research gate that fires only when the orchestra has questions. Use when the user says "start issue N", "orchestrate #N", "open an issue for …", or hands you an issue to run.
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
input — and that is the last message between you and main. **You never message
`<repo>-main`.** It's the session the user is talking to; a message from you
becomes a turn it runs on someone else's behalf mid-conversation. Cross-issue facts
("is anyone else touching this module") you read yourself: `docs/design/*/design.md`
touched-modules tables, `git worktree list`, `git branch -a`. Decisions you can't
make are the user's, via a blocker. What you leave behind at close is written into
your `ledger.md`, and main picks it up on its own schedule.

Messages you do receive: workers'. A worker may ask you a question mid-phase
(one message, options included) and you answer it — you hold the design, and your
tab is not the user's. That's the only upward channel in the tree.

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
├── ledger/LEDGER.md                 # repo-level ledger — main's; you never write it
├── spec/<module>.md                 # living spec, present tense, rewritten in place
└── design/<issue-id>-<slug>/        # this issue's delta; read-only once the issue closes
    ├── ledger.md                    # this issue's ledger — yours, the only writer
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
- **You are the only writer of this issue's `ledger.md`.** Workers report findings
  in their messages; you mint. Never touch `docs/ledger/LEDGER.md` — that's
  `<repo>-main`'s, and two branches writing it is exactly the collision the split
  exists to avoid. Commit ledger updates on the issue branch as you go; a phase
  branch that then can't fast-forward rebases at land time (step 5), docs-only.
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
- Create `docs/design/<id>-<slug>/` with an empty `ledger.md` (item-ledger format,
  `next:` all at 01). `docs/ledger/LEDGER.md` is not yours to create or edit.
- Skim the existing `docs/spec/` files for the modules the issue touches — headers
  and section titles (`grep '^#'`), not the full text. You need to know what exists;
  the planner (step 2) reads them in full. Your context holds decisions, not
  documents — measured 2026-09-11: orchestras that read research, spec, and entries
  into context sat at 200–230K per call for the whole issue.
- **Resuming?** If the brief says `Resume: yes`, the branch already carries work.
  Before anything else: `git log origin/main..HEAD --oneline`, `design.md`'s phase
  index, `ledger.md`, and `git worktree list` for `phase/<id>-*` branches. From
  those, decide per phase: landed (its commits are on the issue branch), in flight
  (a `phase/` branch exists with commits past the issue branch — check it with
  step 5 as if the worker had just reported; if the phase branch is on another
  machine and not pushed, it's lost: note it and re-dispatch), or not started.
  Then continue from the first non-landed phase, or step 6 if all landed. Behind
  `origin/main` → rebase first and rerun the gates; if that rewrites pushed
  history, the push at step 6.4 becomes the user's (force-with-lease). State what
  you found in one message to the user, then go on — no gate here.
- **Epic child?** If the brief names an epic plan and your entries (`PH-xx..PH-yy`),
  skip research and planning: your `design.md` is the epic's header plus your
  entries copied verbatim (they were approved with the epic), and you go straight
  to the G2 summary so the user sees which slice is starting. Then step 3 onward.

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
**one subagent per source** (general-purpose, `model: "sonnet"`, in parallel — they
read and report, they don't design; measured 2026-09-11: identical token profiles
cost 2.5× on opus for no decision made). Each writes its full report to
`docs/design/<id>-<slug>/research/<source>.md` and returns to you **at most 15
lines**: what it confirmed, what's `unverified`, questions for the user. You never
read the full reports; `research.md` links them. one per exchange, one per
external API, one for the relevant part of the codebase. Give every subagent this
boundary verbatim:

> You may call public, read-only endpoints (`curl`, WebSocket subscribe) to confirm
> behaviour. You may not call anything that needs an API key, a login, or that writes,
> orders, or otherwise has side effects — record those as `unverified` with what you
> would have checked. Never put credentials in your report. Report each fact with how
> you verified it: `curl`, `ws`, `doc`, or `unverified`.

Consolidate the summaries into `research.md`: a needs table (`N-1…`), per need one
line per source with its verification tag and a link to `research/<source>.md`
for the detail, an **Unverified** list (`U-1…`), and the questions you need the
user to answer (mint them as ledger `Q-xx` now). The per-source tables live in the
per-source files, written by the subagents — not in your context.

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

1. **Decide, then delegate the writing.** The spec rewrite and the phase entries
   are long-form documents; you don't hold them. You settle the decisions (`D-xx`
   in the ledger, one line each with the rejected alternative) from the research
   summaries and the issue, and hand them to the planner in step 3, which rewrites
   `docs/spec/` and writes the entries. Every spec file it touches gets its
   `最近改動: #<id>` header line; the spec cites `D-xx` ids, never restates the why.
2. **Write the top of `design.md`.** Unverified premises first (with how the
   design absorbs each), goal, non-goals, Spec 改動 table, AC table (id, condition,
   verification method — a method you can actually run at phase check: integration
   test, e2e, unit, screenshot, manual command), touched modules and explicit
   not-touched modules, and a one-line phase index.

   **A design mockup is spec.** When the issue comes with an HTML mockup (CSS
   included, opens in a browser), copy it verbatim into
   `docs/design/<id>-<slug>/mockup/` and list it under a `## Binding constraints`
   line in `design.md`. It is not a reference image: structure, spacing, colors,
   type sizes, copy — all come from it. A conflict between the mockup and the
   existing design system is a `Q-xx` for the user at G2, not a judgment call by
   anyone downstream. Every fe entry the planner writes cites the mockup file and
   the region it implements, and carries at least one visual AC:
   `AC-V<n>: at <viewport> the <screen/region> matches mockup/<file> (screenshot)`.
3. **Have a planner rewrite the spec and write the phase entries.** Launch one
   subagent (general-purpose, `model: "fable"`, high effort) with: the `D-xx`
   decisions, `design.md` so far, the paths of `research.md` and `research/`, the
   spec files to rewrite, and read access to the code. It (a) rewrites `docs/spec/`
   in place per the decisions, (b) writes the `## Phases` section of `design.md`:
   one **complete entry per phase**, in the shape below, so that a worker can start
   from the entry alone and a check subagent can judge the result against it
   alone, and (c) returns to you **only** the phase index (one line per phase:
   number, domain, one-liner, depends-on, `Parallel-ok`, `Thin` if so, and the
   entry's In-scope file paths — you paste those into the dispatch as `Start here`)
   plus the
   list of spec files it changed with one line each. You do not read the entries
   or the spec diff; `git diff --stat docs/spec/` is your check that it touched
   what the Spec 改動 table says. This is the planning cost of the issue, paid
   once, by one author — phases planned one at a time by different sessions drift
   from each other.

   ```
   ### PH-NN — <one line>
   Domain: be | fe            Depends on: PH-xx     Parallel-ok: no | yes (<why: disjoint packages>)
   Settles: D-xx …            Covers: AC-x, AC-y
   Goal: <one paragraph — the state of the system when this phase is done>
   In scope: <bullets, file/module level>
   Out of scope: <bullets, with the phase that owns each>
   Binding constraints: <spec sections / D-xx this phase must not violate>
   Parameters: | parameter | value | hardcoded / configurable | source |
   Skeleton contract: <files, signatures, fixtures, the tests that must be red on the stub>
   Acceptance: - AC-x: <condition> (<verification: unit | integration | e2e | manual cmd>)
   Doc sync: <spec sections to rewrite when this lands>
   ```

   An entry the planner cannot fill completely (a decision not yet made, an
   unknown it can't resolve) is marked `Thin: <what's missing>` at the top and gets
   a `D-xx pending` in the ledger. Thin entries are the only ones that get a plan
   co-sign later (step 4).

   Sizing rules the planner follows, and you enforce:
   - one phase = one `/phased-implementation` run: one domain, one commit-able
     unit. "A bit of both sides" is two phases.
   - **six phases is the cap.** More → this is an epic. Stop: rewrite the phase
     section as an epic plan grouping entries into child issues of ≤ 6 phases each,
     present that at G2, and end. On approval, move the plan to
     `docs/design/<id>-<slug>/plan.md`, commit, report "epic — start child issues
     from <repo>-main with `/start-issue … --epic <id> PH-01..PH-03`", and stop —
     you don't run an epic. Child orchestras read their entries from the epic plan
     instead of running step 3.
   - `Parallel-ok: yes` only when two phases touch disjoint packages and share no
     file. Everything else is sequential. Parallelism is not free — it's what the
     port isolation, rebase, and ledger rules exist to pay for.
4. **Present G2 as a summary, not as homework.** (Entries are what the user reads
   when they want detail; the summary's phase line names them.) The user approves from what you
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

Phases go out **one at a time, in order**. The next one starts when the previous
has landed (step 5). The only exception is a pair marked `Parallel-ok: yes` in
their entries — those may run together. Start a worker and brief it:

```
BR=phase/<id>-<NN>-<slug>
git worktree add -b $BR .claude/worktrees/phase-<id>-<NN>-<slug> feat/<id>-<slug>
ENV=$(worktree-env $BR $PORT_VARS)   # PORT_VARS from design.md's Ports: line; see below
herdr tab create --workspace $HERDR_WORKSPACE_ID --cwd <that path> --label <NN>-<slug> --no-focus \
  --env WORKTREE_ID=$BR --env COMPOSE_PROJECT_NAME=$(echo $BR | tr '/' '-') $ENV
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

**Ports and shared resources.** Parallel phases (and your own verification runs)
each start dev servers, backends, browser runners, maybe containers; without
isolation they collide. How many ports a project needs is the project's business,
so **the repo declares its port variables and you assign the numbers**:

- The list of port variables comes from **the repo's own docs**, wherever it keeps
  them — a dev-environment or ports doc under `docs/` or a package's `docs/`
  (e.g. `web/docs/spec/dev-ports.md`), a `.env.example`, the repo `CLAUDE.md`
  pointing at one of those. Find it at intake (`grep -rl -i 'port' docs */docs
  .env.example` and read the hit that lists variable names), and write the
  resulting names into your `design.md` header as `Ports: WEB_PORT API_PORT …` so
  every later step uses the same list. Don't invent variables the repo doesn't
  document, and don't require the repo to document them in any particular file.
  Nothing found → inject only `WORKTREE_ID` and `COMPOSE_PROJECT_NAME`, and say so
  in the dispatch ("repo documents no port variables; a server you need to start
  is an `F-xx` against the repo, not a number you pick").
- Assignment is a block per worktree, derived from the branch so it's the same
  every time anyone computes it:
  ```
  worktree-env() {  # $1 = branch, $2… = variable names; prints --env args
    local branch=$1; shift; local names=("$@")
    local n=${#names[@]}; [ $n -eq 0 ] && return
    local stride=$(( (n + 9) / 10 * 10 ))                       # 10, 20, …
    local base=$(( 20000 + $(python3 -c "import zlib,sys;print(zlib.crc32(sys.argv[1].encode())%(10000//$stride))" "$branch") * stride ))
    local i=0; for v in "${names[@]}"; do printf -- '--env %s=%s ' "$v" $((base+i)); i=$((i+1)); done
  }
  ```
  Ports land in 20000–29999, one contiguous block per worktree, variable *i* gets
  `base+i`. Everything the worker starts inherits them (verified 2026-09-11).
- The repo's configs read those variables and nothing else: `vite`
  `server.port` + `strictPort`, Playwright `baseURL`/`webServer.port`, the
  backend's listen ports, DB names and compose project from `WORKTREE_ID` /
  `COMPOSE_PROJECT_NAME`. A config that hardcodes a port is an `F-xx` against the
  repo, not something to route around per phase.
- When *you* (or your check subagent) run anything in a phase worktree, export
  the same block first — `eval export $(worktree-env $BR $PORT_VARS | sed 's/--env //g')`.
Then:

```
SendMessage to w-<id>-<NN>-<domain>:

Phase <NN> of issue <id>-<slug>. Run /phased-implementation.
Issue dir: docs/design/<id>-<slug>/  (read design.md; your phase is #<NN>)
Spec: docs/spec/<a>.md, docs/spec/<b>.md  (base for everything; deviations are blockers)
Entry: design.md § PH-<NN>  (complete | thin — <what's missing>) — read it first; it is your plan
Start here: <the entry's In-scope file list, copied from the index line's paths, one per line>
Co-sign: no | yes   (yes only for a thin entry)
AC covered: AC-x, AC-y
Approver: orch-<id>  — questions and completion report come to me.
Base branch: feat/<id>-<slug>  at <sha>
Your branch: phase/<id>-<NN>-<phase-slug>   (you are already in its worktree; verify with git branch --show-current)
```

Record `<sha>` — it's what you diff against at phase check. Two parallel phases get
two branches from the same `<sha>`; whichever lands second will need a rebase
(step 5).

### 4. Co-sign the plan — thin entries only

A worker with a complete entry doesn't submit a plan; it writes its plan file
(entry + file list + test list) and starts, and you hear from it next at
completion. Only a `Thin` entry's worker submits, because there the plan
contains a decision the entry didn't. Its submission arrives as a message naming
the plan file. Read it against `design.md` and the spec and answer **only** these:

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

The worker's completion message names commits and deviations. **You do not read the
diff yourself.** Measured 2026-09-11: orchestras that did sat at 250–290K tokens of
context per turn for a whole issue, and every cache miss re-wrote all of it. Your
context holds the design and the decisions; the diff goes to a subagent.

Launch one **check subagent** (general-purpose, `model: "opus"`, high effort) per
finished phase. Give it paths, not text: `design.md` and the entry id `PH-NN` (it
reads the entry's AC, scope, and not-touched list itself), the spec files the
entry names, the worker's reported deviations (that one is short — paste it), the
diff command `git diff <base-sha>..phase/<id>-<NN>-<slug> -- <touched paths>`, the
worker's worktree path, and the env block (the repo's declared port variables plus
`WORKTREE_ID`/`COMPOSE_PROJECT_NAME`, recomputed from the branch with
`worktree-env`) to export before running any verification there. Tell it it may run commands in that worktree and must never
edit or commit in it. It returns a fixed-shape report: per AC `pass|fail` with the
evidence line; a numbered list of structure findings; a verdict on each reported
deviation. Nothing else — you don't want the diff back.

The subagent checks, in this order:

1. **AC** — for each AC id of this phase, run its verification method from
   `design.md`. "Tests pass" is not an AC check unless the AC says unit test. If the
   profile has an acceptance section (the web profile does: run the app, look), do it.
   For a `screenshot` AC: with Playwright, capture the mockup file and the running
   app at the same viewport, then list differences element by element — color,
   spacing, type size, missing or extra elements, copy — as findings. "Looks close"
   is a fail; the mockup is the contract.
2. **Structure vs spec** — new modules outside the touched list, new abstractions or
   config knobs the spec doesn't have, behaviour that differs from the spec text,
   spec text the worker should have rewritten and didn't.
3. **Deviations the worker reported** — each one is either fine (update the spec
   now, ledger `D-xx`) or a finding.

You read the report, not the diff. Every problem becomes a ledger `F-xx` (you
mint; the subagent doesn't). If the report is ambiguous on one item, ask the same
subagent a follow-up rather than opening the diff yourself. Then:

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

1. **No issue-level code review.** Every phase was already reviewed twice — the
   worker's review subagent (phased-impl step 9) and your check subagent (step 5) —
   and the whole-branch view is what the MR reviewer at G3 provides. Measured
   2026-09-11: an end-of-issue `/code-review` fed FX loops of up to five rounds,
   introduced design decisions after the design gate, and spent worker sessions on
   comment-level nits. Findings for this issue are what the per-phase checks
   minted in `ledger.md`; nothing new is generated here.
2. Confirm every spec file in the Spec 改動 table has its `最近改動` line and matches
   what was built. Confirm the issue `ledger.md` has no `open` `Q-xx`. Add a final
   section `## Leftovers` to `ledger.md` listing every item still `open` that
   outlives the issue (`R-xx`, `pre-existing:` findings), one line each. Nobody is
   messaged; `/sweep` reads this section from merged issues and main re-mints what
   it keeps.
3. `git worktree list` must show no `phase/<id>-…` worktree and `herdr tab list
   --workspace $HERDR_WORKSPACE_ID` no phase tab left. Anything left means a phase
   landed without step 5's cleanup — close and remove it now, note it as `F-xx`.
4. `git fetch && git rebase origin/main`, rerun the profile's gates. Then:
   - **never pushed:** push, `glab mr create`.
   - **pushed before, no rewrite** (only new commits on top): push, `glab mr update`.
   - **pushed before and the rebase rewrote history:** you can't push it — you
     have no force-push permission. Do **not** close the MR, do **not** open a new
     MR from a new branch, do **not** undo the rebase. Update the MR body with
     `glab mr update` (it still points at the branch), then end with the G3 report
     saying: `branch feat/<id>-<slug> is rebased locally in <worktree path> and
     needs --force-with-lease from you, then merge`. That push is the user's; G3
     for this issue is force-push then merge.
   MR body: goal, AC table with pass/fail, Spec 改動 table, the open `F-xx`/`R-xx`
   from `ledger.md` with one line each, and the session attribution line the
   environment gives you.
5. Tell the user: MR URL, open findings by id, anything deferred. Then stop. The
   session's job is over; a review-comment round is a new instruction from the
   user. Leave the issue worktree and this workspace in place — `<repo>-main`'s
   `/sweep` closes the workspace and removes the worktree once the MR is merged
   and you're idle. You can't close the room you're sitting in.

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
