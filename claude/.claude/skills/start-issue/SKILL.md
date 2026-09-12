---
name: start-issue
description: Turn a request into a running issue — create or resolve the GitLab issue, open the issue worktree and herdr workspace, start the orchestra session, and brief it so it begins intake. Run from the repo's main session. Use when the user says "start an issue for …", "make this an issue", "kick off #42", or when a request fails the main session's sub-issue cap.
---

# Start an issue

From one sentence to an `orch-<id>` session running `/issue-orchestration` intake.
You do the mechanical part; the orchestra does the thinking. Total time should be
under a minute.

## Preconditions

- `test "${HERDR_ENV:-}" = 1` — without herdr, stop and tell the user; this skill
  has no manual fallback worth automating.
- `glab auth status` succeeds.
- You are in the main checkout on `main`, `git status --porcelain` empty, `git pull
  --rebase` done. Anything else → fix it or stop; never branch an issue off a stale
  or dirty `main`.

## Steps

1. **Issue id.** Three cases, in this order:
   - The user named one (`#42`, a URL) → `glab issue view 42 --comments`. It must be
     open; a closed one is a stop-and-ask.
   - Not named → search before creating: `glab issue list --search "<2-3 key
     words>"` (open issues). One plausible match → show it and ask "this one?";
     several → list them; none → create.
   - Create: `glab issue create --title "<short title>" --description "<the user's
     words, verbatim, plus any AC they stated>"` in the repo's language. Never
     invent requirements to pad the description; the orchestra's research fills
     that in.

   For an existing issue, the issue body and its comments are the requirement, not
   the user's one-liner — carry both into the brief (step 6), the issue text
   verbatim or, past ~40 lines, as a summary with a note that the orchestra must
   read the full issue itself.
