#!/usr/bin/env bash
# Run 100: the sixteenth registered study (preregistrations/PREREGISTRATION_16.md), played once on Newton 1.7.0:
# Featherstone's step as the classic Runge-Kutta scheme (issue 11's Featherstone part). Each play into runs/ and
# stats/, the suites into suites/, then the registered rules judged by sx_contact rule (rules.txt), the measured lines
# beside them (measured.txt). DRY=1 plays one throwaway play of each scene and setting (no suite), into dry/, to check
# that the runner runs to the end.
# usage: play.sh <folder holding sx_contact and sx_contact_suite.sh> <engine folder>   (repository root)
set -u
M="$(cd "${1:?usage: play.sh <measure folder> <engine folder>}" && pwd)"; B=$M/sx_contact; E="$(cd "${2:?}" && pwd)"
O=validation/run_100_study_16
FREE="mass1=1.1 mass2=0.5 radius=0.035 arm1=0.22 len1=0.45 arm2=0.2 angle1=0 angle2=0.6 omega1=1.8 omega2=-0.7 gravity=0 solver=featherstone"
SWING="mass1=0.7 mass2=0.9 radius=0.035 arm1=0.18 len1=0.4 arm2=0.22 angle1=-0.5 angle2=1.0 omega1=0 omega2=0 gravity=1 solver=featherstone"
if [ "${DRY:-0}" = 1 ]; then OUT=$O/dry; FS="0.004"; WS="0.004"; SECS=0.3; else OUT=$O; FS="0.006 0.003 0.001 0.00025"; WS="0.005 0.002 0.0005"; SECS=2; fi
plays() { local e dt; for e in stock off rk4; do for dt in $FS; do echo "f_${e}_$dt $e dt=$dt $FREE secs=$SECS"; done
  for dt in $WS; do echo "w_${e}_$dt $e dt=$dt $SWING secs=$SECS"; done; done; }
envof() { case $1 in stock) echo "$E/stock 0";; off) echo "$E/rk4 0";; rk4) echo "$E/rk4 1";; esac; }
mkdir -p $OUT/runs $OUT/stats; date -u +%FT%TZ > $OUT/started.txt
group() { local g=$1; set -- $(envof $g)
  ( . "$1/bin/activate"; unset NEWTON_FEATHERSTONE_RK4; [ $2 = 1 ] && export NEWTON_FEATHERSTONE_RK4=1
    plays | awk -v g=$g '$2 == g { $2 = ""; print }' | xargs -P 2 -L 1 bash -c 'python tools/nwt_chain.py '"$OUT"'/runs/$0.txt "$@" > '"$OUT"'/stats/$0.txt 2> '"$OUT"'/runs/log_$0.txt' ) ; }
suite() { local l=$1; set -- $(envof $l)
  ( . "$1/bin/activate"; unset NEWTON_FEATHERSTONE_RK4; [ $2 = 1 ] && export NEWTON_FEATHERSTONE_RK4=1
    bash tools/contact_suite.sh study16_$l solver=featherstone > $OUT/runs/log_suite_$l.txt 2>&1 )
  mkdir -p $OUT/suites; rm -rf $OUT/suites/$l; mv suites/1/study16_$l $OUT/suites/$l
  bash "$M/sx_contact_suite.sh" $OUT/suites/$l $OUT/suites/$l/verdicts.txt > /dev/null 2>> $OUT/runs/log_suite_$l.txt; }
for g in stock off rk4; do group $g & done
if [ "${DRY:-0}" != 1 ]; then suite stock & suite rk4 & fi
wait; date -u +%FT%TZ > $OUT/finished.txt
pick() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
MS=$OUT/measured.txt; : > $MS
for n in $(plays | awk '{print $1}'); do st=$(pick nan_at_step < $OUT/stats/$n.txt); [ -n "$st" ] || st=$(pick out_of_range_at_step < $OUT/stats/$n.txt)
  l=$("$B" chain $OUT/runs/$n.txt < /dev/null | tail -1)
  echo "$n stops ${st:--1} energy_drift_ppm $(echo "$l" | pick energy_drift_ppm_of_most_kinetic) energy_largest_drift_ppm $(echo "$l" | pick energy_largest_drift_ppm) momentum_drift_ppm $(echo "$l" | pick momentum_drift_ppm) kinetic_end_per_million $(echo "$l" | pick kinetic_end_per_million_of_start)" >> $MS; done
# the suites' gaps between successive steps for T01 (the free fall) and T08 (the refinement chain), as the suite runner
# reads them (sx_contact gap against a 10 ms base, its summed height difference)
gap() { "$B" gap 10000000 "$1" "$2" < /dev/null | tail -1 | awk '{ print $12 }'; }
if [ "${DRY:-0}" != 1 ]; then for l in stock rk4; do for s in free chain; do for k in 1 2 4 8 16 32; do
  echo "gap_${s}_${l}_1/$k gap_um $(gap $OUT/suites/$l/${s}_$k.txt $OUT/suites/$l/${s}_$((k * 2)).txt)" >> $MS; done; done; done; fi
[ "${DRY:-0}" = 1 ] && { echo "dry run: $(wc -l < $MS | tr -d ' ') measured lines"; cat $MS; exit 0; }
v() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $MS; }
verdict() { grep "^$2 " $OUT/suites/$1/verdicts.txt | awk '{print $NF}'; }
abs() { for x in "$@"; do echo "${x#-}"; done; }
R=$OUT/rules.txt; : > $R
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $R; }
s=0; t=0; for n in $(plays | awk '$2 == "stock" { print $1 }'); do t=$((t + 1)); cmp -s $OUT/runs/$n.txt $OUT/runs/${n/_stock_/_off_}.txt && s=$((s + 1)); done
rule R1_safe_when_off eq $s $t
rule R2_fault_there all_ge 100 $(abs $(for dt in $FS; do v f_stock_$dt energy_largest_drift_ppm; done))
rule R3_free_energy all_le 20 $(abs $(for dt in $FS; do v f_rk4_$dt energy_largest_drift_ppm; done))
rule R3_free_momentum all_le 20 $(abs $(for dt in $FS; do v f_rk4_$dt momentum_drift_ppm; done))
rule R4_swing_kept all_le 100 $(abs $(v w_rk4_0.002 energy_largest_drift_ppm) $(v w_rk4_0.0005 energy_largest_drift_ppm))
rule R4_swing_kept_5ms le $(abs $(v w_rk4_0.005 energy_largest_drift_ppm)) 1000
rule R5_numbers all_eq -1 $(plays | awk '$2 == "rk4" { print $1 }' | while read -r n; do v $n stops; done)
lost=0; for tt in T02 T03 T04 T05 T06 T07 T09 T10; do [ "$(verdict stock $tt)" = PASS ] && [ "$(verdict rk4 $tt)" != PASS ] && lost=$((lost + 1)); done
rule R6_nothing_lost eq $lost 0
rule R7_no_worse all_ge 0 $(for s in free chain; do for k in 1 2 4 8 16 32; do echo $(( $(v gap_${s}_stock_1/$k gap_um) - $(v gap_${s}_rk4_1/$k gap_um) )); done; done)
grep -rlIF "$HOME" $OUT 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
echo "rules: $(wc -l < $R | tr -d ' '), held: $(grep -c ': HELD$' $R)" >> $R
cat $R; for l in stock rk4; do echo "$l: $(grep '^SUITE' $OUT/suites/$l/verdicts.txt)"; done
