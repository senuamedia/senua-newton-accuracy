#!/usr/bin/env bash
# Run 068: Senua AI's Featherstone limit patch in design (patches/in_design/featherstone_limit_on_1.7.0.diff), the
# joint limit kept from pulling (NEWTON_FEATHERSTONE_LIMIT=1, issue 16) and also integrated implicitly (=2, issue
# 28), on Newton 1.7.0, on run 055's and run 042's arms. The README's predictions were pushed before these plays.
# Then measured.txt (sx_contact final and swing, each play) and checks.txt (sx_contact rule).
# usage: play.sh <sx_contact binary>   (repository root; STOCK_VENV Newton 1.7.0 as released, LIMIT_VENV the same with
#   the patch's tree first on the path)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary>}")" && pwd)/$(basename "$1")"
O=validation/run_068_featherstone_limit; ROOT=$(pwd)
LIGHT="mass=0.05 radius=0.01 arm=0.02 gravity=1 lo=-0.5 hi=0.5 secs=0.15 solver=featherstone"
STRIKE="radius=0.04 arm=0.4 secs=2 lo=-1 hi=1 solver=featherstone"
CHAIN="mass1=0.7 mass2=1.3 radius=0.04 arm1=0.25 len1=0.5 arm2=0.22 angle1=0 angle2=-0.4 omega1=2.2 omega2=-1.1 secs=2 gravity=0 solver=featherstone"
plays() {  # <name> <environment: stock, off, 1 or 2> <rig> <settings...>
  local dt m e
  for e in stock off 1 2; do
    for dt in 0.0041666667 0.001 0.00025 0.00002 0.000005 0.000002; do echo "l1_light_${e}_$dt $e nwt_joint dt=$dt $LIGHT"; done
    for m in 0.1 1; do for dt in 0.00025 0.0000625; do echo "l3_strike_${e}_m${m}_$dt $e nwt_joint dt=$dt mass=$m $STRIKE"; done; done
    echo "l5_chain_${e}_0.002 $e nwt_chain dt=0.002 $CHAIN"
  done
}
mkdir -p $O/runs $O/stats
date -u +%FT%TZ > $O/started.txt
for g in stock off 1 2; do
  ( v=$LIMIT_VENV; [ $g = stock ] && v=$STOCK_VENV; . "$v/bin/activate"; unset NEWTON_FEATHERSTONE_LIMIT
    case $g in 1|2) export NEWTON_FEATHERSTONE_LIMIT=$g;; esac
    plays | awk -v g=$g '$2 == g { $2 = ""; print }' | xargs -P 2 -L 1 bash -c 'python tools/$1.py '"$O"'/runs/$0.txt "${@:2}" > '"$O"'/stats/$0.txt 2> '"$O"'/runs/log_$0.txt' ) &
done
wait
date -u +%FT%TZ > $O/finished.txt
# ---- measuring
M=$O/measured.txt; : > $M
pick_s() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
for n in $(plays | awk '{print $1}'); do
  f=$O/runs/$n.txt; st=$(pick_s nan_at_step < $O/stats/$n.txt); [ -n "$st" ] || st=$(pick_s out_of_range_at_step < $O/stats/$n.txt)
  case $n in
    l1_*) l="$("$B" final $f < /dev/null | tail -1)";;
    l3_*) l="$("$B" swing $f < /dev/null | tail -1 | awk '{ n = 0; for (i = 1; i < NF; i++) if ($i == "turn_urad") { n++; if (n == 2) { print "back_urad", $(i + 1); exit } } }')";;
    l5_*) l="$("$B" chain $f < /dev/null | tail -1)";;
  esac
  echo "$n stops ${st:--1} $l" >> $M
done
pick() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $M; }
# ---- checks
C=$O/checks.txt; : > $C
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $C; }
same=0; for n in $(plays | awk '$2 == "stock" { print $1 }'); do cmp -s $O/runs/$n.txt $O/runs/${n/_stock_/_off_}.txt && same=$((same + 1)); done
rule F0_safe_when_off eq $same 11
rule F1_fault_there all_ge 0 $(for dt in 0.0041666667 0.001 0.00025 0.00002; do pick l1_light_stock_$dt stops; done)
rule F2_held_numbers all_eq -1 $(for dt in 0.0041666667 0.001 0.00025 0.00002 0.000005 0.000002; do pick l1_light_2_$dt stops; done)
rule F2_held_angle all_within -500000 100 $(for dt in 0.0041666667 0.001 0.00025 0.00002 0.000005 0.000002; do pick l1_light_2_$dt angle_urad; done)
rule F2_held_still_hi all_le 10000 $(for dt in 0.0041666667 0.001 0.00025 0.00002 0.000005 0.000002; do pick l1_light_2_$dt speed_urads; done)
rule F2_held_still_lo all_ge -10000 $(for dt in 0.0041666667 0.001 0.00025 0.00002 0.000005 0.000002; do pick l1_light_2_$dt speed_urads; done)
rule F3_pulls_released all_le -880000 $(for dt in 0.00025 0.0000625; do pick l3_strike_stock_m0.1_$dt back_urad; done)
rule F4_no_pull_0.1kg all_within -815000 40 $(for e in 1 2; do pick l3_strike_${e}_m0.1_0.0000625 back_urad; done) $(pick l3_strike_1_m0.1_0.00025 back_urad)
rule F4_no_pull_1kg all_within -450000 22 $(for e in 1 2; do for dt in 0.00025 0.0000625; do pick l3_strike_${e}_m1_$dt back_urad; done; done)
same5=0; for e in 1 2; do cmp -s $O/runs/l5_chain_stock_0.002.txt $O/runs/l5_chain_${e}_0.002.txt && same5=$((same5 + 1)); done
rule F5_no_limit_unchanged eq $same5 2
echo "checks: $(wc -l < $C | tr -d ' '), held: $(grep -c ': HELD$' $C)" >> $C
grep -rlIF "$HOME" $O 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
cat $C
