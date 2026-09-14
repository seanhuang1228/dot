---
name: mr-review
description: Review a batch of merge requests written by other people (usually by their AI) — one subagent per MR produces a fixed-shape card, you read them as one board, and approved findings get posted back to GitLab as inline comments. Judges whether the MR does what its ticket asked and whether it breaks anything; never enforces our own workflow conventions on someone else's branch. Use when the user says "看 MR", "review the open MRs", "review !284", or hands over a list of MR ids.
---

# MR review

Someone else's MRs, usually written by someone else's agent. The scarce resource
is the user's attention, so the output is a **board of fixed-shape cards** they
can skim in one screen, plus **comment drafts** they approve before anything is
posted. You never edit, push, approve, or merge.

## What you judge — and what you don't

Judge exactly three things, in this order:

1. **Does it do what its ticket asked?** The title usually cites a Bug number
   and an issue (`（Bug 260，#108）`). Read that issue (`glab issue view <n>`),
   then the diff. The most common defect in agent-written MRs is not a bug — it
   is doing something adjacent to, larger than, or instead of what was asked.
2. **Is it carrying weight it doesn't need?** New abstractions, new config knobs,
   a refactor bundled with a fix, a new dependency, files unrelated to the
   subject, reformatting noise mixed into real changes. Each with `file:line`.
3. **Will it break?** Correctness in the changed code and at its edges; tests
   that are theatre (assert on mocks, deleted cases, assertions that can't fail);
   an error path that swallows; a contract change that callers don't follow.

**Do not review against our own process.** This is the explicit rule for this
skill: the repo's `docs/spec/`, `docs/design/`, ledger ids, `CLAUDE.md`
conventions, commit-message shape, branch naming, phase structure — all of that
is *our* workflow and none of it binds someone else's branch. Read `docs/spec/`
if it helps you understand what the code is supposed to do, but a divergence
from it is only a finding when the code actually misbehaves because of it.
Never write a comment whose substance is "this doesn't follow our convention".

Also out of scope: style preferences, naming taste, test-coverage percentages,
and anything you'd phrase as "consider…" with no consequence attached.

## Procedure

1. **Scope.** Ids given → those. Nothing given → `glab mr list` for open MRs not
   authored by the user (`glab api "projects/:id/merge_requests?state=opened"`,
   filter on `author.username`). Show the list and the count, then go; don't ask
   which ones.

2. **One subagent per MR** (general-purpose, `model: "opus"`, high effort), in
   parallel. Give each: the MR id, the command set below, the three judging
   questions verbatim, the do-not-review rule verbatim, and the card shape. It
   returns **only the card** — never the diff, never a narration of the code.

   ```
   glab mr view <id>                       # title, description, source/target, conflicts
   glab mr diff <id>                       # the changes
   glab issue view <n>                     # the ticket the title cites, if any
   git log origin/main..origin/<source>    # how it was built
   ```
   Read-only. The subagent runs no build, no tests, and touches no worktree —
   it is looking at someone else's branch, not running it.

3. **Card shape**, identical for every MR so ten of them read as one board:

   ```
   !284  jordan  「418（IP 被封）要真的停止送請求（#110）」  conflicts: yes
   Verdict: BLOCK | SHRINK | ASK | PASS
   對題:   <one line: what the ticket asked vs what the diff does>
   超載:   <one line each, or 無>
   會壞:   <one line each with file:line, or 無>
   看這裡: <the one thing the user should open with their own eyes, or 不用>
   Comments: <n drafted>
   ```

   Verdicts: `BLOCK` — doesn't do what was asked, or breaks something.
   `SHRINK` — works, but carries weight that should come out or be split.
   `ASK` — can't be judged without the author's intent. `PASS` — fine.

4. **Comment drafts.** Each finding worth a teammate's time becomes one draft,
   attached to its card. Economy is the point: a comment costs someone's
   attention, so at most **five inline drafts per MR** plus one summary. Rank by
   consequence and drop the tail rather than posting everything.

   Write them in the repo's language (Chinese here) as a peer would: the
   observation, the consequence, and — when it's a judgment call rather than a
   defect — a question instead of an instruction. No opener, no praise padding,
   no "per our convention". One point per comment.

5. **Present the board.** All cards, `BLOCK` first, then `ASK`, `SHRINK`, `PASS`.
   Then stop. The user reads it and says what to post — by MR (`!284 post`), by
   card (`!284 post 1,3`), or `all`. Never post before that.

6. **Post what's approved.**
   ```
   glab mr note create <id> --file <path> --line <n> --unique -m "<text>"   # inline
   glab mr note create <id> --unique -m "<summary>"                         # summary
   ```
   `--unique` prevents a double-post if a run is repeated. Report what went up,
   one line per comment, with the MR id.

## Never

- `glab mr approve`, `glab mr merge`, `glab mr update`, `glab mr rebase`,
  `glab mr close` — the MR is someone else's and merging is the user's.
- Push to, check out, or edit another author's branch. Fixing it yourself is
  not review; if a fix is obvious, it goes in the comment as a suggestion.
- Post anything the user didn't approve, or re-post after edits without saying
  which comments changed.
- Read the whole diff into your own context. The cards are what you hold; the
  diffs live in the subagents.
