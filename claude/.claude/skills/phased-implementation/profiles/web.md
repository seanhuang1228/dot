# Profile: Web (React + TypeScript)

## Marker

`package.json` at the touched package's root.

In a mixed repo the *touched package's* root decides, not the repo root — a repo
with `Cargo.toml` at the root and `package.json` in a `web/` subdirectory selects
this profile for work under `web/` and the Rust profile for work under the crates.
Two different markers at the same root is the ambiguous case the core file says to
ask about.

Run every command below from the package root, not the repo root.

**Ports come from the environment.** When dispatched, `PORT` (dev server),
`API_PORT`, `WORKTREE_ID`, and `COMPOSE_PROJECT_NAME` are set for this worktree so
parallel phases don't collide. Never pass a literal port to a dev server or a
browser runner, and never "fix" a port clash by picking another number — if a
config ignores `PORT` (Vite without `strictPort`, a Playwright `baseURL` with a
hardcoded port), report it as a finding; it's a repo bug.

**Before step 1, read the package's own conventions** — a `CLAUDE.md`, `README.md`,
or `CONTRIBUTING.md` at the package root. This profile is the stack-generic layer;
where the package documents its own gates, test layout, or guard tests, those win
over anything here, and they are usually where the expensive-to-rediscover traps
are written down.

## Parameter table categories (step 3)

Hardcoded: route paths and query-parameter *names*, i18n keys, `data-testid`
values, error codes from the backend, breakpoint pixel values, class strings that
encode a design token.

Configurable: build-time env (`import.meta.env` / `process.env`), data-layer cache
and refetch intervals, page sizes and list limits, debounce/throttle delays,
feature flags.

Give each navigation target its own row. A URL like
`page.html?market=perp&symbol=BTC%2FUSDT` is four separate decisions — page, param
names, value format, encoding — and the encoding is the one no type checks.

## Skeleton conventions (step 5)

TypeScript has no `todo!()`. Which stub form applies depends on the shape of the
unit of work — decide before writing the checkpoint:

**New function, module, or component** — real signature, body
`throw new Error('not implemented: <what>')`. A stub returning a plausible default
(`null`, `[]`, `false`, an empty fragment) is not a stub; it lets tests pass
vacuously. Same rule as every other stack.

**Behaviour change to existing code** — the common case for a bug ticket. There is
no new signature to stub, and gutting working code to stub it is worse than leaving
it alone. Here the checkpoint commit is **failing tests only**: existing code
untouched, plus tests encoding the new expected behaviour that are red against
today's code. The checkpoint keeps both properties that matter — it is the revert
target, and it fixes the contract before the implementation subagent sees it. Say
in the commit message that it is red on purpose and which assertions should fail.

Also:

- **Follow the package's existing test layout** — co-located `Foo.test.tsx` beside
  `Foo.tsx`, or a `__tests__/` directory, or a separate `test/` tree. Look at what
  is already there; do not introduce a second convention.
- **Check the runner's include/exclude patterns before placing a new test file.**
  A unit runner and a browser runner (Playwright, Cypress, WebdriverIO) frequently
  have overlapping default globs — Vitest's default include catches `*.spec.ts`,
  which is also the browser runner's usual suffix. Getting this wrong fails in both
  directions and both are quiet: a unit test in the excluded directory never runs
  and reports nothing, and a browser test dragged into jsdom takes the whole unit
  run down with it. Read the config, don't infer from the filename.
- **Pin the locale in any test asserting user-facing text**, if the app has i18n.
  jsdom has no browser language, so a language detector falls through to its
  fallback and an unpinned test asserts on whatever the environment happened to be —
  which changes on someone else's machine, or on a detector upgrade, without a
  code change.
- **Check the tsconfig's strictness before writing stubs.** With `noUnusedLocals`
  and `noUnusedParameters` on, a stub that accepts a prop it does not yet use fails
  the typecheck gate; prefix with `_` or reference it.

Run the unit tests once against the skeleton before committing the checkpoint and
confirm every new test fails **on its assertion**, not on an import error or a
crash inside `render()`. A test that dies during render proves nothing about the
contract, and it will keep "failing correctly" no matter what the subagent writes.

## Implementation guidance (step 7)

Paste into the implementation subagent's prompt:

> Surface genuine failures to the user, don't swallow them. Any network or
> streaming call you add needs a visible error state — or an explicit note in your
> report saying why the caller already handles it. A caught error that only reaches
> `console.error` is invisible to everyone without devtools open. This is the
> user-facing analogue of ops logging; it is not a licence to scatter `console.log`,
> and don't add analytics events unless the plan called for them.
>
> Don't reach for `any`, an `as` cast, `@ts-expect-error`, or `@ts-ignore` to get
> past the typecheck — fix the types. Don't add dependencies the plan didn't list
> without saying so in your report.
>
> If the app has i18n, every user-facing string goes through the translation
> function with the key added to every locale file, not just the one you can read.
>
> Read the package's conventions file if it has one; its rules override the generic
> guidance in this prompt.

