#!/usr/bin/env bash
# Run 096: Senua AI's Featherstone RK4 patch in design (patches/in_design/featherstone_rk4_on_1.7.0.diff,
# NEWTON_FEATHERSTONE_RK4=1: the step in four stages as MuJoCo's own RK4, each stage's accelerations the stock step's),
# on Study 9's free chain and a swinging chain (issue 11) and the contact suite, on Newton 1.7.0. The README's
# predictions were pushed before these plays. Then measured.txt and checks.txt.
# usage: play.sh <folder holding sx_contact and sx_contact_suite.sh>   (repository root; STOCK_VENV Newton 1.7.0,
#   RK4_VENV the patch's tree first on the path)
set -u
M="$(cd "${1:?usage: play.sh <measure folder>}" && pwd)"; B=$M/sx_contact; O=validation/run_096_featherstone_rk4
FREE="mass1=0.7 mass2=1.3 radius=0.04 arm1=0.25 len1=0.5 arm2=0.22 angle1=0 angle2=-0.4 omega1=2.2 omega2=-1.1 secs=2 gravity=0"
SWING="mass1=0.9 mass2=0.6 radius=0.04 arm1=0.2 len1=0.45 arm2=0.25 angle1=0.3 angle2=0.8 omega1=0 omega2=0 secs=2 gravity=1"
FS="0.01 0.008 0.002 0.0005 0.000125"; SS="0.01 0.0025 0.0005"
mkdir -p $O/runs $O/stats $O/suites; date -u +%FT%TZ > $O/started.txt
plays() { local e dt; for e in stock off rk4; do for dt in $FS; do echo "free_${e}_$dt $e dt=$dt $FREE solver=featherstone opt.angular_damping=0"; done
  for dt in $SS; do echo "swing_${e}_$dt $e dt=$dt $SWING solver=featherstone opt.angular_damping=0"; done
  echo "free_${e}_damped_0.002 $e dt=0.002 $FREE solver=featherstone"; done; }
for g in stock off rk4; do
  ( v=$RK4_VENV; [ $g = stock ] && v=$STOCK_VENV; . "$v/bin/activate"; unset NEWTON_FEATHERSTONE_RK4; [ $g = rk4 ] && export NEWTON_FEATHERSTONE_RK4=1
    plays | awk -v g=$g '$2 == g { $2 = ""; print }' | xargs -P 1 -L 1 bash -c 'python tools/nwt_chain.py '"$O"'/runs/$0.txt "$@" > '"$O"'/stats/$0.txt 2> '"$O"'/runs/log_$0.txt' ) &
done
for l in stock rk4; do
  ( v=$RK4_VENV; [ $l = stock ] && v=$STOCK_VENV; . "$v/bin/activate"; unset NEWTON_FEATHERSTONE_RK4; [ $l = rk4 ] && export NEWTON_FEATHERSTONE_RK4=1
    bash tools/contact_suite.sh r096_$l solver=featherstone > $O/runs/log_suite_$l.txt 2>&1; rm -rf $O/suites/$l; mv suites/1/r096_$l $O/suites/$l
    bash "$M/sx_contact_suite.sh" $O/suites/$l $O/suites/$l/verdicts.txt > /dev/null 2>> $O/runs/log_suite_$l.txt ) &
done
wait; date -u +%FT%TZ > $O/finished.txt
pick() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
MS=$O/measured.txt; : > $MS
for n in $(plays | awk '{print $1}'); do st=$(pick nan_at_step < $O/stats/$n.txt); [ -n "$st" ] || st=$(pick out_of_range_at_step < $O/stats/$n.txt)
  l=$("$B" chain $O/runs/$n.txt < /dev/null | tail -1)
  echo "$n stops ${st:--1} energy_drift_ppm $(echo "$l" | pick energy_drift_ppm_of_most_kinetic) energy_largest_drift_ppm $(echo "$l" | pick energy_largest_drift_ppm) momentum_drift_ppm $(echo "$l" | pick momentum_drift_ppm) kinetic_end_per_million $(echo "$l" | pick kinetic_end_per_million_of_start)" >> $MS; done
v() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $MS; }
verdict() { grep "^$2 " $O/suites/$1/verdicts.txt | awk '{print $NF}'; }
abs() { for x in "$@"; do echo "${x#-}"; done; }
C=$O/checks.txt; : > $C
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $C; }
s=0; t=0; for n in $(plays | awk '$2 == "stock" { print $1 }'); do t=$((t + 1)); cmp -s $O/runs/$n.txt $O/runs/${n/_stock_/_off_}.txt && s=$((s + 1)); done
rule C0_safe_when_off eq $s $t
rule C0_numbers all_eq -1 $(plays | awk '$2 == "rk4" { print $1 }' | while read -r n; do v $n stops; done)
rule C1_free_energy all_le 5 $(abs $(for dt in $FS; do v free_rk4_$dt energy_largest_drift_ppm; done))
rule C1_free_momentum all_le 5 $(abs $(for dt in $FS; do v free_rk4_$dt momentum_drift_ppm; done))
rule C2_swing_energy all_le 100 $(abs $(for dt in $SS; do v swing_rk4_$dt energy_largest_drift_ppm; done))
lost=0; for tt in T01 T02 T03 T04 T05 T06 T07 T08 T09 T10; do [ "$(verdict stock $tt)" = PASS ] && [ "$(verdict rk4 $tt)" != PASS ] && lost=$((lost + 1)); done
rule C3_nothing_lost eq $lost 0
echo "checks: $(wc -l < $C | tr -d ' '), held: $(grep -c ': HELD$' $C)" >> $C
grep -rlIF "$HOME" $O 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
cat $C; for l in stock rk4; do echo "$l: $(grep '^SUITE' $O/suites/$l/verdicts.txt)"; done