2. **Slug.** Kebab-case, ≤ 4 words, from the title: `42-multi-exchange`. Check
   `docs/design/` and `git branch -a --list '*feat/42-*'` — a collision means the
   issue was started before. Without `--resume`, stop and tell the user which
   worktree/branch exists. **With `--resume`** (`/start-issue #42 --resume`): take
   the existing branch (fetch it if it's only on `origin`), keep its slug, skip
   issue creation and the ledger step, and in step 3 create the worktree *from that
   branch* instead of `-b`: `herdr worktree create --cwd "$ROOT" --branch
   feat/<id>-<slug> --path "$ROOT/.claude/worktrees/feat-<id>-<slug>" …` (existing
   branch, no `--base`). The brief (step 6) says `Resume: yes — find where it
   stands from design.md, ledger.md, and git log; don't redo landed phases`.
   Used when an orchestra died, or the work moves to another machine.
3. **Worktree + workspace.**
   ```
   git worktree prune
   ROOT=$(git rev-parse --show-toplevel)
   herdr worktree create --cwd "$ROOT" --branch feat/<id>-<slug> --base main \
     --path "$ROOT/.claude/worktrees/feat-<id>-<slug>" --label <id>-<slug> --no-focus
   ```
   **`--path` must be absolute.** Verified 2026-09-11: a relative `--path` is
   resolved against the herdr *workspace's* cwd, not the repo root and not `--cwd`,
   which is how worktrees end up outside the repo. `--cwd` must point inside the
   repo or herdr refuses (`not_git_worktree`). Run it from the main session, whose
   workspace already is the repo: when the calling workspace is a different repo,
   herdr silently creates and focuses an extra "source" workspace for the repo as a
   side effect (also verified), which you'd then have to close.

   Output (verified): `.result.workspace.workspace_id`, `.result.root_pane.pane_id`,
   `.result.tab.tab_id`. The tab comes labelled `1`; `herdr tab rename` it to `orch`.

   **Split the orch tab half/half** before starting anything: the orchestra lives
   in the left (root) pane, the right pane is the user's shell for reading
   `design.md`, the spec diff, and the MR without leaving the workspace.
   ```
   herdr pane split --pane <root_pane> --direction right --ratio 0.5 \
     --cwd "$ROOT/.claude/worktrees/feat-<id>-<slug>" --no-focus
   ```
   The orchestra goes into `<root_pane>` (step 5), never into the split. Phase tabs
   (opened later by the orchestra) stay single-pane; nobody reads in them.
   If the command fails, fall back to the two-step form: `git worktree add -b
   feat/<id>-<slug> "$ROOT/.claude/worktrees/feat-<id>-<slug>" main`, then `herdr
   workspace create` and `herdr tab create --workspace <ws> --cwd <path> --label
   orch --no-focus`. Either way, confirm with `git worktree list` that the new path
   is under `$ROOT/.claude/worktrees/` before going on.
4. **Repo ledger.** If the request was an `I-xx`, graduate it to `FT-xx`
   (item-ledger rules); otherwise mint `FT-xx` directly. The line links to
   `docs/design/<id>-<slug>/` (which doesn't exist yet — the orchestra creates it).
   Commit it on main's rolling `chore/ledger` branch (see `main-session`), never on
   `main` and never on the issue branch — two issue branches carrying repo-ledger
   edits collide at merge. If the `chore/ledger` MR isn't open yet, open it; the
   user merges it whenever.
5. **Start the orchestra.**
   ```
   herdr agent start orch-<id> --kind claude --pane <root_pane> -- -n orch-<id> --model <fable|opus>
   ```
   **You pick the orchestra's model.** `fable` (`claude-fable-5-1`) when the issue
   has judgment in it — any of: cross-domain (fe + be), a new module or a contract
   to shape, research needed, the request is ambiguous, or it touches a module whose
   spec doesn't exist yet. `opus` when it's execution against an existing pattern:
   single domain, spec already describes the module, the phases are obvious from
   the request ("add exchange #4 like the other three"). If the user named a model,
   that wins. Say which you chose and why in one line of the report. This blocks
   until the session is ready (~5 s). Failure → close the tab, leave the
   worktree, report.
6. **Brief it.** `SendMessage` to `orch-<id>`, one message, self-contained:
   ```
   Issue #<id> <slug> — run /issue-orchestration from intake.
   GitLab: <issue url>
   Request, in the user's words: "<verbatim>"
   Issue body / comments: <verbatim, or summary + "read the full issue with glab issue view <id> --comments">
   Epic: none | docs/design/<epic-id>-<slug>/plan.md, entries PH-01..PH-03 are yours — skip planning, run them
   Ledger: FT-xx
   Related spec files: docs/spec/<a>.md, docs/spec/<b>.md   (your best guess; say "none known" if none)
   Related open ledger items: <ids or none>
   Context the user gave: <Lark links / MR ids / anything pasted, or none>
   Mockup: none | <path to the HTML file(s)> — this is spec, copy it into the issue dir
   Gates G1/G2/G3 and blockers go to the user, not to me. Do not message me at all — cross-issue facts are in docs/design/*/design.md and git worktree list; leftovers go in your ledger.md.
   ```
7. **Report to the user**, four lines: workspace label, orchestra name and model
   (with the one-line why), "next thing you'll see is G2 (design.md) — or G1 if
   research raises questions". Then you're done with this issue.

## Epics

`/start-issue … --epic <epic-id> PH-xx..PH-yy` starts a child of an epic that an
orchestra already planned. Same steps; the GitLab issue is created as a child of
the epic's issue (`glab issue create … --linked-issues <epic-id>` or the repo's
convention), the slug is `<epic-slug>-<xx>-<yy>`, and the brief's `Epic:` line
points at the plan and the entries. One child at a time unless the epic plan marks
the groups `Parallel-ok`.

## Not this skill's job

Deciding whether it should have been a `/sub-issue` (the main session does that
before calling this), reading Lark to enrich the description (the orchestra's research does that),
or waiting for the orchestra (it reports to the user directly).
