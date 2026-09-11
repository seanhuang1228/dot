# Profile: Rust

## Marker

`Cargo.toml` at the repo root (workspace) or at the touched package's root.

## Parameter table categories (step 3)

Hardcoded: URLs, magic numbers, format strings, error codes, buffer sizes, channel
capacities. Configurable: env vars, config-struct fields, polling intervals, timeouts,
retry counts, feature flags.

## Skeleton conventions (step 5)

- Function/trait signatures with `todo!()` bodies. A stub that returns a plausible
  default (`Ok(())`, `Vec::new()`, `0`) is not a stub — it lets tests pass vacuously.
- Module structure in place (`mod` declarations, `pub use` re-exports) so the crate
  compiles with the stubs.
- Tests live where the crate already puts them (inline `#[cfg(test)] mod tests` vs.
  `tests/` integration dir — follow the existing convention, don't introduce the
  other one). Every test must panic on the `todo!()` when run against the skeleton;
  run `cargo test -p <pkg>` once before committing the checkpoint and confirm they
  all fail for that reason, not for a compile error.
- If a trait is being introduced, the skeleton is where its shape is fixed — the
  subagent implements it, it does not redesign it.

## Implementation guidance (step 7)

Paste into the implementation subagent's prompt:

> Add operational logging (`tracing`) on genuine failure paths you introduce — a
> caught error from an external call (network, upstream API, subprocess, disk)
> should log enough to diagnose it later (what was being attempted, the relevant
> identifier, the underlying error), not just get wrapped and returned. This is ops
> visibility, not business-event tracking; don't add analytics/funnel events unless
> the plan called for them. Skip logging on paths that aren't genuine failures — a
> validation rejection, an expected empty result, or an already-logged-by-the-caller
> error doesn't need its own log line.
>
> Don't add `#[allow(...)]` to silence clippy; fix the code. Don't add dependencies
> the plan didn't list without saying so in your report.

## Fast check commands (step 8)

In gate order, scoped to the touched package(s):

```
cargo fmt --check -p <pkg>
cargo clippy -p <pkg> --all-targets -- -D warnings
cargo test -p <pkg>
```

Use `-p` for every command; a full-workspace pass is only for the final pre-merge
review, not for each retry iteration.

## Review criteria (step 9)

Paste into the review prompt in addition to the core criteria:

- **Idiomatic Rust** — `?` over manual match-and-return, iterators over index loops
  where they read better, no needless `clone()`, `impl Trait` args where a concrete
  type isn't required. Why: the codebase should read as one author.
- **Premature abstraction** — a trait introduced for a single implementation, a
  generic parameter with exactly one instantiation. Why: it costs readers now and
  pays off only if a second impl ever appears; the plan would have said so.
- **Logging on failure paths — complete but not annoying** — every genuine
  external-call failure path (network, upstream API, subprocess, disk) should be
  diagnosable from logs alone, not just surfaced as an error to the caller. But don't
  flag the absence of a log line on every `?`/early-return — that's noise, and a
  reviewer that nags about it on every finding trains people to skip the review
  output. Flag it only where an on-call engineer would otherwise have nothing to go
  on (an outage in an external dependency, an adapter/infra boundary) — not on
  internal control flow, validation errors, or anything the caller will already log.
- **`unwrap`/`expect` outside tests** — each one needs a reason it can't fail, in a
  comment or in the `expect` message. Why: these are the panics that page someone.
- **Blocking in async** — `std::fs`, `std::thread::sleep`, blocking locks held across
  `.await`. Why: stalls the executor; hard to reproduce in tests.

## Acceptance

`cargo test -p <pkg>` green plus both gates passing is acceptance for a library or
service crate. For a binary with observable behavior the plan said to change (CLI
output, an HTTP endpoint), also run it once against the case in step 1's pass
criteria and paste the output into the wrap-up — tests exercise the code, this
exercises the wiring.
