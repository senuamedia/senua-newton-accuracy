#!/usr/bin/env bash
# Run 064: the ninth registered study (preregistrations/PREREGISTRATION_09.md), played once on Newton 1.7.0: five issues
# answered by Newton's own options. Scenes C1 to C5, each play into this run's runs/ and stats/, then every registered
# rule judged by sx_contact rule (rules.txt), the measured lines beside them (measured.txt).
# DRY=1 plays one throwaway play of each scene, into dry/, to check that the runner runs to the end; no rule is read.
# usage: play.sh <sx_contact binary>   (repository root; STOCK_VENV set to Newton 1.7.0 as released, NORMAL_VENV to the
#   same with Study 3's normal contact rebased onto 1.7.0, patches/newton-1.7.0/, Study 7's environment)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary>}")" && pwd)/$(basename "$1")"
O=validation/run_064_study_09; ROOT=$(pwd)
CHAIN="mass1=0.7 mass2=1.3 radius=0.04 arm1=0.25 len1=0.5 arm2=0.22 angle1=0 angle2=-0.4 omega1=2.2 omega2=-1.1 secs=2 gravity=0"
SPIN="mass=1.5 radius=0.04 h0=1 gravity=0 wz0=4 secs=2 comx=0.03"
SLIP="mass=1.5 radius=0.035 h0=0.06 secs=0.5"
SMALL="mass=0.5 radius=0.035 h0=0.07 secs=0.5 mu=0"
if [ "${DRY:-0}" = 1 ]; then
  OUT=$O/dry; C1S="0.004"; C2S="0.004"; C3S="0.001"; C3MU="0.0005"; C4S="0.0025"; C5S="0.0005"
else
  OUT=$O; C1S="0.008 0.002 0.0005 0.000125"; C2S="0.008 0.002 0.0005"; C3S="0.002 0.00025"; C3MU="0 0.0001 0.001"
  C4S="0.00125 0.0003125"; C5S="0.001 0.0005 0.00025"
fi
mkdir -p $OUT/runs $OUT/stats
one() {  # <venv> <switches: none or normal> <name> <rig> <settings...>: one play, its file in runs/, its STATS in stats/
  local venv=$1 sw=$2 n=$3 rig=$4; shift 4
  ( . "$venv/bin/activate"; unset NEWTON_UNIT_FRICTION_DIRECTION NEWTON_CONTACT_DAMPING_NO_PULL
    if [ "$sw" = normal ]; then export NEWTON_UNIT_FRICTION_DIRECTION=1 NEWTON_CONTACT_DAMPING_NO_PULL=1; fi
    python tools/$rig.py $OUT/runs/$n.txt "$@" > $OUT/stats/$n.txt 2>> $OUT/runs/log.txt )
}
date -u +%FT%TZ > $OUT/started.txt
( for dt in $C1S; do one "$STOCK_VENV" none c1_release_$dt nwt_chain dt=$dt $CHAIN solver=mujoco
                     one "$STOCK_VENV" none c1_rk4_$dt nwt_chain dt=$dt $CHAIN solver=mujoco opt.integrator=rk4; done ) &
( for dt in $C2S; do one "$STOCK_VENV" none c2_release_$dt nwt_contact dt=$dt $SPIN solver=mujoco
                     one "$STOCK_VENV" none c2_rk4_$dt nwt_contact dt=$dt $SPIN solver=mujoco opt.integrator=rk4; done ) &
( for mu in $C3MU; do for dt in $C3S; do one "$STOCK_VENV" none c3_default_${mu}_$dt nwt_contact dt=$dt $SLIP mu=$mu solver=mujoco
                                         one "$STOCK_VENV" none c3_elliptic_${mu}_$dt nwt_contact dt=$dt $SLIP mu=$mu solver=mujoco opt.cone=elliptic; done; done ) &
( for s in semi featherstone; do
    [ "${DRY:-0}" = 1 ] || one "$STOCK_VENV" none c4_release_${s}_0.005 nwt_contact dt=0.005 $SMALL solver=$s
    for dt in $C4S; do one "$STOCK_VENV" none c4_release_${s}_$dt nwt_contact dt=$dt $SMALL solver=$s
                       one "$NORMAL_VENV" normal c4_normal_${s}_$dt nwt_contact dt=$dt $SMALL solver=$s; done
  done
  for dt in $C5S; do one "$STOCK_VENV" none c5_release_$dt nwt_chain dt=$dt $CHAIN solver=semi
                     one "$STOCK_VENV" none c5_kd0_$dt nwt_chain dt=$dt $CHAIN solver=semi opt.joint_attach_kd=0; done ) &
