#!/usr/bin/env bash
# Run 072: the eleventh registered study (preregistrations/PREREGISTRATION_11.md), played once on Newton 1.7.0: the
# elliptic cone with noslip on the MuJoCo solver's CPU path (15, and 6's part), that path beside the Warp path (24), and
# Featherstone's limit kept from pulling (16). Each play into runs/ and stats/, then every registered rule judged by
# sx_contact rule (rules.txt), the measured lines beside them (measured.txt).
# DRY=1 plays one throwaway play of each scene, into dry/, to check that the runner runs to the end; no rule is read.
# usage: play.sh <sx_contact binary> <engine folder>   (repository root; the engine folder made by setup_engine.sh)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary> <engine folder>}")" && pwd)/$(basename "$1")"
E="$(cd "${2:?}" && pwd)"
O=validation/run_072_study_11; ROOT=$(pwd)
CPU="solver=mujoco opt.use_mujoco_cpu=true"
HOLD="mass=1.5 radius=0.04 h0=0 mu=0.6 push=6.174 pushat=0.4 secs=1.6"
SLIDE="mass=1.5 radius=0.04 h0=0 mu=0.6 vx0=0.8 secs=1"
DROP="mass=0.8 radius=0.03 h0=0.05 mu=0.3 secs=1"
PUSH="mass=0.8 radius=0.03 gravity=0 h0=1 push=0.04 secs=1.2"
TORQUE="mass=1.6 radius=0.04 arm=0.35 gravity=0 torque=0.7 secs=0.04"
STRIKE="radius=0.04 arm=0.35 gravity=1 lo=-0.8 hi=0.8 secs=2 solver=featherstone"
if [ "${DRY:-0}" = 1 ]; then OUT=$O/dry; ES="0.002"; FS="0.0005"; MS="0.3"; else OUT=$O; ES="0.001 0.004"; FS="0.0002 0.00005"; MS="0.3 2"; fi
plays() {  # <name> <environment: stock, noslip, fsoff, fs1> <rig> <settings...>
  local dt m
  for dt in $ES; do
    echo "e1_hold_$dt stock nwt_contact dt=$dt $HOLD $CPU opt.cone=elliptic"
    echo "e1_hold_off_$dt noslip nwt_contact dt=$dt $HOLD $CPU opt.cone=elliptic"
    echo "e1_hold_noslip_$dt noslip nwt_contact dt=$dt $HOLD $CPU opt.cone=elliptic opt.noslip_iterations=5"
    echo "e2_slide_$dt stock nwt_contact dt=$dt $SLIDE $CPU opt.cone=elliptic"
    echo "e2_slide_noslip_$dt noslip nwt_contact dt=$dt $SLIDE $CPU opt.cone=elliptic opt.noslip_iterations=5"
    echo "e3_drop_noslip_$dt noslip nwt_contact dt=$dt $DROP $CPU opt.cone=elliptic opt.noslip_iterations=5"
    echo "e4_drop_warp_$dt stock nwt_contact dt=$dt $DROP solver=mujoco"
    echo "e4_drop_cpu_$dt stock nwt_contact dt=$dt $DROP $CPU"
    echo "e4_push_warp_$dt stock nwt_contact dt=$dt $PUSH solver=mujoco"
    echo "e4_push_cpu_$dt stock nwt_contact dt=$dt $PUSH $CPU"
    echo "e4_torque_warp_$dt stock nwt_joint dt=$dt $TORQUE solver=mujoco"
    echo "e4_torque_cpu_$dt stock nwt_joint dt=$dt $TORQUE $CPU"
  done
  for m in $MS; do for dt in $FS; do
    echo "e5_strike_stock_m${m}_$dt stock nwt_joint dt=$dt mass=$m $STRIKE"
    echo "e5_strike_off_m${m}_$dt fsoff nwt_joint dt=$dt mass=$m $STRIKE"
    echo "e5_strike_one_m${m}_$dt fs1 nwt_joint dt=$dt mass=$m $STRIKE"
  done; done
}
mkdir -p $OUT/runs $OUT/stats
date -u +%FT%TZ > $OUT/started.txt
for g in stock noslip fsoff fs1; do
  ( case $g in stock) v=$E/stock;; noslip) v=$E/noslip;; *) v=$E/fslimit;; esac
    . "$v/bin/activate"; unset NEWTON_FEATHERSTONE_LIMIT; [ $g = fs1 ] && export NEWTON_FEATHERSTONE_LIMIT=1
    plays | awk -v g=$g '$2 == g { $2 = ""; print }' | xargs -P 2 -L 1 bash -c 'python tools/$1.py '"$OUT"'/runs/$0.txt "${@:2}" > '"$OUT"'/stats/$0.txt 2> '"$OUT"'/runs/log_$0.txt' ) &
