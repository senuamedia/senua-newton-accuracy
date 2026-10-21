#!/usr/bin/env bash
# Run 078: the twelfth registered study (preregistrations/PREREGISTRATION_12.md), played once on Newton 1.7.0:
# SemiImplicit's joint angle (27) and Featherstone's limit integrated implicitly (28). Each play into runs/ and stats/,
# then every registered rule judged by sx_contact rule (rules.txt), the measured lines beside them (measured.txt).
# DRY=1 plays one throwaway play of each scene, into dry/, to check that the runner runs to the end; no rule is read.
# usage: play.sh <sx_contact binary> <engine folder>   (repository root; the engine folder made by setup_engine.sh)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary> <engine folder>}")" && pwd)/$(basename "$1")"
E="$(cd "${2:?}" && pwd)"
O=validation/run_078_study_12; ROOT=$(pwd)
REP="opt.angular_damping=0 opt.joint_attach_ke=0 opt.joint_attach_kd=0"
LIGHT="mass=0.08 radius=0.012 arm=0.025 gravity=1 lo=-0.6 hi=0.6 secs=0.2 solver=featherstone"
SERIAL="mass1=0.06 mass2=0.06 radius=0.012 arm1=0.025 len1=0.05 arm2=0.025 angle1=0 angle2=0 gravity=1 secs=0.25 lo1=-0.6 hi1=0.6 solver=featherstone"
if [ "${DRY:-0}" = 1 ]; then OUT=$O/dry; S1="0.002"; S2="0.001"; LS="0.001"; N1=50; N2=50
else OUT=$O; S1="0.001 0.0005"; S2="0.002 0.0005"; LS="0.0041666667 0.002 0.0005 0.00005"; N1=800; N2=600; fi
plays() {  # <name> <environment: stock, joff, angle, foff, three> <rig> <settings...>
  local e s dt n
  for e in stock joff angle; do for s in semi semirep; do
    o="solver=semi"; [ $s = semirep ] && o="solver=semi $REP"
    for dt in $S1; do for n in 1 $N1; do echo "s1_${s}_${e}_${dt}_n$n $e nwt_rest dt=$dt joint=revolute rest=8.1 ke=3 steps=$n $o"; done; done
    for dt in $S2; do echo "s2_${s}_${e}_$dt $e nwt_rest dt=$dt joint=d6 ke=5 steps=$N2 $o"; done
  done; done
  for e in stock foff three; do [ $e = foff ] && g=foff || g=$e
    for dt in $LS; do
      echo "s3_light_${e}_$dt $g nwt_joint dt=$dt $LIGHT"
      echo "s4_serial_${e}_$dt $g nwt_chain dt=$dt $SERIAL"
    done
  done
}
mkdir -p $OUT/runs $OUT/stats
date -u +%FT%TZ > $OUT/started.txt
for g in stock joff angle foff three; do
  ( case $g in stock) v=$E/stock;; joff|angle) v=$E/semijoint;; *) v=$E/fslimit;; esac
    . "$v/bin/activate"; unset NEWTON_SEMI_JOINT_ANGLE NEWTON_SEMI_JOINT_LIMIT NEWTON_FEATHERSTONE_LIMIT
    [ $g = angle ] && export NEWTON_SEMI_JOINT_ANGLE=1; [ $g = three ] && export NEWTON_FEATHERSTONE_LIMIT=3
    plays | awk -v g=$g '$2 == g { $2 = ""; print }' | xargs -P 2 -L 1 bash -c 'python tools/$1.py '"$OUT"'/runs/$0.txt "${@:2}" > '"$OUT"'/stats/$0.txt 2> '"$OUT"'/runs/log_$0.txt' ) &
