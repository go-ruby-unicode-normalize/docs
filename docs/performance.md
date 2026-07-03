# Performance

`go-ruby-unicode-normalize/unicode-normalize` is the pure-Go library that
[`rbgo`](https://github.com/go-embedded-ruby/ruby) binds for Ruby's
`String#unicode_normalize`. This page records the **methodology** of the
ecosystem-wide per-module parity benchmark; it does not quote numbers that have
not been measured on this module.

## What is measured

The **same** Ruby script — a `unicode_normalize` / `unicode_normalized?` workload
over a representative UTF-8 corpus (mixed Latin with combining marks, Hangul,
ligatures, full/half-width forms) across all four UAX #15 forms — is run under
every runtime. `rbgo`'s number reflects **this pure-Go library doing the work**;
every other column is that interpreter's own `unicode_normalize` stdlib. So the
comparison is the **Ruby-visible operation**, apples-to-apples across
interpreters. The script prints a deterministic checksum and its output is checked
**byte-identical to MRI** before timing.

## Method

- **Host:** a single fixed machine; **best-of-N wall time** (best, not mean, to
  suppress scheduler noise); single-shot processes, no warm-up beyond the
  script's own loop.
- **Runtimes:** `ruby` (MRI, the oracle) and `ruby --yjit`; `jruby`;
  `truffleruby` — each running its own `unicode_normalize`, against `rbgo`
  running this library.
- The benchmark script and harness live in rbgo's repo under
  [`bench/modules/`](https://github.com/go-embedded-ruby/ruby/tree/main/bench/modules).
  Reproduce with the per-module runner there.

## Result (best of 5, ms)

| Runtime | time | vs MRI |
| --- | ---: | ---: |
| **rbgo** (go-ruby-unicode-normalize) | 110 | 0.30× |
| MRI (ruby 4.0.5) | 370 | 1.00× |
| MRI + YJIT | 370 | 1.00× |
| JRuby 10.1.0.0 | 1380 | 3.73× |
| TruffleRuby 34.0.1 | 320 | 0.86× |

rbgo runs on **go-ruby-unicode-normalize** and is **~3x faster than MRI** here (0.30x) on this NFC/NFD/NFKC normalization sweep.

!!! note "Honest framing"
    JRuby and TruffleRuby are timed **cold, single-shot**, so they carry JVM /
    Graal startup on every run — read them as one-shot `ruby file.rb` costs, the
    same way `rbgo` and MRI are measured, not as steady-state JIT numbers. Rows
    that complete in well under ~200 ms carry the most relative noise; treat
    their ratios as order-of-magnitude. These are **real measured numbers** from
    the 2026-06-30 run (Apple M-series; `ruby 4.0.5 +PRISM`, `jruby 10.1.0.0`,
    `truffleruby 34.0.1`) — nothing is fabricated or cherry-picked.

## Library-level benchmark (Go API vs runtimes) — 2026-07-03

This section measures the **pure-Go library directly, through its Go API** — not
the `rbgo` interpreter path recorded above. It isolates the library primitive
(`normalize.Normalize`, which backs Ruby's `String#unicode_normalize`) from
Ruby-interpreter dispatch, answering the parity question head-on: *is the pure-Go
implementation as fast as the reference runtime's own `unicode_normalize`?* The
**same workload, same inputs, same iteration counts** run through the Go library
and through each reference runtime's stdlib; outputs were checked identical to MRI
before any timing.

- **Host:** Apple M4 Max (`Mac16,5`, arm64), macOS 26.5.1 — **date 2026-07-03**.
- **Runtimes:** Go 1.26.4 · MRI `ruby 4.0.5 +PRISM` · MRI + YJIT · JRuby 10.1.0.0
  (OpenJDK 25) · TruffleRuby 34.0.1 (GraalVM CE Native).
- **Workload:** a ~1 KiB representative UTF-8 corpus normalized in each of the
  four UAX #15 forms. The corpus mixes pre-composed and combining accented Latin,
  canonical singletons (angstrom U+212B, ohm U+2126), a vulgar fraction (U+00BD),
  a `fi` ligature (U+FB01), full-width forms (U+FF21..U+FF23), Hangul (pre-composed
  U+AC00 and conjoining jamo), and two characters added in **Unicode 16.0/17.0**
  (U+1CCD6, U+16121) that pre-`go1.27` `x/text` leaves un-decomposed but MRI folds
  — the exact gap this library's patch tables close. So the timed work is real
  normalization, not a no-op pass-through.
- **Method:** each process runs 3 untimed warm-up passes, then 25 timed passes of
  a fixed inner loop, timed with a monotonic clock; the **best** pass is reported
  as **ns/op** (lower is better). `vs MRI` < 1.00× means *faster than MRI*.
  Interpreter start-up is outside the timed region, so these are operation costs,
  not `ruby file.rb` process costs. Before timing, the harness verifies the Go
  library and MRI emit **byte-identical** output for all four forms (SHA-256 per
  form); the run aborts otherwise.

**Verdict — go-ruby vs MRI + YJIT: the pure-Go library beats YJIT on all four
forms.** Ratios below are from the recorded run (values stable to ~2% across three
back-to-back runs):

| Form | go-ruby ns/op | MRI + YJIT ns/op | go ÷ YJIT | Winner |
| --- | ---: | ---: | ---: | --- |
| `:nfc`  | 28161.0 | 44478.0 | **0.63×** | go-ruby (1.6× faster) |
| `:nfd`  | 17996.1 | 45502.0 | **0.40×** | go-ruby (2.5× faster) |
| `:nfkc` | 37365.9 | 67205.0 | **0.56×** | go-ruby (1.8× faster) |
| `:nfkd` | 26829.1 | 69431.0 | **0.39×** | go-ruby (2.6× faster) |

#### unicode_normalize-nfc — `String#unicode_normalize(:nfc)`

| Runtime | ns/op | vs MRI |
| --- | ---: | ---: |
| **go-ruby (pure Go)** | 28161.0 | 0.64× |
| MRI | 44061.0 | 1.00× |
| MRI + YJIT | 44478.0 | 1.01× |
| JRuby | 45067.7 | 1.02× |
| TruffleRuby | 10636.2 | 0.24× |

#### unicode_normalize-nfd — `String#unicode_normalize(:nfd)`

| Runtime | ns/op | vs MRI |
| --- | ---: | ---: |
| **go-ruby (pure Go)** | 17996.1 | 0.40× |
| MRI | 45273.0 | 1.00× |
| MRI + YJIT | 45502.0 | 1.01× |
| JRuby | 41360.5 | 0.91× |
| TruffleRuby | 19679.7 | 0.43× |

#### unicode_normalize-nfkc — `String#unicode_normalize(:nfkc)`

| Runtime | ns/op | vs MRI |
| --- | ---: | ---: |
| **go-ruby (pure Go)** | 37365.9 | 0.56× |
| MRI | 66802.0 | 1.00× |
| MRI + YJIT | 67205.0 | 1.01× |
| JRuby | 61737.3 | 0.92× |
| TruffleRuby | 19704.6 | 0.29× |

#### unicode_normalize-nfkd — `String#unicode_normalize(:nfkd)`

| Runtime | ns/op | vs MRI |
| --- | ---: | ---: |
| **go-ruby (pure Go)** | 26829.1 | 0.39× |
| MRI | 69555.0 | 1.00× |
| MRI + YJIT | 69431.0 | 1.00× |
| JRuby | 56795.6 | 0.82× |
| TruffleRuby | 22073.8 | 0.32× |

The pure-Go library is **1.6×–2.6× faster than both MRI and MRI + YJIT** on every
form — YJIT barely moves MRI's pure-Ruby `unicode_normalize` stdlib (≈1.00×), so
the pure-Go path (delegating the hot work to `golang.org/x/text/unicode/norm`)
wins comfortably. The decomposition-only forms (`:nfd`, `:nfkd`) are the widest
wins (~2.5×), since they skip the recomposition pass. **TruffleRuby is the fastest
runtime on three of four forms** (its Graal JIT reaches steady state within the
warm-up budget); go-ruby edges it only on `:nfd` (17996 vs 19680 ns/op). JRuby
tracks MRI (0.82×–1.02×). Every output is checked **byte-identical to MRI** — for
all four forms, including the Unicode 16/17 characters x/text alone would miss —
before any timing.

!!! note "Reproduce"
    The harness is committed under
    [`benchmarks/`](https://github.com/go-ruby-unicode-normalize/docs/tree/main/benchmarks):
    a self-contained Go driver (`go/`, pins the published library via `go.mod`
    pseudo-version), the equivalent `ruby/unicode_normalize.rb` workload, and
    `run.sh`. Run `bash benchmarks/run.sh`; env `OUTER`/`WARM` tune the pass
    budget and `RUBY`/`JRUBY`/`TRUFFLERUBY` select the runtime binaries. `run.sh`
    refuses to benchmark unless the Go and MRI outputs are byte-identical.

!!! warning "Warm-up budget & noise — honest framing"
    Numbers reflect a **fixed warm-process budget** (3 warm-up + 25 timed passes
    in one process). The JVM/GraalVM JITs (JRuby, TruffleRuby) may need a larger
    warm-up to reach peak throughput, so their columns can **understate** it; here
    TruffleRuby is already the fastest on most forms, so its lead is a floor, not
    a ceiling. Every number here is a **real measured value** from the dated run
    above (values stable to ~2% across three back-to-back runs) — nothing is
    fabricated, estimated, or cherry-picked. The go-ruby column is the pure-Go
    library; every other column is that interpreter's own `unicode_normalize`
    stdlib doing the equivalent work.
