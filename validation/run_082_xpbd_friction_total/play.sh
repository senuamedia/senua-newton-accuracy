#!/usr/bin/env bash
# Run 082: Senua AI's XPBD friction patch in design (patches/in_design/xpbd_friction_total_on_1.7.0.diff,
# NEWTON_XPBD_FRICTION_TOTAL=1: a contact's friction over a step bounded by mu times its normal correction summed over
# the step's iterations), on XPBD's contact suite and run 044's hold (issue 6's XPBD part), on Newton 1.7.0. The
# README's predictions were pushed before these plays. Then measured.txt, the suites' verdicts and checks.txt.
# usage: play.sh <folder holding sx_contact and sx_contact_suite.sh>   (repository root; STOCK_VENV Newton 1.7.0,
#   XFR_VENV the patch's tree first on the path)
set -u
M="$(cd "${1:?usage: play.sh <measure folder>}" && pwd)"; B=$M/sx_contact
O=validation/run_082_xpbd_friction_total; ROOT=$(pwd)
HOLD="mass=1 radius=0.05 h0=0 pushat=0.5 secs=2 solver=xpbd mu=0.5 push=2.94"
mkdir -p $O/runs $O/stats $O/suites; date -u +%FT%TZ > $O/started.txt
suite() {  # <label> <venv> <switch 0|1>
  ( . "$2/bin/activate"; unset NEWTON_XPBD_FRICTION_TOTAL; [ $3 = 1 ] && export NEWTON_XPBD_FRICTION_TOTAL=1
    bash tools/contact_suite.sh r082_$1 solver=xpbd > $O/runs/log_suite_$1.txt 2>&1 )
  rm -rf $O/suites/$1; mv suites/1/r082_$1 $O/suites/$1
  bash "$M/sx_contact_suite.sh" $O/suites/$1 $O/suites/$1/verdicts.txt > /dev/null 2>> $O/runs/log_suite_$1.txt
}
holds() {  # <label> <venv> <switch 0|1>
  ( . "$2/bin/activate"; unset NEWTON_XPBD_FRICTION_TOTAL; [ $3 = 1 ] && export NEWTON_XPBD_FRICTION_TOTAL=1
    for dt in 0.002 0.0005; do for it in 2 32; do
      python tools/nwt_contact.py $O/runs/hold_$1_it${it}_$dt.txt dt=$dt $HOLD iterations=$it > $O/stats/hold_$1_it${it}_$dt.txt 2>> $O/runs/log_$1.txt
    done; done )
}
suite stock "$STOCK_VENV" 0 & suite off "$XFR_VENV" 0 & suite on "$XFR_VENV" 1 &
holds stock "$STOCK_VENV" 0 & holds off "$XFR_VENV" 0 & holds on "$XFR_VENV" 1 &
wait; date -u +%FT%TZ > $O/finished.txt
MS=$O/measured.txt; : > $MS
for e in stock off on; do for dt in 0.002 0.0005; do for it in 2 32; do n=hold_${e}_it${it}_$dt
  echo "$n $("$B" creep $O/runs/$n.txt < /dev/null | tail -1)" >> $MS; done; done; done
v() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $MS; }
verdict() { grep "^$2 " $O/suites/$1/verdicts.txt | awk '{print $NF}'; }
C=$O/checks.txt; : > $C
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $C; }
s=0; t=0; for f in $O/suites/stock/*.txt; do b=$(basename $f); case $b in stats.txt|verdicts.txt) continue;; esac; t=$((t + 1)); cmp -s $f $O/suites/off/$b && s=$((s + 1)); done
for dt in 0.002 0.0005; do for it in 2 32; do t=$((t + 1)); cmp -s $O/runs/hold_stock_it${it}_$dt.txt $O/runs/hold_off_it${it}_$dt.txt && s=$((s + 1)); done; done
rule X0_safe_when_off eq $s $t
p6s=0; [ "$(verdict stock T06)" = PASS ] && p6s=1; p6o=0; [ "$(verdict on T06)" = PASS ] && p6o=1
rule X1_T06_fails_released eq $p6s 0
rule X1_T06_passes_patched eq $p6o 1
rule X2_hold_creeps_released all_ge 300 $(for dt in 0.002 0.0005; do for it in 2 32; do v hold_stock_it${it}_$dt mean_speed_ums; done; done)
rule X2_hold_held_patched all_in -10 10 $(for dt in 0.002 0.0005; do for it in 2 32; do v hold_on_it${it}_$dt mean_speed_ums; done; done)
kept=0; lost=0; for tt in T01 T02 T03 T04 T05 T06 T07 T08 T09 T10; do if [ "$(verdict stock $tt)" = PASS ]; then [ "$(verdict on $tt)" = PASS ] && kept=$((kept + 1)) || lost=$((lost + 1)); fi; done
rule X3_nothing_lost eq $lost 0
echo "checks: $(wc -l < $C | tr -d ' '), held: $(grep -c ': HELD$' $C)" >> $C
grep -rlIF "$HOME" $O 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
cat $C; for e in stock on; do echo "$e: $(grep '^SUITE' $O/suites/$e/verdicts.txt)"; done
