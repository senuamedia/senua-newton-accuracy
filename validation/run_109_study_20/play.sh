#!/usr/bin/env bash
# Run 109: the twentieth registered study (preregistrations/PREREGISTRATION_20.md), played once on Newton 1.7.0: XPBD's
# joint limit holds an arm and stops a chain as a hard limit does (issue 8), with the joint-angle patch's fourth form at
# 64 iterations, the chain against MuJoCo's own engine with an ever stiffer limit. Each play into runs/ and stats/,
# then the registered rules judged by sx_contact rule (rules.txt), the measured lines beside them (measured.txt).
# DRY=1 plays one throwaway play of each scene and setting, into dry/, to check that the runner runs to the end.
# usage: play.sh <sx_contact binary> <engine folder>   (repository root)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary> <engine folder>}")" && pwd)/$(basename "$1")"; E="$(cd "${2:?}" && pwd)"
O=validation/run_109_study_20
A1="mass=1.2 radius=0.035 arm=0.25 omega0=2.5 angle0=0 lo=-0.6 hi=2.2 gravity=0 solver=xpbd"
A2="mass=0.8 radius=0.025 arm=0.15 omega0=3.5 angle0=0.4 lo=-0.6 hi=2.9 gravity=0 solver=xpbd"
CH="mass1=0.9 mass2=0.5 radius=0.035 arm1=0.2 len1=0.42 arm2=0.18 gravity=0 angle1=0 angle2=0 omega1=1.6 omega2=0 lo1=-1 hi1=2.4"
if [ "${DRY:-0}" = 1 ]; then OUT=$O/dry; AS="0.004"; CS="0.005"; TCS="0.002"; ASEC=0.4; CSEC=0.3; TS="0.2 0.3"
else OUT=$O; AS="0.002 0.0004"; CS="0.0025 0.000625 0.00015625"; TCS="0.0005 0.0002"; ASEC=1.6; CSEC=2.6; TS="1.7 1.9 2.05 2.3 2.6"; fi
plays() { local e dt it; for e in stock stock64 off on; do it=""; case $e in stock64|on) it=" iterations=64";; esac
  for dt in $AS; do echo "a1_${e}_$dt $e nwt_joint dt=$dt $A1 secs=$ASEC$it"; echo "a2_${e}_$dt $e nwt_joint dt=$dt $A2 secs=$ASEC$it"; done
  for dt in $CS; do echo "c_${e}_$dt $e nwt_chain dt=$dt $CH secs=$CSEC solver=xpbd$it"; done; done; }
mkdir -p $OUT/runs $OUT/stats; date -u +%FT%TZ > $OUT/started.txt
( . "$E/stock/bin/activate"
  for tc in $TCS; do dt=$(awk -v t=$tc 'BEGIN { printf "%.10g", t / 20 }'); ev=$(awk -v t=$tc 'BEGIN { printf "%d", 0.0001 / (t / 20) + 0.5 }')
    python tools/mjc_limit_chain.py $OUT/runs/ref_$tc.txt dt=$dt $CH secs=$CSEC timeconst=$tc imp0=0.99 imp1=0.999 every=$ev > $OUT/stats/ref_$tc.txt 2> $OUT/runs/log_ref_$tc.txt & done; wait ) &
for g in stock stock64 off on; do
  ( v=$E/v4; case $g in stock|stock64) v=$E/stock;; esac; . "$v/bin/activate"; unset NEWTON_XPBD_JOINT_ANGLE_UNWRAP; [ $g = on ] && export NEWTON_XPBD_JOINT_ANGLE_UNWRAP=4
    plays | awk -v g=$g '$2 == g { $2 = ""; print }' | xargs -P 2 -L 1 bash -c 'python tools/$1.py '"$OUT"'/runs/$0.txt "${@:2}" > '"$OUT"'/stats/$0.txt 2> '"$OUT"'/runs/log_$0.txt' ) &
