---
name: item-ledger
description: Numbering and recording rules for trackable items (findings, tasks, questions, decisions, risks, ideas, features). Use whenever a response would hand the user 4+ trackable items at once, when the user mentions an item ID like F-07 or T-03, or when the user says "record this", "track these", or "add to the ledger". Keeps a docs/ledger/ directory per project (index + optional per-item detail files) so items can be referenced by short stable IDs instead of re-described.
---

# Item Ledger

When work produces many items at once (review findings, open questions, follow-up
tasks), the user cannot trace them from chat scrollback. Every trackable item gets
a short stable ID and one line in a ledger file. Later, the user or any agent
refers to the item by ID alone.

## ID grammar

```
<CAT>-<NN>        examples: F-07  T-03  Q-12
```

- **CAT** — one uppercase letter from the category registry below.
- **NN** — per-category counter, starting at `01`, zero-padded to 2 digits.
  At 100 it becomes 3 digits (`F-100`); never re-pad existing IDs.
- Exactly one canonical spelling: uppercase letter, hyphen, zero-padded number.
  Never write `f-7`, `F7`, or `F-7` — one spelling means one grep hit.

### Category registry

| Code | Meaning  | Typical source                                  |
| ---- | -------- | ----------------------------------------------- |
| `F`  | Finding  | Code review, investigation, audit output        |
| `T`  | Task     | Work someone must do                            |
| `Q`  | Question | Needs an answer from the user or a peer         |
| `D`  | Decision | A choice that was made, with its why            |
| `R`  | Risk     | Known hazard, not yet a task                    |
| `I`  | Idea     | Maybe later; explicitly not committed           |
| `FT` | Feature  | Committed unit of product work, usually graduated from an `I` |

Adding a category is allowed but rare: pick an unused uppercase letter (or a
short unique code like `FT`), add a row to the ledger's registry section first,
then mint IDs. Never repurpose a code.

### Graduation (I → FT)

When an idea is committed to be built, it graduates:

1. In the same edit: mint `FT-NN`, and close the source `I` item as
   `dropped — superseded by FT-NN`. At any moment one piece of work has exactly
   one live item; two live items for the same thing will diverge.
2. The FT line links to where its spec lives (a section in the project's living
   spec doc, a plan file — whatever the project uses). The ledger line is the
   pointer, never the spec.
3. `FT` status flips open → done exactly once, when the work lands. In-flight
   progress lives in the project's status doc, not on the FT line — status in
   two places goes stale in one of them.
4. A real ruling made on the way (chose O2 over O1, and the why matters later)
   is a separate `D` item. "We decided to build it" is not — the FT's existence
   already records that.

## Ledger vs living docs

The ledger is an account book, not a log and not documentation. Three tenses,
three homes:

- **Spec / design doc — present tense.** What the thing is and why it's shaped
  this way. Rewritten in place; must always be correct; old content disappears
  on rewrite.
- **Status doc — present progressive.** How far along; changes most often.
- **Ledger — the books.** Every trackable point that came up along the way.
  Closed items are never deleted or edited — when the spec is rewritten, the
  ledger is the only place "what we considered and why, at the time" survives.

Final facts go to the spec; rejected options, Q&A, and risk calls stay in the
ledger. Never answer "what is this system like now" from the ledger — that's
the spec's job. Each direction held by one side means no fact lives twice.

## Immutability rules

These make an ID safe to say in chat weeks later:

1. **Never reuse** a number, even after an item is dropped.
2. **Never renumber** existing items, even if the list looks sparse.
3. A cancelled item keeps its ID with status `dropped` — it is a tombstone,
   not a free slot.
4. Cross-reference between items inline by ID: `blocks T-03`, `answers Q-01`.

## Two ledgers, one writer each

Parallel branches minting into one file collide on the counter and conflict on
every rebase, so a repo has two levels and each file has exactly one writer:

| ledger | path | writer | holds |
| --- | --- | --- | --- |
| repo | `docs/ledger/LEDGER.md` | the repo's main session, on its rolling `chore/ledger` branch + one MR (nothing is ever pushed to `main`) | `I`, `FT`, risks that outlive an issue, `pre-existing:` findings |
| issue | `docs/design/<id>-<slug>/ledger.md` | that issue's orchestra, on the issue branch | that issue's `F`, `T`, `Q`, `D`, `R` |

Resolution: inside an issue directory (or a session whose brief names one), the
issue ledger is *the* ledger — IDs are unqualified (`F-03`). From anywhere else, an
issue item is written `42/F-03`. Repo-level items are never qualified. Workers,
sub-issue sessions, and subagents don't write either file: they report, the owner
mints. (A project CLAUDE.md may name different paths; the one-writer rule stays.)

Layout of either:

```
<ledger dir>/
  LEDGER.md      # repo level — the index, one line per item
  ledger.md      # issue level — same format, lower-case to tell them apart at a glance
  F-07.md        # detail file — only for items too complex for one line
  Q-02.md
```

When an issue closes, its `ledger.md` freezes with the directory. Items still
`open` that matter beyond the issue are re-minted at repo level by the main session
(new id, line cites `42/R-01`), and the issue line is closed `dropped — moved to
R-07`.

- The **index** is the single source of truth for existence, status, and counters.
- A **detail file** is optional, named exactly `<ID>.md`, created only when an
  item genuinely needs more than the index line (long analysis, reproduction
  steps, option comparison, quotes). Most items should not have one.
- Detail files never duplicate status — status lives only in the index, so it
  cannot go stale in two places. Detail file holds title + body + references.
- When a detail file exists, its index line ends with `(→ F-07.md)`.
- Dropped items keep their detail file — tombstone includes the body.

```markdown
# Ledger

next: F=08 T=04 Q=03 D=02 R=01 I=01

## F — Findings
- F-07 open — gateway drops SSE heartbeat under proxy buffering (services/gateway/src/sse.rs:41)
- F-06 done — billing idempotency key missing unique index

## T — Tasks
- T-03 blocked — add retry to news fetcher; blocks on Q-02
```

Format rules:

- The `next:` line holds the next unminted number per category. Update it in the
  same edit that mints an ID — it is the single source of truth for counters.
- One line per item: `- <ID> <status> — <short title, ≤ ~100 chars>` plus an
  optional `file:line` or doc link. Long detail never goes in the index; it goes
  in the item's detail file, or a link to where it lives (code, doc, PR).
- Statuses: `open`, `done`, `dropped`, `blocked`. Newest item first within
  each section.
- Sections ordered by category code; omit empty sections.

## Behavior

**When producing 4+ trackable items** (or fewer, if the user will act on them
later): mint IDs, write them to the ledger, and prefix every item in the chat
response with its ID so the user sees the same IDs that were recorded.

**When the user mentions an ID**: read the index, then the item's detail file if
one exists, resolve the item, act on it.
If the ID does not exist, say so — never guess which item was meant.

**When an item's state changes** (fixed, answered, abandoned): update its status
in the ledger in the same turn the change happens, not in a batch later.

**Overhead discipline**: do not load the ledger speculatively — read it only when
minting, resolving a mentioned ID, or updating status. Keep the file lean enough
that reading it costs less than re-deriving what it records.
