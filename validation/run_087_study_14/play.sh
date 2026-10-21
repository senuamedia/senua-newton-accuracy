#!/usr/bin/env bash
# Run 087: the fourteenth registered study (preregistrations/PREREGISTRATION_14.md), played once on Newton 1.7.0:
# SemiImplicit's joint limit on two heavy arms with its joint attachment stiff enough to be a joint (issue 16). Each play
# into runs/ and stats/, then the registered rules judged by sx_contact rule (rules.txt), the measured lines beside them.
# DRY=1 plays one throwaway play of each arm into dry/, to check that the runner runs to the end; no rule is read.
# usage: play.sh <sx_contact binary>   (repository root; STOCK_VENV Newton 1.7.0, LIMIT_VENV the Featherstone limit patch's tree)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary>}")" && pwd)/$(basename "$1")"
O=validation/run_087_study_14
if [ "${DRY:-0}" = 1 ]; then OUT=$O/dry; ST="0.0005"; SECS=0.6; else OUT=$O; ST="0.0001 0.000025"; SECS=2; fi
A4="mass=4 radius=0.18 arm=0.45 lo=-1 hi=1"; A15="mass=1.5 radius=0.12 arm=0.35 lo=-0.9 hi=0.9"
plays() { local e a dt; for e in stiff default fs fs1; do for a in A4 A15; do for dt in $ST; do
  [ $a = A4 ] && g="$A4" || g="$A15"
  case $e in stiff) o="solver=semi opt.joint_attach_ke=1000000";; default) o="solver=semi";; *) o="solver=featherstone";; esac
  echo "strike_${e}_${a}_$dt $e dt=$dt $g secs=$SECS gravity=1 $o"; done; done; done; }
mkdir -p $OUT/runs $OUT/stats; date -u +%FT%TZ > $OUT/started.txt
for g in stiff default fs fs1; do
  ( v=$STOCK_VENV; [ $g = fs1 ] && v=$LIMIT_VENV; . "$v/bin/activate"; unset NEWTON_FEATHERSTONE_LIMIT; [ $g = fs1 ] && export NEWTON_FEATHERSTONE_LIMIT=1
    plays | awk -v g=$g '$2 == g { $2 = ""; print }' | xargs -P 2 -L 1 bash -c 'python tools/nwt_joint.py '"$OUT"'/runs/$0.txt "$@" > '"$OUT"'/stats/$0.txt 2> '"$OUT"'/runs/log_$0.txt' ) &
done
wait; date -u +%FT%TZ > $OUT/finished.txt
pick_s() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
back() { "$B" swing $1 < /dev/null | tail -1 | awk '{ n = 0; for (i = 1; i < NF; i++) if ($i == "turn_urad") { n++; if (n == 2) { print $(i + 1); exit } } } END { if (n < 2) print "none" }'; }
M=$OUT/measured.txt; : > $M
for n in $(plays | awk '{print $1}'); do st=$(pick_s nan_at_step < $OUT/stats/$n.txt); [ -n "$st" ] || st=$(pick_s out_of_range_at_step < $OUT/stats/$n.txt)
  echo "$n stops ${st:--1} back_urad $(back $OUT/runs/$n.txt)" >> $M; done
[ "${DRY:-0}" = 1 ] && { echo "dry run: $(wc -l < $M | tr -d ' ') measured lines"; cat $M; exit 0; }
v() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $M; }
R=$OUT/rules.txt; : > $R
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $R; }
rule R1_numbers all_eq -1 $(for a in A4 A15; do for dt in $ST; do v strike_stiff_${a}_$dt stops; done; done)
rule R2_strike_A4 all_in -253220 -213220 $(for dt in $ST; do v strike_stiff_A4_$dt back_urad; done)
rule R2_strike_A15 all_in -407852 -367852 $(for dt in $ST; do v strike_stiff_A15_$dt back_urad; done)
grep -rlIF "$HOME" $OUT 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
echo "rules: $(wc -l < $R | tr -d ' '), held: $(grep -c ': HELD$' $R)" >> $R
cat $R