done
wait; date -u +%FT%TZ > $OUT/finished.txt
at() { awk -v t=$2 '$1 == "CHAIN" { for (i = 2; i < NF; i++) if ($i == "dt_ns") dt = $(i + 1) / 1e9; next }
  dt > 0 && $1 == sprintf("%d", t / dt - 1 + 0.5) - 0 { print "j1_urad", $2, "j1_urads", $3, "j2_urads", $5; exit }' $1; }
nan() { awk '{ for (i = 1; i < NF; i++) if ($i == "nan_at_step" || $i == "out_of_range_at_step") { print $(i + 1); exit } }' $1; }
M=$OUT/measured.txt; : > $M
for tc in $TCS; do for t in $TS; do echo "ref_$tc t $t stops $(s=$(nan $OUT/stats/ref_$tc.txt); echo ${s:--1}) $(at $OUT/runs/ref_$tc.txt $t)" >> $M; done; done
for n in $(plays | awk '$3 == "nwt_chain" { print $1 }'); do s=$(nan $OUT/stats/$n.txt); for t in $TS; do echo "$n t $t stops ${s:--1} $(at $OUT/runs/$n.txt $t)" >> $M; done; done
for n in $(plays | awk '$3 == "nwt_joint" { print $1 }'); do s=$(nan $OUT/stats/$n.txt); echo "$n t end stops ${s:--1} $("$B" final $OUT/runs/$n.txt < /dev/null | tail -1)" >> $M; done
[ "${DRY:-0}" = 1 ] && { echo "dry run: $(wc -l < $M | tr -d ' ') measured lines"; cat $M; exit 0; }
v() { awk -v n="$1" -v t="$2" -v k="$3" '$1 == n && $3 == t { for (i = 4; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $M; }
abs() { for x in "$@"; do echo "${x#-}"; done; }
R=$OUT/rules.txt; : > $R
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $R; }
s=0; t=0; for n in $(plays | awk '$2 == "stock" { print $1 }'); do t=$((t + 1)); cmp -s $OUT/runs/$n.txt $OUT/runs/${n/_stock_/_off_}.txt && s=$((s + 1)); done
rule R1_safe_when_off eq $s $t
rule R2_fault_there all_le -500000 $(for a in a1 a2; do for dt in $AS; do v ${a}_stock_$dt end speed_urads; done; done)
rule R3_arms_held_a1 all_within 2200000 44 $(for dt in $AS; do v a1_on_$dt end angle_urad; done)
rule R3_arms_held_a2 all_within 2900000 58 $(for dt in $AS; do v a2_on_$dt end angle_urad; done)
rule R3_arms_slow all_in -100000 100000 $(for a in a1 a2; do for dt in $AS; do v ${a}_on_$dt end speed_urads; done; done)
REF=$(v ref_0.0002 2.6 j1_urad)
rule R4_reference_converged near $(v ref_0.0005 2.6 j1_urad) $REF 5000
rule R5_reference_on_the_limit all_in 2399000 2401000 $(v ref_0.0002 1.7 j1_urad) $(v ref_0.0002 1.9 j1_urad)
rule R5_reference_link2 within $(v ref_0.0002 1.9 j2_urads) 5240000 100
rule R6_fault_there_chain all_ge 10000 $(for dt in $CS; do st=$(v c_stock_$dt 1.9 stops); j=$(v c_stock_$dt 1.9 j1_urad)
  if [ "$st" != -1 ] || [ -z "$j" ]; then echo 999999999; else d=$((j - 2400000)); echo ${d#-}; fi; done)
rule R7_on_the_limit all_in 2399000 2401000 $(for dt in 0.000625 0.00015625; do v c_on_$dt 1.7 j1_urad; v c_on_$dt 1.9 j1_urad; done)
d1=$(abs $(( $(v c_on_0.0025 2.6 j1_urad) - REF ))); d2=$(abs $(( $(v c_on_0.000625 2.6 j1_urad) - REF ))); d3=$(abs $(( $(v c_on_0.00015625 2.6 j1_urad) - REF )))
rule R8_nearer_as_the_step_shrinks all_ge 0 $((d1 - d2)) $((d2 - d3))
rule R8_near_at_the_smallest_step le $d3 50000
stopsof() { case $1 in c_*) v $1 2.6 stops;; *) v $1 end stops;; esac; }
rule R9_numbers all_eq -1 $(for n in $(plays | awk '$2 == "on" { print $1 }'); do stopsof $n; done)
grep -rlIF "$HOME" $OUT 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
echo "rules: $(wc -l < $R | tr -d ' '), held: $(grep -c ': HELD$' $R)" >> $R
cat $R
