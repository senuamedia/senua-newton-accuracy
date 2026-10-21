#!/usr/bin/env bash
# Run 080: the thirteenth registered study (preregistrations/PREREGISTRATION_13.md), played once on Newton 1.7.0:
# SemiImplicit's joint angle (27). Each play into runs/ and stats/, then every registered rule judged by sx_contact rule
# (rules.txt), the measured lines beside them (measured.txt).
# DRY=1 plays one throwaway play of each scene, into dry/, to check that the runner runs to the end; no rule is read.
# usage: play.sh <sx_contact binary> <engine folder>   (repository root; the engine folder made by run 078's setup_engine.sh)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary> <engine folder>}")" && pwd)/$(basename "$1")"
E="$(cd "${2:?}" && pwd)"
O=validation/run_080_study_13; ROOT=$(pwd)
REP="opt.angular_damping=0 opt.joint_attach_ke=0 opt.joint_attach_kd=0"
if [ "${DRY:-0}" = 1 ]; then OUT=$O/dry; T1="0.004"; N1=30; T2="0.004:30"
else OUT=$O; T1="0.002 0.00025"; N1=1200; T2="0.001:1500 0.0005:2000"; fi
plays() {  # <name> <environment: stock, joff, angle> <settings...>
  local e s dt n p
  for e in stock joff angle; do for s in semi semirep; do
    o="solver=semi"; [ $s = semirep ] && o="solver=semi $REP"
    for dt in $T1; do for n in 1 $N1; do echo "t1_${s}_${e}_${dt}_n$n $e dt=$dt joint=revolute rest=-7.6 ke=4 steps=$n $o"; done; done
    for p in $T2; do echo "t2_${s}_${e}_${p%%:*} $e dt=${p%%:*} joint=d6 ke=3 steps=${p##*:} $o"; done
  done; done
}
mkdir -p $OUT/runs $OUT/stats
date -u +%FT%TZ > $OUT/started.txt
for g in stock joff angle; do
  ( v=$E/semijoint; [ $g = stock ] && v=$E/stock; . "$v/bin/activate"; unset NEWTON_SEMI_JOINT_ANGLE NEWTON_SEMI_JOINT_LIMIT
    [ $g = angle ] && export NEWTON_SEMI_JOINT_ANGLE=1
    plays | awk -v g=$g '$2 == g { $2 = ""; print }' | xargs -P 2 -L 1 bash -c 'python tools/nwt_rest.py '"$OUT"'/runs/$0.txt "$@" > '"$OUT"'/stats/$0.txt 2> '"$OUT"'/runs/log_$0.txt' ) &
done
wait
date -u +%FT%TZ > $OUT/finished.txt
M=$OUT/measured.txt; : > $M
for n in $(plays | awk '{print $1}'); do f=$OUT/runs/$n.txt
  case $n in t2_*) echo "$n $("$B" final $f < /dev/null | tail -1) dof2 $("$B" final $f.dof2 < /dev/null | tail -1)" >> $M;;
    *) echo "$n $("$B" final $f < /dev/null | tail -1)" >> $M;; esac; done
[ "${DRY:-0}" = 1 ] && { echo "dry run: $(wc -l < $M | tr -d ' ') measured lines"; cat $M; exit 0; }
v() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $M; }
v2() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == "dof2") on = 1; else if (on && $i == k) { print $(i + 1); exit } }' $M; }
R=$OUT/rules.txt; : > $R
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $R; }
s=0; t=0; for n in $(plays | awk '$2 == "stock" { print $1 }'); do t=$((t + 1)); cmp -s $OUT/runs/$n.txt $OUT/runs/${n/_stock_/_joff_}.txt && s=$((s + 1)); done
rule R1_safe_when_off eq $s $t
abs() { for x in "$@"; do echo "${x#-}"; done; }
rule R2_fault_there_drive all_ge 10000 $(abs $(for s in semi semirep; do for dt in $T1; do v t1_${s}_stock_${dt}_n1 speed_urads; done; done))
rule R3_held_speed all_in -100 100 $(for s in semi semirep; do for dt in $T1; do v t1_${s}_angle_${dt}_n1 speed_urads; v t1_${s}_angle_${dt}_n$N1 speed_urads; done; done)
for s in semi semirep; do for dt in $T1; do rule R3_held_still_${s}_$dt near $(v t1_${s}_angle_${dt}_n$N1 angle_urad) $(v t1_${s}_angle_${dt}_n1 angle_urad) 1000; done; done
rule R4_fault_there_d6 all_ge 220000 $(for s in semi semirep; do for p in $T2; do v t2_${s}_stock_${p%%:*} angle_urad; done; done)
for s in semi semirep; do for p in $T2; do
  rule R5_d6_held_${s}_${p%%:*} near $(v t2_${s}_angle_${p%%:*} angle_urad) 200000 1000
  rule R5_d6_held_dof2_${s}_${p%%:*} near $(v2 t2_${s}_angle_${p%%:*} angle_urad) 400000 1000
done; done
grep -rlIF "$HOME" $OUT 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
echo "rules: $(wc -l < $R | tr -d ' '), held: $(grep -c ': HELD$' $R)" >> $R
cat $R
