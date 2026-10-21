#!/usr/bin/env bash
# The audit's number trace, second pass (docs/audit.md): of the numbers trace_numbers.sh finds NOWHERE or ELSEWHERE,
# those that are a unit change of a number in a run their line cites: a whole number of that run's files lies within
# half a unit of the number's last decimal once divided by 10^3, 10^6 or 10^9 (um to mm, urad/s to rad/s, and so on).
# Plumbing only. usage: trace_conversions.sh   (from the repository root, after trace_numbers.sh; writes
# validation/audit/trace_conversions.txt: CONVERSION or BY HAND, the page line, the number, and the run's number)
set -u
A=validation/audit; IN=$A/trace_numbers.txt; OUT=$A/trace_conversions.txt; T=$(mktemp -d)
grep -E '^(NOWHERE|ELSEWHERE)' "$IN" > "$T/left"
cut -f4 "$T/left" | tr -d '[]' | sed 's/runs//' | tr ' ' '\n' | grep -E '^[0-9]{3}$' | sort -u > "$T/runs"
for r in $(cat "$T/runs"); do
  for d in validation/run_${r}_*; do
    find "$d" -type f ! -name README.md ! -name '*.gz' -print0 | xargs -0 grep -IhoE -- '[0-9]{3,}' 2>/dev/null | sort -u | sed "s/^/$r\t/"
  done
done > "$T/ints"
awk -F'\t' -v I="$T/ints" '
  BEGIN { while ((getline l < I) > 0) { split(l, a, "\t"); n[a[1]]++; v[a[1], n[a[1]]] = a[2] + 0 } }
  { x = $3; hit = ""; m = split($4, rr, " ")
    if (x !~ /[eE]/ && index(x, ".")) { d = length(x) - index(x, "."); h = 0.5 / (10 ^ d)
      for (i = 1; i <= m && hit == ""; i++) { r = rr[i]; gsub(/[^0-9]/, "", r)
        for (k = 3; k <= 9 && hit == ""; k += 3) { lo = (x - h) * (10 ^ k); hi = (x + h) * (10 ^ k)
          for (j = 1; j <= n[r] && hit == ""; j++) if (v[r, j] >= lo && v[r, j] < hi) hit = v[r, j] " / 10^" k " in run " r } } }
    if (hit != "") print "CONVERSION\t" $2 "\t" x "\t" hit; else print "BY HAND\t" $2 "\t" x "\t" $4 }' "$T/left" > "$OUT"
rm -rf "$T"
echo "CONVERSION $(grep -c '^CONVERSION' "$OUT"), BY HAND $(grep -c '^BY HAND' "$OUT")"
