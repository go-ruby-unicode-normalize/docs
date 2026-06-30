# Roadmap

`go-ruby-unicode-normalize/unicode-normalize` is grown **test-first**, each
capability differential-tested against MRI rather than built in isolation. Ruby's
`unicode_normalize` standard library — the deterministic,
interpreter-independent slice — is **complete**.

| Stage | What | Status |
| --- | --- | --- |
| Normalize | `Normalize(s, form)` returns UTF-8 text in any of the four UAX #15 forms (NFC, NFD, NFKC, NFKD), matching `String#unicode_normalize` byte-for-byte; NFC is the default form. | **Done** |
| IsNormalized | `IsNormalized(s, form)` reports whether a string is already in the given form — `String#unicode_normalized?` — without rewriting the bytes. | **Done** |
| The four UAX #15 forms | `NFC` / `NFD` / `NFKC` / `NFKD` as `Form` values mapping to Ruby's `:nfc` / `:nfd` / `:nfkc` / `:nfkd`; zero value `NFC`; `Form.String` returns the Ruby symbol name. | **Done** |
| x/text core | Heavy lifting delegated to the cgo-free `golang.org/x/text/unicode/norm`; agrees with MRI on Hangul composition, ligatures, full/half-width folding and combining-mark ordering. | **Done** |
| Unicode 17.0.0 patch | An override table patches exactly the Unicode 16.0/17.0 characters x/text leaves un-normalized on the `go 1.26.4` floor, so the result matches MRI on every toolchain (no-op on `go1.27+`). | **Done** |
| Differential oracle & coverage | An exhaustive sweep of every assigned scalar value × all four forms, plus a curated edge-case corpus and combining-sequence fuzz, run against the system `ruby`; 100% coverage, gofmt + go vet clean, green across all six 64-bit Go arches and three OSes. | **Done** |

## Documented out-of-scope boundaries

These are **deliberate**, recorded so the module's surface is unambiguous:

- **No interpreter.** The library implements the deterministic normalization
  algorithm; it never runs arbitrary Ruby. Invalid-UTF-8 handling and the
  `ArgumentError` on an unknown form symbol are the host binding's job — that is
  why `rbgo` binds this module rather than the reverse.
- **Reference is reference Ruby (MRI).** Byte-for-byte conformance targets MRI
  4.0.5 (Unicode 17.0.0); the differential oracle gates on `RUBY_VERSION >= "4.0"`.
- **Standalone & reusable.** The module has no dependency on the Ruby runtime;
  the dependency runs the other way.

See [Usage & API](api.md) for the surface and [Why pure Go](why.md) for the
deterministic/interpreter split.
