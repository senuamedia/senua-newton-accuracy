#!/usr/bin/env bash
# Run 070: the Featherstone limit patch's third form (patches/in_design/featherstone_limit_v2_on_1.7.0.diff,
# NEWTON_FEATHERSTONE_LIMIT=3: the implicit limit kept only where the force the implicit step applies pushes), on run
# 068's scenes, beside its first form (=1) and the release, on Newton 1.7.0. The README's predictions were pushed
# before these plays. Then measured.txt (sx_contact final and swing) and checks.txt (sx_contact rule).
# usage: play.sh <sx_contact binary>   (repository root; STOCK_VENV Newton 1.7.0 as released, LIMIT_VENV the same with
#   the patch's tree first on the path)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary>}")" && pwd)/$(basename "$1")"
O=validation/run_070_featherstone_limit_v3; ROOT=$(pwd)
LIGHT="mass=0.05 radius=0.01 arm=0.02 gravity=1 lo=-0.5 hi=0.5 secs=0.15 solver=featherstone"
STRIKE="radius=0.04 arm=0.4 secs=2 lo=-1 hi=1 solver=featherstone"
CHAIN="mass1=0.7 mass2=1.3 radius=0.04 arm1=0.25 len1=0.5 arm2=0.22 angle1=0 angle2=-0.4 omega1=2.2 omega2=-1.1 secs=2 gravity=0 solver=featherstone"
STEPS="0.0041666667 0.001 0.00025 0.00002 0.000005 0.000002"
plays() {  # <name> <environment: stock, off, 1 or 3> <rig> <settings...>
  local dt m e
  for e in stock off 1 3; do
    for dt in $STEPS; do echo "l1_light_${e}_$dt $e nwt_joint dt=$dt $LIGHT"; done
    for m in 0.1 1; do for dt in 0.00025 0.0000625; do echo "l3_strike_${e}_m${m}_$dt $e nwt_joint dt=$dt mass=$m $STRIKE"; done; done
    echo "l5_chain_${e}_0.002 $e nwt_chain dt=0.002 $CHAIN"
  done
}
mkdir -p $O/runs $O/stats
date -u +%FT%TZ > $O/started.txt
for g in stock off 1 3; do
  ( v=$LIMIT_VENV; [ $g = stock ] && v=$STOCK_VENV; . "$v/bin/activate"; unset NEWTON_FEATHERSTONE_LIMIT
    case $g in 1|3) export NEWTON_FEATHERSTONE_LIMIT=$g;; esac
    plays | awk -v g=$g '$2 == g { $2 = ""; print }' | xargs -P 2 -L 1 bash -c 'python tools/$1.py '"$O"'/runs/$0.txt "${@:2}" > '"$O"'/stats/$0.txt 2> '"$O"'/runs/log_$0.txt' ) &
done
wait
date -u +%FT%TZ > $O/finished.txt
# ---- measuring: the turn back after the first strike is swing's second turn (none: the arm never came back up)
M=$O/measured.txt; : > $M
pick_s() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
back() { "$B" swing $1 < /dev/null | tail -1 | awk '{ n = 0; for (i = 1; i < NF; i++) if ($i == "turn_urad") { n++; if (n == 2) { print $(i + 1); exit } } } END { if (n < 2) print "none" }'; }
for n in $(plays | awk '{print $1}'); do
  f=$O/runs/$n.txt; st=$(pick_s nan_at_step < $O/stats/$n.txt); [ -n "$st" ] || st=$(pick_s out_of_range_at_step < $O/stats/$n.txt)
  case $n in
    l1_*) l="$("$B" final $f < /dev/null | tail -1) back_urad $(back $f)";;
    l3_*) l="back_urad $(back $f)";;
    l5_*) l="$("$B" chain $f < /dev/null | tail -1)";;
  esac
  echo "$n stops ${st:--1} $l" >> $M
done
pick() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $M; }
held_back() { local v; v=$(pick $1 back_urad); [ "$v" = none ] && echo -500000 || echo $v; }   # never came back up: at the limit
# ---- checks
C=$O/checks.txt; : > $C
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $C; }
same=0; for n in $(plays | awk '$2 == "stock" { print $1 }'); do cmp -s $O/runs/$n.txt $O/runs/${n/_stock_/_off_}.txt && same=$((same + 1)); done
rule G0_safe_when_off eq $same 11
same1=0; for m in 0.1 1; do for dt in 0.00025 0.0000625; do cmp -s $O/runs/l3_strike_1_m${m}_$dt.txt validation/run_068_featherstone_limit/runs/l3_strike_1_m${m}_$dt.txt && same1=$((same1 + 1)); done; done
rule G1_first_form_unchanged eq $same1 4
rule G2_held_numbers all_eq -1 $(for dt in $STEPS; do pick l1_light_3_$dt stops; done)
rule G2_held_angle all_within -500000 100 $(for dt in $STEPS; do pick l1_light_3_$dt angle_urad; done)
rule G2_held_no_bounce all_within -500000 100 $(for dt in $STEPS; do held_back l1_light_3_$dt; done)
rule G4_no_pull_0.1kg all_within -815000 40 $(pick l3_strike_3_m0.1_0.0000625 back_urad)
rule G4_no_pull_1kg all_within -450000 22 $(for dt in 0.00025 0.0000625; do pick l3_strike_3_m1_$dt back_urad; done)
cmp -s $O/runs/l5_chain_stock_0.002.txt $O/runs/l5_chain_3_0.002.txt && s5=1 || s5=0
rule G5_no_limit_unchanged eq $s5 1
echo "checks: $(wc -l < $C | tr -d ' '), held: $(grep -c ': HELD$' $C)" >> $C
grep -rlIF "$HOME" $O 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
cat $C
