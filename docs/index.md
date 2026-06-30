# go-ruby-unicode-normalize documentation

**Ruby's `String#unicode_normalize` in pure Go — the four UAX #15 forms, MRI-compatible, no cgo.**

`go-ruby-unicode-normalize/unicode-normalize` is a faithful, pure-Go (zero cgo)
reimplementation of Ruby's `unicode_normalize` standard library —
`String#unicode_normalize` and `String#unicode_normalized?` — matching reference
Ruby (MRI 4.0.5, Unicode 17.0.0) byte-for-byte. The module path is
`github.com/go-ruby-unicode-normalize/unicode-normalize` and the package is
`normalize`.

It is the Unicode-normalization backend bound into
[go-embedded-ruby](https://github.com/go-embedded-ruby/ruby) by `rbgo` as a
native module — just like [go-ruby-regexp](https://github.com/go-ruby-regexp)
(the Onigmo engine) and [go-ruby-yaml](https://github.com/go-ruby-yaml) (the
Psych port) — but it is a **standalone, reusable** module with **no dependency on
the Ruby runtime**. The dependency runs the other way.

!!! success "Status: complete — MRI byte-exact"
    `Normalize` and `IsNormalized` cover all four UAX #15 forms — **NFC / NFD / NFKC / NFKD**. Validated by a **differential oracle** against the system `ruby` / `unicode_normalize` — a curated edge-case corpus, a combining-sequence fuzz, and an exhaustive sweep of every assigned scalar value × all four forms — at 100% coverage, `gofmt` + `go vet` clean, CI green across the six 64-bit Go targets and three OSes.

## Quick taste

```go
import normalize "github.com/go-ruby-unicode-normalize/unicode-normalize"

normalize.Normalize("é", normalize.NFC)   // "é"  (composes e + acute)
normalize.Normalize("é",        normalize.NFD)   // "é" (decomposes)
normalize.Normalize("ﬁ",        normalize.NFKC)  // "fi"  (ligature -> ascii)
normalize.Normalize("Ａ",       normalize.NFKC)  // "A"   (full-width -> ascii)
normalize.IsNormalized("é",     normalize.NFC)   // true  (composed)
```

## Repositories

| Repo | What it is |
| --- | --- |
| [`unicode-normalize`](https://github.com/go-ruby-unicode-normalize/unicode-normalize) | the library — Ruby's `unicode_normalize` stdlib in pure Go |
| [`docs`](https://github.com/go-ruby-unicode-normalize/docs) | this documentation site (MkDocs Material, versioned with mike) |
| [`go-ruby-unicode-normalize.github.io`](https://github.com/go-ruby-unicode-normalize/go-ruby-unicode-normalize.github.io) | the organization landing page (Hugo) |
| [`brand`](https://github.com/go-ruby-unicode-normalize/brand) | logo and brand assets |

## Principles

- **Pure Go, `CGO_ENABLED=0`** — trivial cross-compilation, a single static
  binary, no C toolchain; the `x/text` core is itself cgo-free.
- **MRI byte-exact.** Output matches reference Ruby exactly across every assigned
  scalar value and all four forms, validated by a differential oracle against the
  `ruby` binary.
- **Unicode 17.0.0 everywhere.** An override table patches the Unicode 16.0/17.0
  characters x/text would leave un-normalized on older toolchains, so the result
  is identical on `go 1.26.4` and `go1.27+`.
- **Standalone & reusable.** No dependency on the Ruby runtime — the dependency
  runs the other way.
- **100% test coverage** is the target, enforced as a CI gate, across 6 arches
  and 3 OSes.

## Where to go next

- [Why pure Go](why.md) — why Unicode normalization is deterministic enough to
  live as a standalone, interpreter-independent Go library.
- [Usage & API](api.md) — the public surface and worked examples.
- [Roadmap](roadmap.md) — what is done and what is downstream by design.

Source lives at
[github.com/go-ruby-unicode-normalize/unicode-normalize](https://github.com/go-ruby-unicode-normalize/unicode-normalize).
