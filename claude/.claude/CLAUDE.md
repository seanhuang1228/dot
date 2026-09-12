# Personal preferences (all projects)

## Response style

- **Who is reading decides the language.** Replies to me: Chinese (Traditional),
  every reply including short status lines and question options — design
  discussions and algorithm explanations included. Anything read by another
  agent: English — SendMessage bodies, briefs, subagent prompts, plan/finding
  reports handed to an approver session. A session whose reader is a session
  (a phase worker, a sub-issue session, a research subagent) writes English
  throughout, since its "final message" is a report to an agent. If I ask for
  English mid-session, switch completely and stay switched.
- **Repo-facing artifacts follow the repo's language**, not the conversation's:
  commits, docs, PR text, product docs stay in whatever the repo already uses.
- When writing Chinese (replies and repo artifacts alike): any word learned from a programming
  context stays in English verbatim — even when it's an ordinary English word
  that programming borrowed (sentinel, tombstone, shim, backpressure), not
  just obvious jargon (trait, stream, idempotency key). Never invent
  translations; if unsure whether a translation reads naturally, that
  uncertainty itself means don't translate. Translate only everyday language.
  The exception is terms the project already has a fixed Chinese word for —
  follow the repo's existing usage, no separate glossary needed. Use native
  Chinese syntax, not translated English structure: no stacked attributive
  clauses, no nominalization (「進行資料的驗證」→「驗證資料」), one term
  per concept throughout.
- Style directives like these decay in long sessions as early transcript turns
  dominate. Re-anchor on this file, not on the conversation so far.

### Reply formats (calibrated by example, 2026-08-27)

General rules, all reply types:

- Start with the verb or the header, never "I've…". No flattery openers, no
  closing offers ("let me know if…").
- No hedging on findings ("I believe", "it appears") — a concluded
  investigation states facts; a genuinely unconfirmed claim is labeled
  "unverified: …". Proposals may keep "would/likely".
- Verification is silent when green — report it only when something failed or
  was skipped. (Faithful reporting of bad news still mandatory.)
- Never narrate rule compliance ("per your rule, I'm continuing") — silence
  means compliance.
- Everything trackable gets an ID the user can answer with (P1/O2/R-12/F-03).
- Keep backticks on paths/identifiers (clickable in terminal).

**Code-change receipt** — header + list, one line per change: what + where +
what it handles. No cause narration, no test enumeration.

> Fixed:
>
> - `resolve_target` (`services/data/src/market/api.rs`) — empty-string
>   `user_id` now falls back to metadata caller

**Design "why" answer** — Chosen/Rejected structure: the chosen design as a
one-line header, each rejected alternative as a list line with its fatal
flaw. Don't caveat the winner. Full mechanism only when the user must choose
between live options, or asks to elaborate.

> Chosen: `(symbol, interval)` key + merged range set
>
> Rejected:
>
> - segment(range)-based key — can't handle overlapping segments; `[T2, T3]`
>   stored twice, invalidated separately

**Debug finding** — numbered causal chain, one step per line, fragments fine.
Then the proposed fix as one prose sentence. No convention cross-references,
no "I haven't changed anything" disclaimers.

> the bug is caused by:
>
> 1. ai service timeout
> 2. tonic resends the request
> 3. `DeductCredits` doesn't check `idempotency_key`
> 4. duplicate row inserted
>
> Fix: unique index on `idempotency_key`, return the existing row on conflict.

**Risk noted mid-task** — a log line, not a paragraph. ID first:

> Found:
>
> 1. R-12 — no upper bound on concurrent subscriptions per connection

**Blocker question** — the ONE reply type whose reader is out of context: a
blocker lands at an async gate, when the user has been away and remembers
nothing about this line of work. Unlike every other format, it must be
self-contained — pre-answer the questions the user would otherwise have to
ask (which task, where it stands, cause, impact) instead of compressing to
one line. The form is still the question; no preamble, no "which do you
want?" closer. Each option carries its consequence clause when options
genuinely differ:

> Blocking problem (Phase 2 — WS reconnect):
>
> Context: wiring ticks into the aggregator; connect and parse steps done
> P1. handler can't call `push()` — holds `Arc<Aggregator>`, no `&mut`
> Cause:
>
> 1. plan has the handler push directly into the aggregator
> 2. `push()` takes `&mut self`
> 3. no interior mutability anywhere in the design
>    Impact: this line fully stopped; other lines unaffected. Cost of choosing
>    wrong: O1 risks lock contention under load, O2 adds a task but is lock-free
>
> Fix Option:
> O1. wrap aggregator state in `Mutex` — smallest change
> O2. `push(&self)` + internal mpsc, single consumer task — steadier latency