wait
date -u +%FT%TZ > $OUT/finished.txt
# ---- measuring
pick() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
# a play stops being a number where the rig says nan_at_step, or leaves its range (out_of_range_at_step); -1 when neither
nan() { local v; v=$(pick nan_at_step < $OUT/stats/$1.txt); [ -n "$v" ] || v=$(pick out_of_range_at_step < $OUT/stats/$1.txt); echo "${v:--1}"; }
M=$OUT/measured.txt; : > $M
for f in $(cd $OUT/runs && ls c1_*.txt c5_*.txt 2>/dev/null); do n=${f%.txt}; l=$("$B" chain $OUT/runs/$f | tail -1)
  echo "$n nan $(nan $n) energy_drift_ppm $(echo "$l" | pick energy_drift_ppm_of_most_kinetic) momentum_drift_ppm $(echo "$l" | pick momentum_drift_ppm) kinetic_end_per_million $(echo "$l" | pick kinetic_end_per_million_of_start)" >> $M; done
for f in $(cd $OUT/runs && ls c2_*.txt 2>/dev/null); do n=${f%.txt}
  echo "$n nan $(nan $n) mean_speed_ums $("$B" creep $OUT/runs/$f | tail -1 | pick mean_speed_ums) largest_speed_last_third_ums $("$B" stop $OUT/runs/$f | tail -1 | pick largest_speed_last_third_ums)" >> $M; done
for f in $(cd $OUT/runs && ls c3_*.txt 2>/dev/null); do n=${f%.txt}
  echo "$n nan $(nan $n) mean_ground_force_mN $("$B" rest $OUT/runs/$f | tail -1 | pick mean_ground_force_mN)" >> $M; done
for f in $(cd $OUT/runs && ls c4_*.txt 2>/dev/null); do n=${f%.txt}
  echo "$n nan $(nan $n) rebound_per_10000 $("$B" bounce $OUT/runs/$f | tail -1 | pick rebound_per_10000)" >> $M; done
[ "${DRY:-0}" = 1 ] && { echo "dry run: $(wc -l < $M | tr -d ' ') measured lines"; cat $M; exit 0; }
v() { grep "^$1 " $M | pick "$2"; }   # <play name> <field>
# ---- the rules
R=$OUT/rules.txt; : > $R
rule() { "$B" rule "$@" | tail -1 >> $R; }
abs() { for x in "$@"; do echo "${x#-}"; done; }
rule R1_fault_there_11 all_ge 1000 $(abs $(v c1_release_0.008 energy_drift_ppm))
rule R2_kept_11_energy all_le 100 $(abs $(for dt in $C1S; do v c1_rk4_$dt energy_drift_ppm; done))
rule R2_kept_11_momentum all_le 100 $(abs $(for dt in $C1S; do v c1_rk4_$dt momentum_drift_ppm; done))
rule R3_fault_there_13 all_ge 1000 $(abs $(v c2_release_0.008 mean_speed_ums))
rule R4_at_rest_13 all_le 120 $(abs $(for dt in $C2S; do v c2_rk4_$dt largest_speed_last_third_ums; done))
rule R5_fault_there_14 all_ge 1 $(for mu in $C3MU; do for dt in $C3S; do v c3_default_${mu}_$dt nan; done; done)
rule R6_played_14_numbers all_eq -1 $(for mu in $C3MU; do for dt in $C3S; do v c3_elliptic_${mu}_$dt nan; done; done)
rule R6_played_14_weight all_within 14700 100 $(for mu in $C3MU; do for dt in $C3S; do v c3_elliptic_${mu}_$dt mean_ground_force_mN; done; done)
rule R7_fault_there_9 all_ge 1000 $(for s in semi featherstone; do v c4_release_${s}_0.005 rebound_per_10000; done)
rule R8_carried_9_rebound all_eq 0 $(for s in semi featherstone; do for dt in $C4S; do v c4_normal_${s}_$dt rebound_per_10000; done; done)
rule R8_carried_9_numbers all_eq -1 $(for s in semi featherstone; do for dt in $C4S; do v c4_normal_${s}_$dt nan; done; done)
rule R9_fault_there_10 all_ge 1 $(v c5_release_0.001 nan)
rule R10_played_10_numbers all_eq -1 $(for dt in $C5S; do v c5_kd0_$dt nan; done)
rule R10_played_10_energy all_within 1000000 100 $(for dt in $C5S; do v c5_kd0_$dt kinetic_end_per_million; done)
grep -rlIF "$HOME" $OUT 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
echo "rules: $(wc -l < $R | tr -d ' '), held: $(grep -c ': HELD$' $R)" >> $R
cat $R
