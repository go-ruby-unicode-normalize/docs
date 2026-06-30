# Usage & API

The public API lives at the module root
(`github.com/go-ruby-unicode-normalize/unicode-normalize`, package `normalize`).
It is **Ruby-shaped but Go-idiomatic**: `Normalize` / `IsNormalized` mirror
`String#unicode_normalize` / `String#unicode_normalized?`, while the surface
follows Go conventions — value types, no global state, no error return (invalid
UTF-8 handling is the host binding's job).

!!! success "Status: implemented"
    The library is built and importable as
    `github.com/go-ruby-unicode-normalize/unicode-normalize`, bound into `rbgo`
    as a native module; see [Roadmap](roadmap.md).

## Install

```sh
go get github.com/go-ruby-unicode-normalize/unicode-normalize
```

## Worked example

```go
import normalize "github.com/go-ruby-unicode-normalize/unicode-normalize"

normalize.Normalize("é", normalize.NFC)   // "é"  (composes e + acute)
normalize.Normalize("é",        normalize.NFD)   // "é" (decomposes)
normalize.Normalize("ﬁ",        normalize.NFKC)  // "fi"  (ligature -> ascii)
normalize.Normalize("①",        normalize.NFKC)  // "1"
normalize.Normalize("Ａ",       normalize.NFKC)  // "A"   (full-width -> ascii)
normalize.IsNormalized("é",     normalize.NFC)   // true  (composed)
normalize.IsNormalized("é",            normalize.NFC)  // false (decomposed)
```

## Shape

```go
// Normalize returns s in the given form. NFC is the default form for Ruby's
// unicode_normalize when called with no argument.
func Normalize(s string, form Form) string

// IsNormalized reports whether s is already in the given form
// (Ruby's unicode_normalized?).
func IsNormalized(s string, form Form) bool

// Form is one of the four UAX #15 normalization forms.
type Form int

const (
	NFC  Form = iota // Ruby :nfc (the zero value, Ruby's default)
	NFD              // Ruby :nfd
	NFKC             // Ruby :nfkc
	NFKD             // Ruby :nfkd
)

// String returns the Ruby symbol name (":nfc", ":nfd", ":nfkc", ":nfkd").
func (f Form) String() string
```

The four forms are the `normalize.Form` values `NFC`, `NFD`, `NFKC`, `NFKD`,
corresponding to Ruby's `:nfc`, `:nfd`, `:nfkc`, `:nfkd`. The zero value is
`NFC`, mirroring Ruby's default. `Form.String` returns the Ruby symbol name for
diagnostics and for the rbgo binding layer.

## What the host binds

This library is the deterministic, interpreter-free core. The `rbgo` binding
wires `Normalize` to `String#unicode_normalize` and `IsNormalized` to
`String#unicode_normalized?`, defaults the form to `:nfc`, maps the
`:nfc` / `:nfd` / `:nfkc` / `:nfkd` symbols to `Form`, raises `ArgumentError`
on an unknown form symbol and on invalid UTF-8 byte sequences (matching MRI),
and otherwise hands the bytes straight through.

## How it works

The heavy lifting is delegated to
[`golang.org/x/text/unicode/norm`](https://pkg.go.dev/golang.org/x/text/unicode/norm),
a pure-Go (cgo-free) implementation of the same Unicode standard. Both MRI 4.0.5
and `x/text` target **Unicode 17.0.0**, so they agree across the official
NormalizationTest corpus and the Ruby-specific edge cases — Hangul composition,
full/half-width and ligature compatibility, combining-mark ordering.

`x/text` gates its Unicode 17.0.0 tables behind the `go1.27` build tag and
otherwise falls back to Unicode 15.0.0. On this module's `go 1.26.4` floor that
fallback would leave a handful of characters added in Unicode 16.0/17.0
un-normalized relative to MRI — new canonical decompositions/compositions in
some Indic and historic scripts, and new compatibility mappings folding to ASCII
(`U+A7F1` → `S`, the outlined alphanumerics `U+1CCD6..U+1CCF9` → `A`–`Z` /
`0`–`9`). An override table (`tables_unicode17.go` + `patch.go`) patches exactly
those characters, so the result matches MRI on **every** toolchain. On `go1.27+`,
where `x/text` already expands them, the override runes never appear and the
patch is a no-op.

## MRI conformance

Correctness is defined by reference Ruby. A **differential oracle** runs a wide
corpus — including an exhaustive sweep of every assigned scalar value × all four
forms — through both the system `ruby` and this library and compares the results
**byte-for-byte**, not approximated from memory. The oracle tests skip themselves
where `ruby` is absent (e.g. the qemu arch lanes and Windows) and gate on
`RUBY_VERSION >= "4.0"`, so the cross-arch builds still validate the library.

## Relationship to Ruby

`go-ruby-unicode-normalize/unicode-normalize` is **standalone and reusable**, and
is the backend bound into
[go-embedded-ruby](https://github.com/go-embedded-ruby/ruby) by `rbgo` as a
native module — the same way [go-ruby-regexp](https://github.com/go-ruby-regexp)
and [go-ruby-yaml](https://github.com/go-ruby-yaml) are bound. The dependency
runs the other way: this library has no dependency on the Ruby runtime.
