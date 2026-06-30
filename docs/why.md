# Why pure Go

`go-ruby-unicode-normalize/unicode-normalize` reimplements Ruby's
`unicode_normalize` standard library in **pure Go, with cgo disabled**. Unicode
normalization is **deterministic and interpreter-independent**: given a string
and a form, the result is a pure function of the Unicode Character Database — no
live binding, no evaluation of arbitrary Ruby. That is exactly the part that
can — and should — live as a standalone Go library, separate from the interpreter.

## A reusable library, bound by rbgo

This library is the deterministic core that backs Ruby's
`String#unicode_normalize` in [go-embedded-ruby](https://github.com/go-embedded-ruby/ruby).
It is **standalone and reusable** so that:

- any Go program can import
  `github.com/go-ruby-unicode-normalize/unicode-normalize` directly, with no Ruby
  runtime;
- the dependency runs the *other* way — `rbgo` binds this module as a native
  module (the same pattern as [go-ruby-regexp](https://github.com/go-ruby-regexp)
  and [go-ruby-yaml](https://github.com/go-ruby-yaml)), rather than this module
  depending on the interpreter;
- the behaviour is pinned by a **differential oracle** against the system
  `ruby`, independent of any one consumer.

## Why pure Go matters here

The heavy lifting is delegated to
[`golang.org/x/text/unicode/norm`](https://pkg.go.dev/golang.org/x/text/unicode/norm),
which is itself **cgo-free**. Because this module and its core dependency carry
no C, the library:

- cross-compiles to every Go target with no C toolchain, and links into a single
  static binary;
- has **no dependency on the Ruby runtime** — the dependency runs the other way;
- can be differentially tested against the `ruby` binary wherever one is on
  `PATH`, while the cross-arch lanes (where `ruby` is absent) still validate the
  library itself.

## One result on every toolchain

There is a subtlety: `x/text` gates its Unicode 17.0.0 tables behind the
`go1.27` build tag and otherwise falls back to Unicode 15.0.0, while MRI 4.0.5
normalizes against Unicode 17.0.0. Rather than raise the Go floor, this module
ships a small **override table** that patches exactly the Unicode 16.0/17.0
characters fallback would leave un-normalized — so the result matches MRI
**byte-for-byte on `go 1.26.4` and on `go1.27+` alike** (where the patch is a
no-op). Determinism is preserved across the whole supported toolchain range.

See [Usage & API](api.md) for the surface and [Roadmap](roadmap.md) for what is
in scope.