done
wait
date -u +%FT%TZ > $OUT/finished.txt
# ---- measuring
pick_s() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
back() { "$B" swing $1 < /dev/null | tail -1 | awk '{ n = 0; for (i = 1; i < NF; i++) if ($i == "turn_urad") { n++; if (n == 2) { print $(i + 1); exit } } } END { if (n < 2) print "none" }'; }
M=$OUT/measured.txt; : > $M
for n in $(plays | awk '{print $1}'); do
  f=$OUT/runs/$n.txt; st=$(pick_s nan_at_step < $OUT/stats/$n.txt); [ -n "$st" ] || st=$(pick_s out_of_range_at_step < $OUT/stats/$n.txt)
  case $n in
    e1_*) l="$("$B" creep $f < /dev/null | tail -1)";; e2_*) l="$("$B" stop $f < /dev/null | tail -1)";;
    e3_*|e4_drop_*) l="$("$B" rest $f < /dev/null | tail -1)";; e4_push_*|e4_torque_*) l="$("$B" final $f < /dev/null | tail -1)";;
    e5_*) l="back_urad $(back $f)";;
  esac
  echo "$n stops ${st:--1} $l" >> $M
done
[ "${DRY:-0}" = 1 ] && { echo "dry run: $(wc -l < $M | tr -d ' ') measured lines"; cat $M; exit 0; }
v() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $M; }
# ---- the rules
R=$OUT/rules.txt; : > $R
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $R; }
s1=0; for dt in $ES; do cmp -s $OUT/runs/e1_hold_$dt.txt $OUT/runs/e1_hold_off_$dt.txt && s1=$((s1 + 1)); done
rule R1_safe_when_off_15 eq $s1 2
rule R2_fault_there_15 all_ge 100 $(for dt in $ES; do v e1_hold_$dt mean_speed_ums; done)
rule R3_held_15 all_in -10 10 $(for dt in $ES; do v e1_hold_noslip_$dt mean_speed_ums; done)
for dt in $ES; do
  rule R4_slide_kept_$dt within $(v e2_slide_noslip_$dt slid_um) $(v e2_slide_$dt slid_um) 100
  rule R6_cpu_contacts_24_$dt within $(v e4_drop_cpu_$dt mean_ground_force_mN) $(v e4_drop_warp_$dt mean_ground_force_mN) 100
  rule R8_cpu_joint_force_24_$dt within $(v e4_torque_cpu_$dt angle_urad) $(v e4_torque_warp_$dt angle_urad) 100
done
rule R5_weight_kept all_within 7840 100 $(for dt in $ES; do v e3_drop_noslip_$dt mean_ground_force_mN; done)
rule R7_cpu_forces_24 all_within 60000 1000 $(for dt in $ES; do v e4_push_warp_$dt speed_urads; v e4_push_cpu_$dt speed_urads; done)
rule R9_cpu_plays_24 all_eq -1 $(for n in $(plays | awk '/opt.use_mujoco_cpu/ { print $1 }'); do v $n stops; done)
s10=0; for m in $MS; do for dt in $FS; do cmp -s $OUT/runs/e5_strike_stock_m${m}_$dt.txt $OUT/runs/e5_strike_off_m${m}_$dt.txt && s10=$((s10 + 1)); done; done
rule R10_safe_when_off_16 eq $s10 4
for dt in $FS; do
  rule R11_fault_there_16_m0.3_$dt all_le -582466 $(v e5_strike_stock_m0.3_$dt back_urad)
  rule R11_fault_there_16_m2_$dt all_le -337277 $(v e5_strike_stock_m2_$dt back_urad)
  rule R12_kept_16_m0.3_$dt all_in -592466 -552466 $(v e5_strike_one_m0.3_$dt back_urad)
  rule R12_kept_16_m2_$dt all_in -347277 -307277 $(v e5_strike_one_m2_$dt back_urad)
done
grep -rlIF "$HOME" $OUT 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
echo "rules: $(wc -l < $R | tr -d ' '), held: $(grep -c ': HELD$' $R)" >> $R
cat $R
