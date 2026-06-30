# Contributing

Contributions are welcome. `go-ruby-unicode-normalize/unicode-normalize` is built
to a small set of non-negotiable rules — they are what keep it pure-Go, correct,
and MRI-compatible. Please read these before opening a pull request.

## Hard rules

- **Build from source — no vendoring.** Everything compiles from source. Being
  able to compile from source is a guarantee of independence.
- **100% test coverage target, enforced in CI.** New code ships with tests, and
  coverage is a CI gate. Fill the error branches, not just the happy path.
- **All GitHub content in English.** Issues, pull requests, commits, comments,
  and discussions are English-only.
- **Differential testing against MRI.** Correctness is defined by reference
  Ruby. A corpus — including an exhaustive sweep of every assigned scalar value ×
  all four forms — is run through both `ruby` and this library and the results
  are compared byte-for-byte, not approximated from memory.
- **Pure Go, cgo disabled.** The whole point is a single static binary with no C
  toolchain. Code must build with `CGO_ENABLED=0`. The `x/text` core is itself
  cgo-free.
- **Unicode 17.0.0 on every toolchain.** Keep the override table in step with the
  reference Unicode version, so the result is identical on `go 1.26.4` and
  `go1.27+`.
- **A reusable library, not the interpreter.** This module implements the
  deterministic core. Anything that needs a live Ruby binding (invalid-UTF-8
  errors, form-symbol mapping) belongs in the consumer, not here.

## Workflow

1. Pick or open an issue describing the change.
2. Work test-first: add the differential / unit tests, then make them pass.
3. Run the full suite with coverage and confirm the gate is green:

    ```sh
    go test -race -coverpkg=./... -coverprofile=cover.out ./...
    go tool cover -func=cover.out | tail -1   # 100.0%
    go test -short ./...                       # skip the exhaustive sweep
    ```

4. Open a PR in English, referencing the issue.

## Where things live

The library is in
[`github.com/go-ruby-unicode-normalize/unicode-normalize`](https://github.com/go-ruby-unicode-normalize/unicode-normalize).
This documentation site is in
[`github.com/go-ruby-unicode-normalize/docs`](https://github.com/go-ruby-unicode-normalize/docs).
Start from the [Usage & API](api.md) page and the [Roadmap](roadmap.md) to find
the right place for your change.
