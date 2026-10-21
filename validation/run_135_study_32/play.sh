#!/usr/bin/env bash
# Run 135: the thirty-second registered study (preregistrations/PREREGISTRATION_32.md), played once on Newton 1.7.0: the
# implicit MPM solver's thin colliders kept whole by a margin of half a voxel, Newton's own configuration (issue 21,
# #4712's leak). Each play into runs/, its error stream into runs/err_<play>.txt and its statistics into stats/, then
# the registered rules judged by sx_contact rule (rules.txt), the measured lines beside them (measured.txt). DRY=1 plays
# each setting for 1/24 s, into dry/, to check that the runner runs to the end.
# usage: STOCK_VENV=<Newton 1.7.0 venv> play.sh <sx_contact binary> [parallel plays]   (repository root)
set -u
B="$(cd "$(dirname "${1:?usage: STOCK_VENV=<venv> play.sh <sx_contact binary> [parallel plays]}")" && pwd)/$(basename "$1")"; P=${2:-4}
O=validation/run_135_study_32
if [ "${DRY:-0}" = 1 ]; then OUT=$O/dry; SECS=0.0417; else OUT=$O; SECS=1; fi
plays() { local v n m; for v in 0.007 0.014; do for n in 12 24; do for m in none half quarter; do
  case $m in none) g=0;; quarter) g=$(awk -v v=$v 'BEGIN { print v / 4 }');; half) g=$(awk -v v=$v 'BEGIN { print v / 2 }');; esac
  echo "cup_v${v#0.}_s${n}_$m scene=cup voxel=$v substeps=$n margin=$g secs=$SECS"; done; done; done; }
mkdir -p $OUT/runs $OUT/stats; date -u +%FT%TZ > $OUT/started.txt
( . "${STOCK_VENV:?}/bin/activate"
  plays | xargs -P $P -L 1 bash -c 'python tools/nwt_mpm_collider.py '"$OUT"'/runs/$0.txt "$@" > '"$OUT"'/stats/$0.txt 2> '"$OUT"'/runs/err_$0.txt' )
date -u +%FT%TZ > $OUT/finished.txt
grep -rlIF "$HOME" $OUT 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
pick() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
M=$OUT/measured.txt; : > $M
# the cup's file: <step> <particles outside the walls> 0 0 0 0; `final` names its first column angle_urad
for n in $(plays | awk '{ print $1 }'); do st=$(pick nan_at_step < $OUT/stats/$n.txt)
  echo "$n stops ${st:--1} $("$B" final $OUT/runs/$n.txt < /dev/null | tail -1)" >> $M; done
[ "${DRY:-0}" = 1 ] && { echo "dry run: $(wc -l < $M | tr -d ' ') measured lines"; cat $M; exit 0; }
v() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $M; }
out() { plays | awk -v m="$1" '$1 ~ ("_" m "$") { print $1 }' | while read -r n; do v $n angle_urad; done; }
R=$OUT/rules.txt; : > $R
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $R; }
rule R1_released_leaks all_ge 1 $(out none)
rule R2_half_voxel_kept all_eq 0 $(out half)
rule R3_numbers all_eq -1 $(plays | awk '{ print $1 }' | while read -r n; do v $n stops; done)
echo "rules: $(wc -l < $R | tr -d ' '), held: $(grep -c ': HELD$' $R)" >> $R
cat $R $M
