#!/usr/bin/env bash
# Run 066: the MuJoCo solver's CPU path (issue 24: use_mujoco_cpu, MuJoCo's C engine stepping Newton's model) against
# its MuJoCo Warp path, on the record's scenes, on Newton 1.7.0 as released. The README's predictions were pushed before
# these plays. Then measured.txt (sx_contact, each play) and checks.txt (sx_contact rule).
# usage: play.sh <sx_contact binary>   (repository root; STOCK_VENV set to Newton 1.7.0 as released)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary>}")" && pwd)/$(basename "$1")"
O=validation/run_066_mujoco_cpu_path; ROOT=$(pwd)
CHAIN="mass1=0.7 mass2=1.3 radius=0.04 arm1=0.25 len1=0.5 arm2=0.22 angle1=0 angle2=-0.4 omega1=2.2 omega2=-1.1 secs=2 gravity=0"
plays() {  # <name> <rig> <settings...>
  local dt p o
  for dt in 0.002 0.0005; do for p in warp cpu; do
    o="solver=mujoco"; [ $p = cpu ] && o="$o opt.use_mujoco_cpu=true"
    echo "k1_drop_${p}_$dt nwt_contact dt=$dt $o h0=0.08 mu=0.5 secs=1"
    echo "k2_push_${p}_$dt nwt_contact dt=$dt $o gravity=0 h0=1 push=0.05 secs=1"
    echo "k3_slide_${p}_$dt nwt_contact dt=$dt $o h0=0 vx0=1 mu=0.5 secs=0.5"
    echo "k4_hold_${p}_$dt nwt_contact dt=$dt $o mass=1 radius=0.05 h0=0 mu=0.5 push=2.94 pushat=0.5 secs=2"
    echo "k5_torque_${p}_$dt nwt_joint dt=$dt $o mass=1 radius=0.05 arm=0.5 gravity=0 torque=1 secs=0.05"
    echo "k6_chain_${p}_$dt nwt_chain dt=$dt $o $CHAIN"
  done; done
}
mkdir -p $O/runs $O/stats
date -u +%FT%TZ > $O/started.txt
( . "$STOCK_VENV/bin/activate"
  plays | while read -r n rig rest; do echo "$n $rig $rest"; done | xargs -P 6 -L 1 bash -c 'python tools/$1.py '"$O"'/runs/$0.txt "${@:2}" > '"$O"'/stats/$0.txt 2>> '"$O"'/runs/log_$0.txt' )
date -u +%FT%TZ > $O/finished.txt
# ---- measuring
M=$O/measured.txt; : > $M
pick_s() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
for n in $(plays | awk '{print $1}'); do
  f=$O/runs/$n.txt; st=$(pick_s nan_at_step < $O/stats/$n.txt); [ -n "$st" ] || st=$(pick_s out_of_range_at_step < $O/stats/$n.txt)
  case $n in
    k1_*) l="$("$B" rest $f < /dev/null | tail -1)";; k2_*|k5_*) l="$("$B" final $f < /dev/null | tail -1)";;
    k3_*) l="$("$B" stop $f < /dev/null | tail -1)";; k4_*) l="$("$B" creep $f < /dev/null | tail -1)";;
    k6_*) l="$("$B" chain $f < /dev/null | tail -1)";;
  esac
  echo "$n stops ${st:--1} $l" >> $M
done
pick() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $M; }
# ---- checks
C=$O/checks.txt; : > $C
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $C; }
for dt in 0.002 0.0005; do
  rule K0_numbers_$dt all_eq -1 $(for k in k1_drop k2_push k3_slide k4_hold k5_torque k6_chain; do pick ${k}_cpu_$dt stops; done)
  rule K1_drop_$dt all_within $(pick k1_drop_warp_$dt mean_ground_force_mN) 100 $(pick k1_drop_cpu_$dt mean_ground_force_mN)
  rule K2_push_$dt all_within 50000 1000 $(pick k2_push_warp_$dt speed_urads) $(pick k2_push_cpu_$dt speed_urads)
  rule K3_slide_$dt all_within $(pick k3_slide_warp_$dt slid_um) 100 $(pick k3_slide_cpu_$dt slid_um)
  rule K5_torque_$dt all_within $(pick k5_torque_warp_$dt angle_urad) 100 $(pick k5_torque_cpu_$dt angle_urad)
  rule K6_chain_$dt all_within $(pick k6_chain_warp_$dt kinetic_end_per_million_of_start) 1000 $(pick k6_chain_cpu_$dt kinetic_end_per_million_of_start)
done
echo "checks: $(wc -l < $C | tr -d ' '), held: $(grep -c ': HELD$' $C)" >> $C
grep -rlIF "$HOME" $O 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
cat $C
