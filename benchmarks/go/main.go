// SPDX-License-Identifier: BSD-3-Clause
package main

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"os"

	normalize "github.com/go-ruby-unicode-normalize/unicode-normalize"
)

// unit is the representative UTF-8 workload, built from explicit code-point
// escapes (never literal glyphs) so it is provably byte-identical to the Ruby
// script's CORPUS regardless of editor or file encoding. Reads as
// "Cafe naive Angstrom Ohm 1/2 file ABC gaga <U+1CCD6><U+16121>". It mixes:
//   - accented Latin, pre-composed (e-acute U+00E9, i-diaeresis U+00EF,
//     o-diaeresis U+00F6), so NFC composes and NFD decomposes real characters;
//   - canonical singletons (angstrom U+212B -> U+00C5, ohm U+2126 -> U+03A9);
//   - a vulgar fraction (1/2 U+00BD), a Latin "fi" ligature (U+FB01) and
//     full-width forms (U+FF21..U+FF23) that only the compatibility K-forms fold;
//   - Hangul, pre-composed (U+AC00) and as conjoining jamo (U+1100 U+1161);
//   - two characters added in Unicode 16.0/17.0 that x/text (Unicode-15 tables
//     on the go1.26 floor) leaves un-decomposed but MRI folds — a compatibility
//     outlined-alphanumeric (U+1CCD6 -> "A") and a canonical composite
//     (U+16121 -> U+1611E U+1611E). These exercise this library's patch path,
//     the reason it exists.
const unit = "Café naïve Ångström Ωhm ½ ﬁle" +
	" ＡＢＣ 가가 \U0001ccd6\U00016121\n"

func repeat(u string, n int) string {
	b := make([]byte, 0, len(u)*n)
	for i := 0; i < n; i++ {
		b = append(b, u...)
	}
	return string(b)
}

var corpus = repeat(unit, 16) // ~1 KiB of mixed, decomposable UTF-8

var forms = []struct {
	name string
	form normalize.Form
}{
	{"nfc", normalize.NFC},
	{"nfd", normalize.NFD},
	{"nfkc", normalize.NFKC},
	{"nfkd", normalize.NFKD},
}

func main() {
	if len(os.Args) > 1 && os.Args[1] == "check" {
		// Emit a stable digest of each form's output so run.sh can prove the Go
		// library and MRI agree byte-for-byte before any timing is recorded.
		for _, f := range forms {
			sum := sha256.Sum256([]byte(normalize.Normalize(corpus, f.form)))
			fmt.Printf("CHECK\t%s\t%s\n", f.name, hex.EncodeToString(sum[:]))
		}
		return
	}
	for _, f := range forms {
		f := f
		bench("unicode_normalize-"+f.name, 1000, func() {
			sink = normalize.Normalize(corpus, f.form)
		})
	}
}