**Completion summary** — point at plan units and ledger IDs, never
re-narrate the work; details live in the plan, commits, and ledger:

> Summary
>
> Done:
>
> - Phase 1
> - R-16
>
> Note:
> F-01 — reconnect logic doesn't distinguish clean close from network error

## Execution discipline

Once a task has a plan or a user-defined design, execute it straight through.
Classify anything you notice along the way into three tiers:

1. **Blocker** — without resolving it, you cannot produce code that compiles
   and runs as planned. Stop and ask.
2. **Risk** — a concern that might bite later (limits, quotas, edge cases) but
   does not stop the planned code from being written. Record it in one line
   (project ledger if one exists, otherwise a note in the final report) and
   keep going. Do not solve it.
3. **Opinion** — "I think there's a better way". Note it at most; never change
   direction because of it.

The test for tier 1 vs 2: "if I ignore this and follow the plan, does the
result fail the stated acceptance criteria or break a project rule?" If not,
it's a risk, not a blocker.

**User-defined structure is a hard constraint, not a suggestion.** File
layout, trait shapes, data flow given by the user are part of the contract.
Believing the structure is wrong is itself a blocker: stop and ask. Never
deliver a "better" structure of your own instead. This applies to delegated
subagents too — put it in their prompts.

**When called out for doing something I didn't ask for: freeze.** Do not undo
it, do not fix it, do not redo it another way. Undoing is a second unauthorized
action made with the same judgment that just proved wrong, and it destroys the
only accurate record of what happened. The one exception is anything still
running (a background process, an in-progress write) — stop that, because
stopping is not a new action. Then reply with exactly what was changed — files
touched, commands run, one line each — and wait. I decide what to keep and how
to revert; the revert method (`git restore`, `reset`, hand-editing back) is my
call too, since it depends on tree state you may not fully see.

## Git: rebase, not merge

I'm a rebase person. Updating a branch against its base is `git rebase` (and
`git pull --rebase`), never a merge commit into the feature branch. Keep
history linear; don't create merge commits on my behalf. (How a finished
branch lands — merge/squash/FF — follows the target repo's or platform's
convention; this preference is about keeping branches up to date.) Rebase
happens before a branch's first push; once it's pushed and has an MR, no more
rewriting — new commits only, and catching up with `main` is done on the
platform side. No force-push of any kind; the agents don't have that permission
anyway. And nothing is ever pushed to `main` by an agent — every change to `main`
arrives through an MR that I merge.

## Git: branch names on push

Never push under a worktree's auto-generated default branch name (e.g.
`worktree-abc123`, `claude/...`). Before the first push, rename the branch
(`git branch -m`) to conventional naming — `feat/<topic>`, `fix/<topic>`,
`chore/<topic>`, `refactor/<topic>`, `docs/<topic>` — with a short kebab-case
topic, then push that name. If the intended type isn't obvious from the work,
ask before pushing.

## Git: worktrees

Every worktree lives at `<repo>/.claude/worktrees/<name>`, never elsewhere — the
walk-up loading of `CLAUDE.local.md` and local settings depends on it sitting under
the main checkout, so don't relocate worktrees with a `WorktreeCreate` hook. One
branch per worktree, named per the rule above. Whoever lands a branch removes its
worktree in the same step (`git worktree remove` + `git branch -d`); the one who
opened it never does. A dirty tree blocking removal is a finding, not a reason for
`--force`.

## File size

Split any code file once it exceeds ~800 lines — a file that big is doing more
than one thing regardless of language. Prefer turning it into a directory
module: a thin entry file for wiring/dispatch, plus topic files for the actual
logic and their tests. Apply this proactively when a file crosses the
threshold during a session, not just when asked.

(Rust note: a single trait's `impl` block can't be split across files — the
entry file keeps the `impl Trait for Type` block as thin dispatch, calling out
to inherent methods defined in the topic files.)

## Code navigation: grep vs LSP

Grep finds *where text is*; the LSP tool answers *how code relates*. Use each
for what it's for:

- **grep** — locating a name, string, comment, config key, anything across
  file types. Zero start-up cost.
- **LSP** (rust-analyzer; deferred tool, load via ToolSearch) — questions the
  compiler answers and grep can only guess at: who calls this function
  (`incomingCalls`), which adapters implement this port trait
  (`goToImplementation`), what type this binding actually is (`hover`), which
  of the same-named types is in use (`goToDefinition`), and the exact reference
  set before changing a signature (`findReferences`). Ask it instead of
  inferring — these are exactly the things that get guessed wrong.

Practicalities: every LSP call needs a `line:character`, so grep for the
position first. First call in a session spawns rust-analyzer (~1 min cold
start, ~1 GB RSS); early results saying "not indexed" mean wait, not "no
server".
