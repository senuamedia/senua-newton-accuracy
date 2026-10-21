#!/usr/bin/env bash
# Run 088: the fifteenth registered study (preregistrations/PREREGISTRATION_15.md), played once on Newton 1.7.0: XPBD
# holds a load at rest (issue 6's XPBD part). Each play into runs/ and stats/, the suites into suites/, then the
# registered rules judged by sx_contact rule (rules.txt), the measured lines beside them (measured.txt).
# DRY=1 plays one throwaway play of each scene (no suite), into dry/, to check that the runner runs to the end.
# usage: play.sh <folder holding sx_contact and sx_contact_suite.sh> <engine folder>   (repository root)
set -u
M="$(cd "${1:?usage: play.sh <measure folder> <engine folder>}" && pwd)"; B=$M/sx_contact; E="$(cd "${2:?}" && pwd)"
O=validation/run_088_study_15
CUBE="mass=2 radius=0.06 h0=0 mu=0.6 solver=xpbd"
if [ "${DRY:-0}" = 1 ]; then OUT=$O/dry; ST="0.004"; IT=4; HS=0.8; else OUT=$O; ST="0.003 0.00075"; IT=64; HS=1.8; fi
plays() { local e dt; for dt in $ST; do
  for e in stock floor both off; do echo "h_${e}_$dt $e dt=$dt $CUBE push=8.232 pushat=0.4 secs=$HS iterations=$IT"; done
  for e in stock both; do echo "s_${e}_$dt $e dt=$dt $CUBE vx0=0.8 secs=1 iterations=$IT"; done; done; }
envof() { case $1 in stock) echo "$E/stock 0 0";; floor) echo "$E/floor 1 0";; both) echo "$E/both 1 1";; off) echo "$E/both 0 0";; esac; }
mkdir -p $OUT/runs $OUT/stats; date -u +%FT%TZ > $OUT/started.txt
group() { local g=$1; set -- $(envof $g)
  ( . "$1/bin/activate"; unset NEWTON_XPBD_NO_SPEED_FLOOR NEWTON_XPBD_FRICTION_TOTAL
    [ $2 = 1 ] && export NEWTON_XPBD_NO_SPEED_FLOOR=1; [ $3 = 1 ] && export NEWTON_XPBD_FRICTION_TOTAL=1
    plays | awk -v g=$g '$2 == g { $2 = ""; print }' | xargs -P 2 -L 1 bash -c 'python tools/nwt_contact.py '"$OUT"'/runs/$0.txt "$@" > '"$OUT"'/stats/$0.txt 2> '"$OUT"'/runs/log_$0.txt' ) ; }
suite() { local l=$1; set -- $(envof $l)
  ( . "$1/bin/activate"; unset NEWTON_XPBD_NO_SPEED_FLOOR NEWTON_XPBD_FRICTION_TOTAL
    [ $2 = 1 ] && export NEWTON_XPBD_NO_SPEED_FLOOR=1; [ $3 = 1 ] && export NEWTON_XPBD_FRICTION_TOTAL=1
    bash tools/contact_suite.sh study15_$l solver=xpbd > $OUT/runs/log_suite_$l.txt 2>&1 )
  mkdir -p $OUT/suites; rm -rf $OUT/suites/$l; mv suites/1/study15_$l $OUT/suites/$l
  bash "$M/sx_contact_suite.sh" $OUT/suites/$l $OUT/suites/$l/verdicts.txt > /dev/null 2>> $OUT/runs/log_suite_$l.txt; }
for g in stock floor both off; do group $g & done
if [ "${DRY:-0}" != 1 ]; then suite stock & suite both & fi
wait; date -u +%FT%TZ > $OUT/finished.txt
MS=$OUT/measured.txt; : > $MS
for n in $(plays | awk '{print $1}'); do case $n in h_*) r=creep;; s_*) r=stop;; esac
  echo "$n $("$B" $r $OUT/runs/$n.txt < /dev/null | tail -1)" >> $MS; done
[ "${DRY:-0}" = 1 ] && { echo "dry run: $(wc -l < $MS | tr -d ' ') measured lines"; cat $MS; exit 0; }
v() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $MS; }
R=$OUT/rules.txt; : > $R
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $R; }
s=0; for dt in $ST; do cmp -s $OUT/runs/h_stock_$dt.txt $OUT/runs/h_off_$dt.txt && s=$((s + 1)); done
rule R1_safe_when_off eq $s 2
rule R2_fault_there all_ge 100 $(for dt in $ST; do v h_stock_$dt mean_speed_ums; v h_floor_$dt mean_speed_ums; done)
rule R3_held all_in -10 10 $(for dt in $ST; do v h_both_$dt mean_speed_ums; done)
for dt in $ST; do rule R4_slide_kept_$dt within $(v s_both_$dt slid_um) $(v s_stock_$dt slid_um) 100; done
lost=0; for tt in T01 T02 T03 T04 T05 T06 T07 T08 T09 T10; do a=$(grep "^$tt " $OUT/suites/stock/verdicts.txt | awk '{print $NF}'); b=$(grep "^$tt " $OUT/suites/both/verdicts.txt | awk '{print $NF}'); [ "$a" = PASS ] && [ "$b" != PASS ] && lost=$((lost + 1)); done
rule R5_nothing_lost eq $lost 0
grep -rlIF "$HOME" $OUT 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
echo "rules: $(wc -l < $R | tr -d ' '), held: $(grep -c ': HELD$' $R)" >> $R
cat $R
