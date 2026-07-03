#!/usr/bin/env bash
#
# Copyright (c) the go-ruby-* authors
# SPDX-License-Identifier: BSD-3-Clause
#
# Library-level cross-runtime benchmark runner.
#
# Runs the SAME workload through (a) the pure-Go go-ruby library (benchmarks/go)
# and (b) each available reference Ruby runtime (benchmarks/ruby/<mod>.rb), then
# prints one Markdown table per sub-benchmark: ns/op and the ratio vs MRI.
#
# Before timing, it PROVES correctness: the Go library and MRI each emit a
# SHA-256 digest of every normalization form's output (`<driver> check`); the run
# aborts unless they are byte-for-byte identical. No numbers are produced from an
# implementation that does not match the MRI oracle.
#
# Usage:  bash benchmarks/run.sh
# Env:    OUTER (timed passes, default 25), WARM (untimed passes, default 3),
#         RUBY / JRUBY / TRUFFLERUBY (override runtime binaries).
set -u
cd "$(dirname "$0")"

RUBY=${RUBY:-ruby}
JRUBY=${JRUBY:-jruby}
TRUFFLERUBY=${TRUFFLERUBY:-truffleruby}

RB=$(ls ruby/*.rb | grep -v _harness | head -1)
MOD=$(basename "$RB" .rb)
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

# --- Correctness gate: Go library output must equal MRI, byte-for-byte --------
echo "== verifying go-ruby-$MOD output == MRI (per form) ==" >&2
GO_CHECK=$( cd go && GOWORK=off go run . check 2>/dev/null | grep '^CHECK' | sort )
MRI_CHECK=$( "$RUBY" "$RB" check 2>/dev/null | grep '^CHECK' | sort )
if [ -z "$GO_CHECK" ] || [ -z "$MRI_CHECK" ]; then
  echo "  ERROR: could not obtain check digests (need go and $RUBY)." >&2
  exit 1
fi
if [ "$GO_CHECK" != "$MRI_CHECK" ]; then
  echo "  ERROR: Go library output differs from MRI — refusing to benchmark." >&2
  echo "  --- go ---"  >&2; echo "$GO_CHECK"  >&2
  echo "  --- mri ---" >&2; echo "$MRI_CHECK" >&2
  exit 1
fi
echo "$GO_CHECK" | sed 's/^/  ok /' >&2

run() { # <runtime-label> <cmd...>
  local label=$1; shift
  command -v "$1" >/dev/null 2>&1 || { echo "  ($label: $1 not found — skipped)" >&2; return; }
  echo "  $label ..." >&2
  "$@" 2>/dev/null | awk -v r="$label" '$1=="RESULT"{printf "%s\t%s\t%s\n", r, $2, $3}' >> "$TMP"
}

echo "== go-ruby-$MOD library-level benchmark ==" >&2
echo "  go ..." >&2
( cd go && command -v go >/dev/null 2>&1 && GOWORK=off go run . 2>/dev/null ) \
  | awk '$1=="RESULT"{printf "go\t%s\t%s\n", $2, $3}' >> "$TMP"
run "mri"         "$RUBY"                "$RB"
run "mri-yjit"    "$RUBY" --yjit        "$RB"
run "jruby"       "$JRUBY"              "$RB"
run "truffleruby" "$TRUFFLERUBY"        "$RB"

echo >&2
# Emit one Markdown table per sub-benchmark (label), runtimes as rows.
awk -F'\t' '
  { key=$2; rt=$1; ns=$3; labels[key]=1; val[rt SUBSEP key]=ns; rts[rt]=1 }
  END {
    order="go mri mri-yjit jruby truffleruby"
    n=split(order, ord, " ")
    ln=0; for (k in labels) lab[++ln]=k
    for (i=1;i<=ln;i++) for (j=i+1;j<=ln;j++) if (lab[j]<lab[i]){t=lab[i];lab[i]=lab[j];lab[j]=t}
    for (i=1;i<=ln;i++){
      k=lab[i]
      printf "\n#### %s\n\n", k
      print  "| Runtime | ns/op | vs MRI |"
      print  "| --- | ---: | ---: |"
      base=val["mri" SUBSEP k]
      for (o=1;o<=n;o++){
        rt=ord[o]; v=val[rt SUBSEP k]
        if (v=="") continue
        ratio=(base!=""&&base+0>0)? sprintf("%.2f×", v/base) : "—"
        name=rt
        if (rt=="go") name="**go-ruby (pure Go)**"
        else if (rt=="mri") name="MRI"
        else if (rt=="mri-yjit") name="MRI + YJIT"
        else if (rt=="jruby") name="JRuby"
        else if (rt=="truffleruby") name="TruffleRuby"
        printf "| %s | %s | %s |\n", name, v, ratio
      }
    }
  }
' "$TMP"
