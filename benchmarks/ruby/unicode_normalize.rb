# frozen_string_literal: true
# encoding: UTF-8
# SPDX-License-Identifier: BSD-3-Clause
require "digest"
require_relative "_harness"

# UNIT is byte-identical to the Go driver's `unit` (main.go). It is written with
# explicit \u{...} escapes — never literal glyphs — so the two workloads are
# provably the same bytes regardless of file encoding. Reads as
# "Cafe naive Angstrom Ohm 1/2 file ABC gaga <U+1CCD6><U+16121>":
#   - accented Latin, pre-composed (U+00E9, U+00EF, U+00F6);
#   - canonical singletons (angstrom U+212B, ohm U+2126);
#   - a fraction (U+00BD), a "fi" ligature (U+FB01) and full-width forms
#     (U+FF21..U+FF23) that only the compatibility K-forms fold;
#   - Hangul, pre-composed (U+AC00) and as conjoining jamo (U+1100 U+1161);
#   - two Unicode 16.0/17.0 additions MRI folds but pre-go1.27 x/text does not
#     (U+1CCD6 -> "A", U+16121 -> U+1611E U+1611E) — this library's patch path.
UNIT = "Caf\u{E9} na\u{EF}ve \u{212B}ngstr\u{F6}m \u{2126}hm \u{BD} \u{FB01}le" \
       " \u{FF21}\u{FF22}\u{FF23} \u{AC00}\u{1100}\u{1161} \u{1CCD6}\u{16121}\n"
CORPUS = (UNIT * 16).freeze # ~1 KiB of mixed, decomposable UTF-8

FORMS = %i[nfc nfd nfkc nfkd].freeze

if ARGV[0] == "check"
  # Emit a stable digest of each form's output so run.sh can prove MRI and the
  # Go library agree byte-for-byte before any timing is recorded.
  FORMS.each do |f|
    printf("CHECK\t%s\t%s\n", f, Digest::SHA256.hexdigest(CORPUS.unicode_normalize(f)))
  end
  exit
end

FORMS.each do |f|
  bench("unicode_normalize-#{f}", 1000) { CORPUS.unicode_normalize(f) }
end
