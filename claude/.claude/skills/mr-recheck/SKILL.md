---
name: mr-recheck
description: Re-check a merge request that /mr-review already reviewed — did each posted finding get addressed, and did the new commits bring anything new. Returns one card per MR to the terminal and posts nothing. Use when the user says "複檢 !284", "他改了，再看一次", "recheck that MR", or hands back an MR id that was reviewed before.
---

# MR recheck

Second pass on someone else's MR after the author pushed changes. Everything in
`mr-review` still holds — the three judging questions, the do-not-review rule, the
card shape, never editing or approving another author's branch. This skill only
narrows the scope and changes the output destination.

**Nothing is posted.** The output is a card in the terminal. If the user wants a
reply on GitLab afterwards, that is a separate instruction and it goes through
`mr-review`'s drafting and approval rules.

## Scope — ids are the input

`/mr-recheck !284`, or several ids. The id is required: this skill re-checks what
you name, it never goes looking. Nothing given → list the open MRs that already
carry our comments and stop, so the user can pick:

```
glab api "projects/:id/merge_requests?state=opened&per_page=100"
# then per MR, the cheap test: does any discussion note have our username?
```

Never fall back to "every open MR" — that is `/mr-review`'s job, and a recheck of
an MR that was never reviewed is a first review wearing the wrong card.

## What the last round was

GitLab is the record. The drafts the user dropped last time were never written
down, so the findings that exist are the ones that were posted:

```
glab api "projects/:id/merge_requests/<iid>/discussions?per_page=100"
```

Ours are the threads authored by the user (`glab api user` for the username).
Their `created_at` and their `position` (file + line) are the finding list. No
posted comments → the MR was never reviewed, or the user dropped everything;
say so and run `/mr-review` on it instead of guessing.

## What is new

Prefer the MR's own versions — each carries a head sha:

```
glab api "projects/:id/merge_requests/<iid>/versions"
```

The version whose `created_at` precedes our last comment is the base of the
re-check; the diff worth reading is that sha to the current head. No usable
version list → fall back to commits dated after our last comment
(`git log --since`), and say in the card that the range was derived from
timestamps.

## Procedure

One subagent per named MR (general-purpose, opus, high effort), in parallel when
several ids were given. It gets: the MR id, the posted-finding list with file:line, the
sha range, `mr-review`'s three judging questions verbatim, the do-not-review rule
verbatim, and the card shape below. Read-only — no build, no tests, no worktree.
It returns only the card.

Each old finding gets exactly one status:

- `已修` — the change does what the comment asked, with the sha
- `沒修` — untouched
- `改錯方向` — touched, but the result doesn't address the point, or breaks
  something else; this is the row that matters most and it carries `file:line`
- `不適用` — the code it pointed at is gone for an unrelated reason

Then the new commits get the normal three questions, scoped to the range. A
finding from the first round that the author argued against in a thread is not
re-asserted — it is `要談` and it belongs to the user, not to another comment.

## Card

```
!284  jordan  「<title>」  複檢 <base sha>..<head sha>  conflicts: yes
Verdict: BLOCK | SHRINK | ASK | PASS
上輪:   3 已修 / 1 沒修 / 1 改錯方向
  - 改錯方向 <one line> — <file:line>
  - 沒修 <one line> — <file:line>
新增:   <one line each from the new commits, or 無>
看這裡: <the one thing the user should open with their own eyes, or 不用>
```

The verdict is for the MR as it stands now, not for the delta: an MR whose new
commits are clean but whose `改錯方向` row is still open is `BLOCK`.

## Never

- Post, reply, resolve, approve, merge, rebase, or touch the branch.
- Re-review the parts of the MR nobody changed — if a file is outside the sha
  range and had no finding on it, it is not in scope.
- Carry a first-round finding forward as if it were new; it keeps its history in
  the `上輪` block.
- Read the diffs into your own context; the subagent holds them, you hold cards.
