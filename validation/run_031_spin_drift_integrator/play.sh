#!/usr/bin/env bash
# Run 031, a trace (not registered): F12, the centre of mass of a body spinning about it off its origin moving on the
# MuJoCo solver (run 030: its largest speed in the last third 12,498, 3,117 and 734 um/s at 10, 2.5 and 0.625 ms, a
# quarter for each step 4 times smaller) and on VBD-ALM (352 um/s at 0.625 ms, more as the step shrinks).
# Hypothesis: the MuJoCo solver's drift is its integrator's first-order error. Newton's MuJoCo solver integrates with
# implicitfast by default; on the two-link chain (run 014) MuJoCo's Euler was the same to the byte and its RK4 kept the
# energy to 5 ppm.
# Run 030's scene (1 kg cube, half-size 0.05 m, 1 m up, no gravity, spinning at 5 rad/s about z, its centre of mass
# 0.05 m off its origin, 2 s), at 10, 2.5 and 0.625 ms:
#   mujoco_rk4, mujoco_euler   the MuJoCo solver with opt.integrator=rk4 and =euler (Newton 1.6.1 from PyPI)
#   vbd_alm_on2, vbd_alm_off   VBD-ALM on run 026's patched source with the carried velocity's second form, and with
#                              no switch (must be run 030's files), at 0.625 ms and 0.15625 ms
# Predicted, before the plays:
#   P1  with RK4 the centre of mass's largest speed in the last third is at most a hundredth of run 030's at each step
#       (125, 31 and 7 um/s).
#   P2  with Euler it reads as with implicitfast (run 030) within 1 in 100.
#   Reported, not predicted: VBD-ALM with the carried velocity.
#   Check: VBD-ALM off at 0.625 ms is run 030's file byte for byte.
# usage: play.sh <sx_contact binary>   (repository root; STOCK_VENV and VBD_VENV set)
set -u
B="${1:?usage: play.sh <sx_contact binary>}"
O=validation/run_031_spin_drift_integrator; W=$O/runs; mkdir -p $W
: > $W/stats.txt; : > $W/log.txt
SPIN="mass=1 radius=0.05 h0=1 gravity=0 wz0=5 secs=2 comx=0.05"
one() {  # <venv> <switch or -> <name> <rig settings...>
  local v=$1 sv=$2 n=$3; shift 3
  ( . "$v/bin/activate"; if [ "$sv" = - ]; then unset NEWTON_VBD_CARRIED_VELOCITY; else export NEWTON_VBD_CARRIED_VELOCITY=$sv; fi
    python tools/nwt_contact.py $W/$n.txt "$@" 2>> $W/log.txt | sed "s/^STATS/STATS $n/" >> $W/stats.txt )
}
date -u +%FT%TZ > $O/started.txt
( for dt in 0.01 0.0025 0.000625; do one "$STOCK_VENV" - spin_mujoco_rk4_$dt dt=$dt $SPIN solver=mujoco opt.integrator=rk4; done ) &
( for dt in 0.01 0.0025 0.000625; do one "$STOCK_VENV" - spin_mujoco_euler_$dt dt=$dt $SPIN solver=mujoco opt.integrator=euler; done ) &
( one "$VBD_VENV" 2 spin_vbd_alm_on2_0.000625 dt=0.000625 $SPIN solver=vbd_alm; one "$VBD_VENV" - spin_vbd_alm_off_0.000625 dt=0.000625 $SPIN solver=vbd_alm ) &
( one "$VBD_VENV" 2 spin_vbd_alm_on2_0.00015625 dt=0.00015625 $SPIN solver=vbd_alm; one "$VBD_VENV" - spin_vbd_alm_off_0.00015625 dt=0.00015625 $SPIN solver=vbd_alm ) &
wait
date -u +%FT%TZ > $O/finished.txt
pick() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
{
  for f in $W/spin_*.txt; do
    echo "$(basename $f .txt) | creep mean_speed_ums $("$B" creep $f | tail -1 | pick mean_speed_ums) | stop largest_speed_last_third_ums $("$B" stop $f | tail -1 | pick largest_speed_last_third_ums) slid_um $("$B" stop $f | tail -1 | pick slid_um)"
  done
  if cmp -s $W/spin_vbd_alm_off_0.000625.txt validation/run_030_com_offset_spin/runs/spin_vbd_alm_off_0.000625.txt; then r=yes; else r=NO; fi
  echo "CHECK VBD-ALM off at 0.625 ms byte-identical to run 030's: $r"
  echo "plays that stopped being a number: $(grep -c nan_at_step $W/stats.txt)"
} > $O/reading.txt
cat $O/reading.txt
