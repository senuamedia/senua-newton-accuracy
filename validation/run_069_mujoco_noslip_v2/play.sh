#!/usr/bin/env bash
# Run 069: run 067 played again with the noslip patch's second form (issue 15): Senua AI's noslip patch in design
# (patches/in_design/mujoco_noslip_v2_on_1.7.0.diff: SolverMuJoCo's noslip_iterations and noslip_tolerance, set on
# the compiled model the C engine steps), on the MuJoCo solver's CPU path, on Newton 1.7.0; and the hold at rest (issue 6's
# part). The README's predictions were pushed before these plays. Then measured.txt and checks.txt (sx_contact).
# usage: play.sh <sx_contact binary>   (repository root; STOCK_VENV Newton 1.7.0 as released, NOSLIP_VENV the same with
#   the patch's tree first on the path)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary>}")" && pwd)/$(basename "$1")"
O=validation/run_069_mujoco_noslip_v2; ROOT=$(pwd)
HOLD="mass=1 radius=0.05 h0=0 mu=0.5 push=2.94 pushat=0.5 secs=2 solver=mujoco"
CPU="opt.use_mujoco_cpu=true"
plays() {  # <name> <environment: stock or noslip> <rig> <settings...>
  local dt
  for dt in 0.002 0.0005; do
    echo "n1_hold_pyramid_$dt stock nwt_contact dt=$dt $HOLD $CPU"
    echo "n1_hold_elliptic_$dt stock nwt_contact dt=$dt $HOLD $CPU opt.cone=elliptic"
    echo "n1_hold_pyramid_noslip_$dt noslip nwt_contact dt=$dt $HOLD $CPU opt.noslip_iterations=10"
    echo "n1_hold_elliptic_noslip_$dt noslip nwt_contact dt=$dt $HOLD $CPU opt.cone=elliptic opt.noslip_iterations=10"
    echo "n3_hold_pyramid_off_$dt noslip nwt_contact dt=$dt $HOLD $CPU"
    echo "n3_hold_elliptic_off_$dt noslip nwt_contact dt=$dt $HOLD $CPU opt.cone=elliptic"
    echo "n3_hold_warp_$dt stock nwt_contact dt=$dt $HOLD"
    echo "n3_hold_warp_off_$dt noslip nwt_contact dt=$dt $HOLD"
    echo "n4_slide_elliptic_$dt stock nwt_contact dt=$dt solver=mujoco $CPU opt.cone=elliptic h0=0 vx0=1 mu=0.5 secs=0.5"
    echo "n4_slide_elliptic_noslip_$dt noslip nwt_contact dt=$dt solver=mujoco $CPU opt.cone=elliptic opt.noslip_iterations=10 h0=0 vx0=1 mu=0.5 secs=0.5"
    echo "n5_drop_elliptic_noslip_$dt noslip nwt_contact dt=$dt solver=mujoco $CPU opt.cone=elliptic opt.noslip_iterations=10 h0=0.08 mu=0.5 secs=1"
  done
  echo "n2_warp_noslip_0.002 noslip nwt_contact dt=0.002 $HOLD opt.noslip_iterations=10"
}
mkdir -p $O/runs $O/stats
date -u +%FT%TZ > $O/started.txt
for g in stock noslip; do
  ( v=$STOCK_VENV; [ $g = noslip ] && v=$NOSLIP_VENV; . "$v/bin/activate"
    plays | awk -v g=$g '$2 == g { $2 = ""; print }' | xargs -P 3 -L 1 bash -c 'python tools/$1.py '"$O"'/runs/$0.txt "${@:2}" > '"$O"'/stats/$0.txt 2> '"$O"'/runs/log_$0.txt' ) &
done
wait
date -u +%FT%TZ > $O/finished.txt
# ---- measuring
M=$O/measured.txt; : > $M
for n in $(plays | awk '{print $1}'); do
  f=$O/runs/$n.txt
  case $n in
    n1_*|n3_*) l="$("$B" creep $f < /dev/null | tail -1)";; n4_*) l="$("$B" stop $f < /dev/null | tail -1)";;
    n5_*) l="$("$B" rest $f < /dev/null | tail -1)";; n2_*) l="refused $(grep -c "^NotImplementedError: noslip solver not implemented" $O/runs/log_$n.txt)";;
  esac
  echo "$n $l" >> $M
done
pick() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $M; }
# ---- checks
C=$O/checks.txt; : > $C
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $C; }
same=0; for dt in 0.002 0.0005; do for p in pyramid elliptic; do cmp -s $O/runs/n1_hold_${p}_$dt.txt $O/runs/n3_hold_${p}_off_$dt.txt && same=$((same + 1)); done
  cmp -s $O/runs/n3_hold_warp_$dt.txt $O/runs/n3_hold_warp_off_$dt.txt && same=$((same + 1)); done
rule N0_safe_when_off eq $same 6
for dt in 0.002 0.0005; do
  rule N1_fault_there_$dt all_ge 500 $(pick n1_hold_pyramid_$dt mean_speed_ums) $(pick n1_hold_elliptic_$dt mean_speed_ums)
  rule N1_held_hi_$dt all_le 10 $(pick n1_hold_pyramid_noslip_$dt mean_speed_ums) $(pick n1_hold_elliptic_noslip_$dt mean_speed_ums)
  rule N1_held_lo_$dt all_ge -10 $(pick n1_hold_pyramid_noslip_$dt mean_speed_ums) $(pick n1_hold_elliptic_noslip_$dt mean_speed_ums)
  rule N4_slide_kept_$dt all_within $(pick n4_slide_elliptic_$dt slid_um) 100 $(pick n4_slide_elliptic_noslip_$dt slid_um)
  rule N5_weight_$dt all_within 9800 100 $(pick n5_drop_elliptic_noslip_$dt mean_ground_force_mN)
done
rule N2_warp_refuses eq $(awk '$1 == "n2_warp_noslip_0.002" { print $3 }' $M) 1
echo "checks: $(wc -l < $C | tr -d ' '), held: $(grep -c ': HELD$' $C)" >> $C
grep -rlIF "$HOME" $O 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
cat $C