## Fast check commands (step 8)

**Read `package.json`'s `scripts` and use what the package actually declares** —
do not assume the usual names exist. Run them in gate order: format, then lint,
then types, then unit tests.

Typical, in a package that has them all:

```
npx prettier --check .
npx eslint .
npx tsc --noEmit
npx vitest run <touched test paths>    # the ticket's own tests
npx vitest run                         # full unit suite
```

Four things that differ from a compiled-language profile:

- **Not every TS package has a formatter or linter.** Some declare `lint` as an
  alias for the typecheck and have neither eslint nor prettier as a dependency.
  Check before you gate on it — and if there is none, say so and drop that gate
  rather than letting a subagent add a formatter mid-ticket.
- **The typecheck can't be scoped to a subset of files.** `tsc` covers whatever the
  tsconfig includes; there is no per-package flag equivalent. It is usually fast
  enough to run whole every iteration.
- **Establish the baseline before step 5.** Run the whole gate once on the
  unmodified checkout and record what is already failing. A pre-existing red gate
  is worse than no gate: the subagent either believes it broke something, or
  "helpfully" fixes files outside the ticket, or learns to ignore the gate's output
  including its own errors. If the baseline is red in a bounded, unrelated area,
  either fix it first or filter the gate to the paths the ticket owns
  (`... 2>&1 | grep '^src/'`) and say explicitly in the work order which errors are
  pre-existing and not the subagent's to touch.
- **Contract tests and browser E2E do not belong in the per-iteration gate.** They
  need a live backend or a real browser, they are slow, and they fail for reasons
  unrelated to the diff. Run them at acceptance, if at all.

## Review criteria (step 9)

Paste into the review prompt in addition to the core criteria:

- **jsdom cannot see CSS.** A pass criterion about cursor shape, hover colour,
  opacity, spacing, or layout is *not* covered by a passing unit test — at best the
  test asserts that a class name is present, which stays true after the stylesheet
  stops applying it. Flag every such criterion as needing the acceptance check, and
  flag any test whose name claims it verifies a visual property. Why: this is the
  most common way a green gate lies on this stack, and it lies in the direction of
  "looks done".
- **Assert behaviour, not implementation.** Testing Library queries by role, label,
  or text. A test reaching for a class name or a `data-testid` where a role exists
  keeps passing after the element becomes invisible, disabled, or unreachable by
  keyboard.
- **Nested click targets need both halves asserted.** Where a handler calls
  `stopPropagation`, the test must assert the inner handler fired *and* the outer
  one did not. Why: asserting only the inner one passes just as happily when the
  event also bubbles and triggers a navigation nobody wanted.
- **A path the plan said is local must issue no request.** Spy on the fetch layer
  and assert it was not called. Why: "it also did something extra" is invisible in a
  screenshot and can be expensive — an unintended call to a metered or billed
  endpoint is a defect no visual check will ever surface.
- **Effect cleanup.** Any `useEffect` that subscribes, opens a stream, or sets a
  timer returns a cleanup function, and its dependency array is complete. Why: the
  symptom is a leak that appears only after several navigations, which no unit test
  in a typical suite is shaped to catch.
- **Accessibility of anything newly made interactive.** A `div` given an `onClick`
  needs a role, a tab stop, and a keyboard handler, or it should have been a
  `button`. Why: mouse-only interactive elements pass every mouse-driven test.
- **i18n completeness.** New strings go through the translation function and exist
  in every locale file. A key present in one locale and missing in another renders
  as the raw key, which looks like a bug in the backend.
- **Premature abstraction** — a component extracted for a single call site, a
  generic prop with one instantiation, a context introduced for one consumer. Why:
  it costs readers now and pays off only if a second use appears; the plan would
  have said so.

## Acceptance

Both gates green is **not** acceptance whenever the ticket has a visual or
navigational pass criterion — which for UI work is almost always. jsdom asserts
structure; it does not render, lay out, or paint.

Before the step-12 wrap-up:

1. Start the app the way the package documents (`npm run dev` unless it says
   otherwise), with whatever backend it needs.
2. Drive the actual case from step 1's pass criteria. If the repo provides a
   screenshot or visual-check script, use it rather than writing a new one — and
   read its header before overriding its flags, since these scripts usually exist
   because a naive screenshot got something wrong.
3. Report per visual criterion what was actually observed, and say plainly which
   criteria were confirmed by eye and which are still only class-name-deep.
   "Tests pass" is not an answer to "does the row highlight on hover".
