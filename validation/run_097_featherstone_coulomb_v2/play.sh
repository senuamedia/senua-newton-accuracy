#!/usr/bin/env bash
# Run 097: Senua AI's Featherstone Coulomb friction patch in design, second form
# (patches/in_design/featherstone_coulomb_friction_v2_on_semi_coulomb_v3.diff, on the same patches as the first: a free
# root's change of speeds kept the change of its centre's speed about where its centre is when applied), alone and on
# the contact damping patch, on run 094's hold, slide and the contact suite on Featherstone (issues 6 and 9). The
# README's predictions were pushed before these plays. Then measured.txt and checks.txt.
# usage: play.sh <folder holding sx_contact and sx_contact_suite.sh>   (repository root; COUL_VENV the patch's tree first
#   on the path; the release's and the damping patch's plays and suites are run 094's)
set -u
M="$(cd "${1:?usage: play.sh <measure folder>}" && pwd)"; B=$M/sx_contact; O=validation/run_097_featherstone_coulomb_v2
P=validation/run_094_featherstone_coulomb
HOLD="mass=1 radius=0.05 h0=0 mu=0.5 push=2.94 pushat=0.5 secs=2 solver=featherstone"
SLIDE="mass=1 radius=0.05 h0=0 mu=0.5 vx0=1 secs=0.5 solver=featherstone"
DTS="0.002 0.0005 0.000125"; ARMS="off f64 df16 df64"
mkdir -p $O/runs $O/stats $O/suites; date -u +%FT%TZ > $O/started.txt
setenv() { unset NEWTON_FEATHERSTONE_COULOMB_FRICTION NEWTON_CONTACT_DAMPING_NO_PULL NEWTON_SEMI_COULOMB_FRICTION
  case $1 in f*) export NEWTON_FEATHERSTONE_COULOMB_FRICTION=${1#f};;
    df*) export NEWTON_CONTACT_DAMPING_NO_PULL=1 NEWTON_FEATHERSTONE_COULOMB_FRICTION=${1#df};; esac; }
plays() { local e dt; for e in $ARMS; do for dt in $DTS; do
  echo "hold_${e}_$dt $e dt=$dt $HOLD"; echo "slide_${e}_$dt $e dt=$dt $SLIDE"; done; done; }
for g in $ARMS; do
  ( . "$COUL_VENV/bin/activate"; setenv $g
    plays | awk -v g=$g '$2 == g { $2 = ""; print }' | xargs -P 1 -L 1 bash -c 'python tools/nwt_contact.py '"$O"'/runs/$0.txt "$@" > '"$O"'/stats/$0.txt 2> '"$O"'/runs/log_$0.txt' ) &
done
for l in df16 df64; do
  ( . "$COUL_VENV/bin/activate"; setenv $l
    bash tools/contact_suite.sh r097_$l solver=featherstone > $O/runs/log_suite_$l.txt 2>&1; rm -rf $O/suites/$l; mv suites/1/r097_$l $O/suites/$l
    bash "$M/sx_contact_suite.sh" $O/suites/$l $O/suites/$l/verdicts.txt > /dev/null 2>> $O/runs/log_suite_$l.txt ) &
done
wait; date -u +%FT%TZ > $O/finished.txt
pick_s() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
MS=$O/measured.txt; : > $MS
for n in $(plays | awk '{print $1}'); do st=$(pick_s nan_at_step < $O/stats/$n.txt); [ -n "$st" ] || st=$(pick_s out_of_range_at_step < $O/stats/$n.txt)
  case $n in hold_*) r=creep;; slide_*) r=stop;; esac; echo "$n stops ${st:--1} $("$B" $r $O/runs/$n.txt < /dev/null | tail -1)" >> $MS; done
v() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $MS; }
vfile() { [ $1 = df16 ] || [ $1 = df64 ] && echo $O/suites/$1/verdicts.txt || echo $P/suites/$1/verdicts.txt; }
verdict() { grep "^$2 " $(vfile $1) | awk '{print $NF}'; }
# a suite line's readings: the numbers after its last "): ", up to " ;" or " :"
nums() { grep "^$2 " $(vfile $1) | awk '{ s = $0; while ((i = index(s, "): ")) > 0) s = substr(s, i + 3); sub(/ [;:].*$/, "", s); print s }'; }
C=$O/checks.txt; : > $C
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $C; }
s=0; for dt in $DTS; do for p in hold slide; do cmp -s $O/runs/${p}_off_$dt.txt $P/runs/${p}_stock_$dt.txt && s=$((s + 1)); done; done
rule C0_safe_when_off eq $s 6
rule C0_numbers all_eq -1 $(for e in f64 df16 df64; do for dt in $DTS; do v hold_${e}_$dt stops; v slide_${e}_$dt stops; done; done)
rule C1_hold_held_f64 all_in -10 10 $(for dt in $DTS; do v hold_f64_$dt mean_speed_ums; done)
rule C1_hold_held_df64 all_in -10 10 $(for dt in $DTS; do v hold_df64_$dt mean_speed_ums; done)
rule C2_slide_coulomb_df64 all_within 102041 100 $(for dt in $DTS; do v slide_df64_$dt slid_um; done)
rule C3_T05_coulomb_at_impact_df64 all_within 4000 100 $(nums df64 T05 | cut -d' ' -f2-)
rule C3_T10_friction_over_impact_df64 all_within 4000 100 $(nums df64 T10 | cut -d' ' -f2-)
rule C3_T06_at_1_16_df64 in $(nums df64 T06 | cut -d' ' -f2) -10 10
for base in stock damp; do lost=0; for tt in T01 T02 T03 T04 T05 T06 T07 T08 T09 T10; do [ "$(verdict $base $tt)" = PASS ] && [ "$(verdict df64 $tt)" != PASS ] && lost=$((lost + 1)); done
  rule C3_nothing_lost_df64_against_$base eq $lost 0; done
echo "checks: $(wc -l < $C | tr -d ' '), held: $(grep -c ': HELD$' $C)" >> $C
grep -rlIF "$HOME" $O 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
cat $C; for l in df16 df64; do echo "$l: $(grep '^SUITE' $O/suites/$l/verdicts.txt)"; done
