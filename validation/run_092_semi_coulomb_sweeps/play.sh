#!/usr/bin/env bash
# Run 092: Senua AI's SemiImplicit Coulomb friction patch in design, second form
# (patches/in_design/semi_coulomb_friction_v2_on_1.7.0.diff: NEWTON_SEMI_COULOMB_FRICTION=1 with
# NEWTON_SEMI_COULOMB_FRICTION_ITERATIONS=K, the friction pass made K times a step, each contact's friction over the
# step kept within Coulomb's cone on its total), on run 090's hold, slide and the contact suite (issues 6 and 9), on
# Newton 1.7.0. The README's predictions were pushed before these plays. Then measured.txt and checks.txt.
# usage: play.sh <folder holding sx_contact and sx_contact_suite.sh>   (repository root; STOCK_VENV Newton 1.7.0,
#   COUL_VENV the patch's tree first on the path)
set -u
M="$(cd "${1:?usage: play.sh <measure folder>}" && pwd)"; B=$M/sx_contact; O=validation/run_092_semi_coulomb_sweeps
HOLD="mass=1 radius=0.05 h0=0 mu=0.5 push=2.94 pushat=0.5 secs=2 solver=semi"
SLIDE="mass=1 radius=0.05 h0=0 mu=0.5 vx0=1 secs=0.5 solver=semi"
KS="1 4 16 64"; DTS="0.002 0.0005 0.000125"
mkdir -p $O/runs $O/stats $O/suites; date -u +%FT%TZ > $O/started.txt
plays() { local e dt; for e in stock $(for k in $KS; do echo k$k; done); do for dt in $DTS; do
  echo "hold_${e}_$dt $e dt=$dt $HOLD"; echo "slide_${e}_$dt $e dt=$dt $SLIDE"; done; done; }
for g in stock $(for k in $KS; do echo k$k; done); do
  ( v=$COUL_VENV; [ $g = stock ] && v=$STOCK_VENV; . "$v/bin/activate"; unset NEWTON_SEMI_COULOMB_FRICTION NEWTON_SEMI_COULOMB_FRICTION_ITERATIONS
    [ $g = stock ] || { export NEWTON_SEMI_COULOMB_FRICTION=1; export NEWTON_SEMI_COULOMB_FRICTION_ITERATIONS=${g#k}; }
    plays | awk -v g=$g '$2 == g { $2 = ""; print }' | xargs -P 1 -L 1 bash -c 'python tools/nwt_contact.py '"$O"'/runs/$0.txt "$@" > '"$O"'/stats/$0.txt 2> '"$O"'/runs/log_$0.txt' ) &
done
for l in stock k16 k64; do
  ( v=$COUL_VENV; [ $l = stock ] && v=$STOCK_VENV; . "$v/bin/activate"; unset NEWTON_SEMI_COULOMB_FRICTION NEWTON_SEMI_COULOMB_FRICTION_ITERATIONS
    [ $l = stock ] || { export NEWTON_SEMI_COULOMB_FRICTION=1; export NEWTON_SEMI_COULOMB_FRICTION_ITERATIONS=${l#k}; }
    bash tools/contact_suite.sh r092_$l solver=semi > $O/runs/log_suite_$l.txt 2>&1; rm -rf $O/suites/$l; mv suites/1/r092_$l $O/suites/$l
    bash "$M/sx_contact_suite.sh" $O/suites/$l $O/suites/$l/verdicts.txt > /dev/null 2>> $O/runs/log_suite_$l.txt ) &
done
wait; date -u +%FT%TZ > $O/finished.txt
pick_s() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
MS=$O/measured.txt; : > $MS
for n in $(plays | awk '{print $1}'); do st=$(pick_s nan_at_step < $O/stats/$n.txt); [ -n "$st" ] || st=$(pick_s out_of_range_at_step < $O/stats/$n.txt)
  case $n in hold_*) r=creep;; slide_*) r=stop;; esac; echo "$n stops ${st:--1} $("$B" $r $O/runs/$n.txt < /dev/null | tail -1)" >> $MS; done
v() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $MS; }
verdict() { grep "^$2 " $O/suites/$1/verdicts.txt | awk '{print $NF}'; }
C=$O/checks.txt; : > $C
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $C; }
rule C0_numbers all_eq -1 $(for k in $KS; do for dt in $DTS; do v hold_k${k}_$dt stops; v slide_k${k}_$dt stops; done; done)
s=0; for dt in $DTS; do for p in hold slide; do cmp -s $O/runs/${p}_k1_$dt.txt validation/run_090_semi_coulomb_friction/runs/${p}_on_$dt.txt && s=$((s + 1)); done; done
rule C0_k1_is_run_090 eq $s 6
rule C1_hold_held_k64 all_in -10 10 $(for dt in $DTS; do v hold_k64_$dt mean_speed_ums; done)
rule C2_slide_coulomb_k64 all_within 102041 100 $(for dt in $DTS; do v slide_k64_$dt slid_um; done)
p6=0; [ "$(verdict k64 T06)" = PASS ] && p6=1; rule C3_T06_passes_k64 eq $p6 1
lost=0; for tt in T01 T02 T03 T04 T05 T06 T07 T08 T09 T10; do [ "$(verdict stock $tt)" = PASS ] && [ "$(verdict k64 $tt)" != PASS ] && lost=$((lost + 1)); done
rule C3_nothing_lost_k64 eq $lost 0
echo "checks: $(wc -l < $C | tr -d ' '), held: $(grep -c ': HELD$' $C)" >> $C
grep -rlIF "$HOME" $O 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
cat $C; for l in stock k16 k64; do echo "$l: $(grep '^SUITE' $O/suites/$l/verdicts.txt)"; done
