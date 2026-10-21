#!/usr/bin/env bash
# Run 032, a probe of a reported issue (not registered): N6, XPBD joint limits beyond plus or minus pi blowing up
# (newton-physics/newton #4313: angles read in (-pi, pi]). Read in the source: XPBD's revolute limit (xpbd/kernels.py,
# solve_body_joints, its Alg. 3) measures the joint's angle with an arcsine and wraps it into (-pi, pi] before clamping
# it to the limits, and SemiImplicit's (semi_implicit/kernels_body.py) takes quat_twist_angle_signed, also in
# (-pi, pi]. Featherstone and the MuJoCo solver keep the joint's angle itself as their state.
# The chain rig gains lo1 and hi1, the first joint's limits (tools/nwt_chain.py), passed to Newton's
# add_joint_revolute, its own limit stiffness and damping kept; with neither given the rig is as before (checked below).
# The scene: run 014's two-link chain (arms of 1.2 and 0.6 kg, half-size 0.04 m, arm1 0.25 m, len1 0.5 m, arm2 0.2 m),
# straight, no gravity, turning as one body at 2 rad/s about the first joint for 1.9 s: the first joint's angle goes
# from 0 to 3.8 rad, passing pi at 1.57 s, and with limits of -1 and 4 rad it never reaches them. Nothing should act:
# the kinetic energy with the limits must be what it is without them.
# XPBD, Featherstone, the MuJoCo solver and VBD at 2.5 ms and 0.625 ms; SemiImplicit at 0.078125 ms (run 024: its
# joints need a step under 0.17 ms on this chain). Each with lo1=-1 hi1=4 and with no limits.
# Predicted, before the plays:
#   P1  XPBD: with the limits the chain's kinetic energy at the end departs from its value without them by more than
#       1 part in 10 at both steps: past pi the wrapped angle reads near -pi, below the lower limit, and the limit
#       pulls the joint back toward -1 rad.
#   P2  SemiImplicit: the same, more than 1 part in 10 (or the play leaves the format's range).
#   P3  Featherstone and the MuJoCo solver: the same energy with and without the limits, to the part per million.
#   Reported, not predicted: VBD.
#   Check: the changed rig with no limits gives run 014's free chain on XPBD at 2.5 ms byte for byte.
# usage: play.sh <sx_contact binary>   (repository root, Newton from PyPI's environment on; writes the reading)
set -u
B="${1:?usage: play.sh <sx_contact binary>}"
O=validation/run_032_joint_limit_past_pi; W=$O/runs; mkdir -p $W
: > $W/log.txt
ARMS="mass1=1.2 mass2=0.6 radius=0.04 arm1=0.25 len1=0.5 arm2=0.2"
TURN="gravity=0 angle1=0 angle2=0 omega1=2 omega2=0 secs=1.9"
FREE="gravity=0 angle2=-0.9 omega1=2.5 omega2=1.5 secs=2"
one() {  # <name> <dt> <rig settings...>
  local n=$1 dt=$2; shift 2
  python tools/nwt_chain.py $W/${n}_$dt.txt dt=$dt $ARMS "$@" > $W/${n}_$dt.stats 2>> $W/log.txt
}
pair() {  # <solver> <dt>
  one turn_$1_lim $2 $TURN solver=$1 lo1=-1 hi1=4
  one turn_$1_free $2 $TURN solver=$1
}
date -u +%FT%TZ > $O/started.txt
( pair xpbd 0.0025; pair xpbd 0.000625; one check_free_xpbd 0.002500000000 $FREE solver=xpbd ) &
( pair featherstone 0.0025; pair featherstone 0.000625; pair mujoco 0.0025; pair mujoco 0.000625 ) &
( pair vbd 0.0025; pair vbd 0.000625 ) &
( pair semi 0.000078125 ) &
wait
date -u +%FT%TZ > $O/finished.txt
{
  for p in "xpbd 0.0025" "xpbd 0.000625" "featherstone 0.0025" "featherstone 0.000625" "mujoco 0.0025" "mujoco 0.000625" "vbd 0.0025" "vbd 0.000625" "semi 0.000078125"; do
    s=${p% *}; dt=${p#* }
    for a in lim free; do
      st=$(grep -o 'out_of_range_at_step [0-9]*\|nan_at_step [0-9]*' $W/turn_${s}_${a}_$dt.stats || echo "plays")
      echo "$s $dt $a | $st | $("$B" chain $W/turn_${s}_${a}_$dt.txt | tail -1)"
    done
    if cmp -s $W/turn_${s}_lim_$dt.txt $W/turn_${s}_free_$dt.txt; then echo "$s $dt: with and without the limits byte-identical"; fi
  done
  if cmp -s $W/check_free_xpbd_0.002500000000.txt validation/run_014_chain/runs/free_xpbd_4.txt; then r=yes; else r=NO; fi
  echo "CHECK the changed rig, no limits, XPBD's free chain at 2.5 ms byte-identical to run 014's: $r"
} > $O/reading.txt
cat $O/reading.txt
