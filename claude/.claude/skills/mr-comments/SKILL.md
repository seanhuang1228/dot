---
name: mr-comments
description: Read the review comments on the issue's own MR, judge each one against the design, auto-answer the purely factual threads, and report the rest to the user with a proposed fix for each. Run by the issue's orchestra after G3, in its own tab. Use when the user says "看一下 MR 的 comment", "MR 有人留言了", "go read the MR comments", or hands over a comment round on our own MR.
---

# MR comments

Someone reviewed **our** MR. This is the "review-comment round" that
`issue-orchestration` G3 calls a new instruction from the user — this skill is
that instruction, nothing more. It ends with a report and a decision for the
user; it never starts the fixing.

## Who runs this

The issue's own orchestra (`orch-<id>`), in its own tab. It holds the design, the
`D-xx` rows, and the spec diff, which is exactly what deciding "is this comment
right?" needs. Main never runs it and never forwards it — main doesn't message
orchestras, and it doesn't have the context to judge the answer.

The orchestra is still alive at this point by construction: `/sweep` closes an
issue workspace only after its MR is **merged**, and a comment round happens
before that. If the session is genuinely gone (killed, cleared), start a session
in the issue worktree, load `issue-orchestration` and this skill, and say in the
report that the design context came from `design.md` rather than from the
orchestra's own memory.

## Which MR

Yours, and only yours. The MR is the one you opened at G3 from this issue's
branch, so resolve it from the branch rather than from an argument:

```
git branch --show-current                 # must be feat/<id>-<slug>, this issue's
glab api "projects/:id/merge_requests?state=opened&source_branch=feat/<id>-<slug>"
```

One match → that `iid`. No match → the MR isn't open (already merged, or G3 never
ran); say which and stop. More than one → stop and report the ids; don't pick.

If the user hands you an id, check it against the branch and refuse the mismatch:
another issue's MR belongs to that issue's orchestra, and someone else's MR is
`/mr-review` or `/mr-recheck`, never this skill. You have the design for exactly
one issue, and that is the whole reason this skill is yours to run.

## Procedure

1. **Pull the threads.** Discussions, not notes — you need the thread structure
   and the resolved flag:

   ```
   glab api "projects/:id/merge_requests/<iid>/discussions?per_page=100"
   ```

   Skip system notes (`system: true`), threads already `resolved`, and threads
   whose last note is ours (already answered — this skill is re-runnable).

2. **One subagent to pair each thread with its code** (general-purpose, opus,
   high effort). It gets the thread list, the MR id, and read-only commands
   (`glab mr diff`, `git log`, `git show`, reading files in the worktree). It
   returns a table, one row per thread — thread id, the file:line it anchors to,
   the comment in one line, and what the code there actually does. It does not
   decide anything and does not write. You keep the table, not the diff.

3. **Judge each thread yourself**, against the design you hold. Four buckets, and
   every thread lands in exactly one:

   | bucket | what it is | what happens |
   | --- | --- | --- |
   | `事實` | answerable from the record alone, no judgment: already fixed in `<sha>`, deliberate per `42/D-03`, the spec says it at `<path>` | reply posted automatically (step 4) |
   | `要改` | a real defect, or a change we accept | `F-xx` in the issue ledger + a one-line proposed fix |
   | `要談` | design pushback, a suggestion we want to reject, anything where you'd be making a call the user owns | reply drafted, not posted |
   | `不用理` | taste, naming, coverage percentages, anything with no consequence | nothing, unless the user says otherwise |

4. **Auto-post the `事實` replies only.** The test is mechanical: the reply cites
   a sha, a `D-xx` row, a spec path, or the MR itself, and contains no "我們認為",
   "建議", "應該", no proposal and no refusal. Anything that fails that test is
   `要談`, not `事實` — when in doubt it is `要談`, because an auto-posted opinion
   on a teammate's thread can't be taken back.

   ```
   glab api -X POST "projects/:id/merge_requests/<iid>/discussions/<discussion_id>/notes" \
     -f body="<text>"
   ```

   Reply inside the thread, never as a new top-level note. Repo's language. Never
   resolve a thread — the reviewer closes their own.

5. **Mint before reporting.** Every `要改` is an `F-xx` in `docs/design/<id>-<slug>/ledger.md`
   with the thread's `file:line`, before it appears in the report, so the user can
   answer with ids. A `要談` that the user later settles becomes a `D-xx` then —
   not now.

6. **Report and stop.**

   ```
   MR !<iid> — <n> threads, <n> answered, <n> for you

   要改:
   - F-09 <one line> — <file:line>；修法：<one line>
   要談:
   - T1 <reviewer's point in one line>
     草稿：<the reply you'd post>
   不用理: <n> 條（<one phrase each>）
   已回: <n> 條事實（thread <id>, <id>）

   下一步（你決定）:
   O1. review round worker — phase/<id>-RR-review，走 phased-implementation，有 check
   O2. throwaway session 直接在 issue branch 上改，快但少一層檢查
   O3. 不修，回覆理由（草稿已在上面）
   ```

   Then end the turn. You do not open a worktree, dispatch a worker, write a line
   of product code, push, resolve, or merge off the back of this. The user picks,
   and that pick is the next instruction.

## Never

- Reply to a `要談` or `要改` thread before the user approves the text.
- Resolve, approve, merge, or `glab mr update` anything.
- Re-post into a thread whose last note is already ours.
- Read the whole diff into your own context — step 2's subagent exists for that.
- Treat a reviewer's suggestion as binding: a comment that contradicts the design
  is `要談`, and the user decides whether the design moves.
- Look at any MR but this issue's.
