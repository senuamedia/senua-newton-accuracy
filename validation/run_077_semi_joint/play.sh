#!/usr/bin/env bash
# Run 077: Senua AI's SemiImplicit joint patch in design (patches/in_design/semi_joint_on_1.7.0.diff): the joint's angle
# measured near its reference and a D6's angles read about its own axes (NEWTON_SEMI_JOINT_ANGLE=1, issue 27), and the
# limit kept from pulling (NEWTON_SEMI_JOINT_LIMIT=1, issue 16's SemiImplicit part), on Newton 1.7.0. The README's
# predictions were pushed before these plays. Then measured.txt (sx_contact final and swing) and checks.txt.
# usage: play.sh <sx_contact binary>   (repository root; STOCK_VENV Newton 1.7.0, JOINT_VENV the patch's tree first)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary>}")" && pwd)/$(basename "$1")"
O=validation/run_077_semi_joint; ROOT=$(pwd)
REP="opt.angular_damping=0 opt.joint_attach_ke=0 opt.joint_attach_kd=0"
STRIKE="radius=0.04 arm=0.4 secs=2 lo=-1 hi=1 solver=semi"
plays() {  # <name> <environment: stock, off, angle, limit> <rig> <settings...>
  local e n s m dt
  for e in stock off angle; do for n in 1 1000; do for s in semi semirep; do
    o="solver=semi"; [ $s = semirep ] && o="solver=semi $REP"
    echo "rev7_${s}_${e}_n$n $e nwt_rest dt=0.001 joint=revolute rest=7 ke=2 steps=$n $o"
    echo "rev2.5_${s}_${e}_n$n $e nwt_rest dt=0.001 joint=revolute rest=2.5 ke=2 steps=$n $o"
    echo "d6_${s}_${e}_n$n $e nwt_rest dt=0.001 joint=d6 ke=2 steps=$n $o"
  done; done; done
  for e in stock off limit; do for m in 0.1 1; do for dt in 0.00025 0.0000625; do
    echo "strike_${e}_m${m}_$dt $e nwt_joint dt=$dt mass=$m $STRIKE"
  done; done; done
}
mkdir -p $O/runs $O/stats; date -u +%FT%TZ > $O/started.txt
for g in stock off angle limit; do
  ( v=$JOINT_VENV; [ $g = stock ] && v=$STOCK_VENV; . "$v/bin/activate"; unset NEWTON_SEMI_JOINT_ANGLE NEWTON_SEMI_JOINT_LIMIT
    [ $g = angle ] && export NEWTON_SEMI_JOINT_ANGLE=1; [ $g = limit ] && export NEWTON_SEMI_JOINT_LIMIT=1
    plays | awk -v g=$g '$2 == g { $2 = ""; print }' | xargs -P 2 -L 1 bash -c 'python tools/$1.py '"$O"'/runs/$0.txt "${@:2}" > '"$O"'/stats/$0.txt 2> '"$O"'/runs/log_$0.txt' ) &
done
wait; date -u +%FT%TZ > $O/finished.txt
back() { "$B" swing $1 < /dev/null | tail -1 | awk '{ n = 0; for (i = 1; i < NF; i++) if ($i == "turn_urad") { n++; if (n == 2) { print $(i + 1); exit } } } END { if (n < 2) print "none" }'; }
M=$O/measured.txt; : > $M
for n in $(plays | awk '{print $1}'); do f=$O/runs/$n.txt
  case $n in strike_*) echo "$n back_urad $(back $f)" >> $M;;
    d6_*) echo "$n $("$B" final $f < /dev/null | tail -1) dof2 $("$B" final $f.dof2 < /dev/null | tail -1)" >> $M;;
    *) echo "$n $("$B" final $f < /dev/null | tail -1)" >> $M;; esac; done
v() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $M; }
v2() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == "dof2") on = 1; else if (on && $i == k) { print $(i + 1); exit } }' $M; }
C=$O/checks.txt; : > $C
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $C; }
same=0; tot=0; for n in $(plays | awk '$2 == "stock" { print $1 }'); do tot=$((tot + 1)); cmp -s $O/runs/$n.txt $O/runs/${n/_stock_/_off_}.txt && same=$((same + 1)); done
rule J0_safe_when_off eq $same $tot
for s in semi semirep; do
  rule J1_rev7_thrown_released_$s all_ge 20000 $(v rev7_${s}_stock_n1 speed_urads)
  rule J2_rev7_held_$s all_in -100 100 $(v rev7_${s}_angle_n1 speed_urads) $(v rev7_${s}_angle_n1000 speed_urads)
  rule J2_rev7_still_$s near $(v rev7_${s}_angle_n1000 angle_urad) $(v rev7_${s}_angle_n1 angle_urad) 1000
  rule J3_rev2.5_unchanged_$s near $(v rev2.5_${s}_angle_n1000 angle_urad) 2500000 1000
  rule J4_d6_drifts_released_$s all_ge 300000 $(v d6_${s}_stock_n1000 angle_urad)
  rule J5_d6_held_$s near $(v d6_${s}_angle_n1000 angle_urad) 200000 1000
  rule J5_d6_held_dof2_$s near $(v2 d6_${s}_angle_n1000 angle_urad) 400000 1000
done
for dt in 0.00025 0.0000625; do
  rule J6_no_pull_0.1kg_$dt all_in -835000 -795000 $(v strike_limit_m0.1_$dt back_urad)
  rule J6_no_pull_1kg_$dt all_in -470000 -430000 $(v strike_limit_m1_$dt back_urad)
done
echo "checks: $(wc -l < $C | tr -d ' '), held: $(grep -c ': HELD$' $C)" >> $C
grep -rlIF "$HOME" $O 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
cat $C
