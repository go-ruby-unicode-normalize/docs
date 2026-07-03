<!-- SPDX-License-Identifier: BSD-3-Clause -->
# `go-ruby-unicode-normalize` library-level benchmark harness

Reproducible, cross-runtime benchmark of the **pure-Go `go-ruby-unicode-normalize`
library** against the reference Ruby runtimes (MRI, MRI + YJIT, JRuby,
TruffleRuby). It measures the **library primitive** — `String#unicode_normalize`
in the four UAX #15 forms (`:nfc`, `:nfd`, `:nfkc`, `:nfkd`) — through the Go API,
isolated from the rbgo interpreter, so the numbers answer: *is the pure-Go
implementation as fast as the reference runtime's own `unicode_normalize`?*

## Layout

- `go/`          — self-contained Go driver; `go.mod` pins the published library
  by pseudo-version (no `replace`).
- `ruby/unicode_normalize.rb` — the equivalent workload; `ruby/_harness.rb` is the
  shared timer.
- `run.sh`       — verifies output, runs every available runtime and prints one
  Markdown table per sub-benchmark (ns/op + ratio vs MRI).

## Run

```sh
bash benchmarks/run.sh
```

Environment knobs: `OUTER` (timed passes, default 25), `WARM` (untimed warm-up
passes, default 3), and `RUBY`/`JRUBY`/`TRUFFLERUBY` to select runtime binaries.

## Method

Each process runs `WARM` untimed passes (to let the JVM/GraalVM JITs warm up),
then `OUTER` timed passes of a fixed inner loop, timed with a monotonic clock; the
**best** pass is reported as **ns/op**. Interpreter start-up is outside the timed
region. The Go driver and the Ruby script build **identical inputs** — the same
representative UTF-8 corpus (pre-composed and combining accented Latin, canonical
singletons, a fraction, a `fi` ligature, full-width forms, Hangul, and two
Unicode 16.0/17.0 additions this library patches over pre-go1.27 `x/text`).

Before timing, `run.sh` runs both drivers in `check` mode: each emits a SHA-256
digest of every form's normalized output, and the run **aborts unless the Go
library and MRI agree byte-for-byte**. Results are published, dated, in
`../docs/performance.md`.
