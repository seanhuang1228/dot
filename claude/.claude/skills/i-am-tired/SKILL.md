---
name: i-am-tired
description: Switch every reply to the three-slot tired format — what the mechanism is, what's wrong with it, how we'd fix it — in plain language, ending in one yes/no gate. Compresses what is already known; never starts new investigation. Use when the user says "我很累", "沒辦法接受太多資訊", "簡潔地告訴我", "i'm tired", "keep it short", or asks for a decision they clearly want to make in one breath.
---

# I am tired

The user is out of budget for reading. They still have enough for one decision.
Spend their remaining attention on the decision, not on your findings.

Stays in effect for every reply until they say otherwise — and style decays over a
long session, so re-read this file rather than copying the shape of your last
answer.

## The three slots

```
1. 現在的機制
- <one line>
- <one line>

2. 問題
- <one line>
- <one line>

3. 修法
<the fix as one headline sentence>
- <what that means, one line>
- <what that means, one line>

<one yes/no gate>
```

Two to four lines per slot. No sub-bullets, no nesting, no tables, no code blocks.

Nothing else in the reply: no preamble, no "簡短版如下", no closing offer, no
mention of what you read or ran to know this.

If there is no defect to report, the slots become **現況 / 卡在哪 / 下一步** —
same shape, same limits. That is the only substitution; don't invent others.

## How each slot is written

**現在的機制** — the behaviour as the user would describe it to a colleague, in
their own domain words (停牌、門檻、多空比、Lark). No identifiers, no paths, no
function names, no ids, unless the user said that name first.

**問題** — one consequence per line, named as a symptom they could feel, not as a
mechanism: 刪得太多 / 刪得太乾淨 / 刪完就不再告警. Parallel phrasing across the
lines so the list can be held in one breath. Never explain the cause chain here —
the cause is why you believe it, not what they need to decide.

**修法** — the headline first, in the form "不做 X，改成 Y". Then what Y means,
one line each, same order as the problems above it. No alternatives, no trade-off
discussion, no risk list. You already chose; a tired reader is not a review board.

**The gate** — exactly one yes/no, naming the single thing you'd do next and its
id if it has one: `你說好，我就開 PH-04 去修`. Not a menu. Two options only when
they are genuinely incompatible and you'd be guessing — then two, with your
recommendation first and one consequence clause each. Never three.

## What gets cut, and where it goes

Everything cut has a home that is not this reply, and it goes there **before** you
answer, so the compression loses nothing:

- findings, risks, open questions → the ledger (`item-ledger`), with ids
- what the system now does → `docs/spec/`
- the reasoning behind the chosen fix → a `D` row

Then the reply can be four lines without anything being lost. If a cut item has no
home yet, write it down first; "I'll mention it when they're less tired" is how it
disappears.

## Never

- Start new investigation because a slot is thin. Say `不確定：<one line>` and let
  the gate be whether to go look.
- Report how you know (files read, commands run, subagents launched, tests green).
- Hedge a concluded finding, or soften the fix with "可能可以考慮".
- Mention ids other than the one in the gate.
- Act on the gate before they answer. The whole point is that one word from them
  is enough, so wait for the word.