done
wait
date -u +%FT%TZ > $OUT/finished.txt
# ---- measuring
pick_s() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
back() { "$B" swing $1 < /dev/null | tail -1 | awk '{ n = 0; for (i = 1; i < NF; i++) if ($i == "turn_urad") { n++; if (n == 2) { print $(i + 1); exit } } } END { if (n < 2) print "none" }'; }
M=$OUT/measured.txt; : > $M
for n in $(plays | awk '{print $1}'); do f=$OUT/runs/$n.txt
  st=$(pick_s nan_at_step < $OUT/stats/$n.txt); [ -n "$st" ] || st=$(pick_s out_of_range_at_step < $OUT/stats/$n.txt)
  case $n in
    s2_*) l="$("$B" final $f < /dev/null | tail -1) dof2 $("$B" final $f.dof2 < /dev/null | tail -1)";;
    s3_*) l="$("$B" final $f < /dev/null | tail -1) back_urad $(back $f)";;
    s4_*) l="last_line $(tail -1 $f | awk '{print "angle1_urad", $2, "speed1_urads", $3}')";;
    *) l="$("$B" final $f < /dev/null | tail -1)";;
  esac
  echo "$n stops ${st:--1} $l" >> $M
done
[ "${DRY:-0}" = 1 ] && { echo "dry run: $(wc -l < $M | tr -d ' ') measured lines"; cat $M; exit 0; }
v() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $M; }
v2() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == "dof2") on = 1; else if (on && $i == k) { print $(i + 1); exit } }' $M; }
# ---- the rules
R=$OUT/rules.txt; : > $R
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $R; }
s=0; t=0; for n in $(plays | awk '$2 == "stock" && /nwt_rest/ { print $1 }'); do t=$((t + 1)); cmp -s $OUT/runs/$n.txt $OUT/runs/${n/_stock_/_joff_}.txt && s=$((s + 1)); done
rule R1_safe_when_off_27 eq $s $t
rule R2_fault_there_27 all_ge 10000 $(for s in semi semirep; do for dt in $S1; do v s1_${s}_stock_${dt}_n1 speed_urads; done; done)
rule R3_held_27_speed all_in -100 100 $(for s in semi semirep; do for dt in $S1; do v s1_${s}_angle_${dt}_n1 speed_urads; v s1_${s}_angle_${dt}_n$N1 speed_urads; done; done)
for s in semi semirep; do for dt in $S1; do
  rule R3_held_27_still_${s}_$dt near $(v s1_${s}_angle_${dt}_n$N1 angle_urad) $(v s1_${s}_angle_${dt}_n1 angle_urad) 1000
done; done
rule R4_fault_there_27_d6 all_ge 250000 $(for s in semi semirep; do for dt in $S2; do v s2_${s}_stock_$dt angle_urad; done; done)
for s in semi semirep; do for dt in $S2; do
  rule R5_d6_held_${s}_$dt near $(v s2_${s}_angle_$dt angle_urad) 200000 1000
  rule R5_d6_held_dof2_${s}_$dt near $(v2 s2_${s}_angle_$dt angle_urad) 400000 1000
done; done
s=0; t=0; for n in $(plays | awk '$2 == "stock" && !/nwt_rest/ { print $1 }'); do t=$((t + 1)); cmp -s $OUT/runs/$n.txt $OUT/runs/${n/_stock_/_foff_}.txt && s=$((s + 1)); done
rule R6_safe_when_off_28 eq $s $t
rule R7_fault_there_28 all_ge 0 $(for dt in $LS; do v s3_light_stock_$dt stops; v s4_serial_stock_$dt stops; done)
rule R8_numbers_28 all_eq -1 $(for dt in $LS; do v s3_light_three_$dt stops; v s4_serial_three_$dt stops; done)
rule R9_on_limit_28_angle all_within -600000 100 $(for dt in $LS; do v s3_light_three_$dt angle_urad; v s4_serial_three_$dt angle1_urad; done)
rule R9_on_limit_28_still all_in -10000 10000 $(for dt in $LS; do v s3_light_three_$dt speed_urads; v s4_serial_three_$dt speed1_urads; done)
grep -rlIF "$HOME" $OUT 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
echo "rules: $(wc -l < $R | tr -d ' '), held: $(grep -c ': HELD$' $R)" >> $R
cat $R
